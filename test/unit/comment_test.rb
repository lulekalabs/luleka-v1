require File.dirname(__FILE__) + '/../test_helper'

class CommentTest < ActiveSupport::TestCase
  all_fixtures

  def setup
    ActionMailer::Base.deliveries.clear
  end

  def test_simple_create
    assert comment = create_comment
    assert comment.valid?
  end
  
  def test_kind
    assert_equal :comment, Comment.kind
    assert_equal "Comment", Comment.human_name
  end
  
  def test_state_machine
    assert comment = create_comment
    assert_equal :created, comment.current_state
    assert_nil comment.activated_at
    assert_nil comment.suspended_at
    assert_nil comment.deleted_at
    assert comment.activate!
    assert_equal :active, comment.current_state
    assert comment.activated_at, 'activated_at should be set'
    assert comment.suspend!
    assert_equal :suspended, comment.current_state
    assert comment.suspended_at, 'suspended_at should be set'
    assert comment.unsuspend!
    assert_equal :active, comment.current_state
    assert_nil comment.suspended_at
    assert comment.delete!
    assert_equal :deleted, comment.current_state
    assert comment.deleted_at, 'deleted_at should be set'
  end

  def test_state_machine_suspend_before_activate
    assert comment = create_comment
    assert_equal :created, comment.current_state
    assert comment.suspend!
    assert_equal :suspended, comment.current_state
    assert comment.unsuspend!
    assert_equal :created, comment.current_state
    assert comment.delete!
    assert_equal :deleted, comment.current_state
  end
  
  def test_should_not_validate_without_message
    assert comment = build_comment(:message => nil)
    assert !comment.valid?
    assert comment.errors.on(:message)
  end

  def test_should_not_validate_short_message
    assert comment = build_comment(:message => "a" * 4)
    assert !comment.valid?
    assert comment.errors.on(:message)
  end

  def test_should_not_validate_long_message
    assert comment = build_comment(:message => "a" * 1001)
    assert !comment.valid?
    assert comment.errors.on(:message)
  end

  def test_should_not_validate_without_commentable
    assert comment = build_comment(:commentable => nil)
    assert !comment.valid?
    assert comment.errors.on(:commentable)
  end

  def test_should_not_validate_without_sender
    assert comment = build_comment(:sender => nil)
    assert !comment.valid?
    assert comment.errors.on(:sender)
  end
  
  def test_belongs_to_person
    assert comment = create_comment(:person => people(:homer))
    assert comment.valid?
    comment.reload
    assert_equal people(:homer), comment.person
    assert_equal people(:homer).comments.first, comment
  end

  def test_belongs_to_sender
    assert comment = create_comment(:sender => people(:homer))
    assert comment.valid?
    comment.reload
    assert_equal people(:homer), comment.sender
    assert_equal people(:homer), comment.person
    assert_equal people(:homer).comments.first, comment
  end
  
  def test_belongs_to_receiver
    assert comment = create_comment(:sender => people(:homer), :receiver => people(:marge))
    assert comment.valid?
    comment.reload
    assert_equal people(:homer), comment.sender
    assert_equal people(:marge), comment.receiver
    assert_equal people(:marge).received_comments.first, comment
  end
  
  def test_mailer_for_kase_comment
    assert comment = create_comment(:sender => people(:homer), :receiver => people(:marge))
    assert comment.activate!
    size = ActionMailer::Base.deliveries.size
    assert_equal "Comment posted on Problem for \"Dirt in the entrance\"", ActionMailer::Base.deliveries[size - 2].subject
    assert_equal "Comment received on Problem for \"Dirt in the entrance\"", ActionMailer::Base.deliveries[size -1 ].subject
    
    # make sure we only send once!
    assert comment.suspend!
    assert comment.activate!
    assert_equal size, ActionMailer::Base.deliveries.size
  end

  def test_belongs_to_commentable_with_kase
    kase = kases(:probono_problem)
    assert comment = create_comment(:sender => people(:homer), :receiver => people(:marge), :commentable => kase)
    assert comment.valid?
    comment.reload
    assert_equal people(:homer), comment.sender
    assert_equal people(:marge), comment.receiver
    assert_equal kase, comment.commentable
    assert_equal kase, comment.kase
    assert_equal comment, kase.comments.first
  end
  
  def test_build_reply
    kase = kases(:probono_problem)
    assert comment = create_comment(:sender => people(:homer), :receiver => people(:marge), :commentable => kase)
    assert reply = comment.build_reply(:message => "reply to comment")
    assert_equal "reply to comment", reply.message
    assert_equal comment, reply.parent
    assert_equal comment.sender, reply.receiver
    assert_equal comment.receiver, reply.sender
    assert_equal comment.commentable, reply.commentable
    assert_equal comment, reply.parent
  end

  def test_create_reply
    Comment.class_eval do

      # returns true if comment can be replied to
      def repliable?(a_person=nil)
        true
      end

    end
    
    kase = kases(:probono_problem)
    assert comment = create_comment(:sender => people(:homer), :receiver => people(:marge), :commentable => kase)
    assert comment.valid?, 'comment is valid'
    assert comment.repliable?, 'comment is repliable'
    assert_difference Comment, :count do
      assert reply = comment.create_reply(:message => "reply to comment")
      assert_equal "reply to comment", reply.message
      assert_equal comment, reply.parent
      assert_equal comment.sender, reply.receiver
      assert_equal comment.receiver, reply.sender
      assert_equal comment.commentable, reply.commentable
      assert_equal comment, reply.parent
    end
  end
  
  def test_flag_with_user_flags
    comment = create_comment
    user = users(:lisa)
    
    flag = user.flags.create :flaggable => comment, :reason => 'spam', :description => "not acceptable spam"
    assert_equal flag, user.flags.first
    assert_equal "not acceptable spam", flag.description
    assert_equal 'spam', flag.reason
    assert_equal user.id, flag.user_id
    assert_equal comment.user_id, flag.flaggable_user_id
  end
  
  def test_flag_with_flaggable_add_flag
    comment = create_comment
    user = users(:lisa)
    
    comment.add_flag(:user => user, :reason => 'spam', :description => "not acceptable spam")
    flag = comment.flags.first
    assert_equal flag, user.flags.first
    assert_equal "not acceptable spam", flag.description
    assert_equal 'spam', flag.reason
    assert_equal user.id, flag.user_id
    assert_equal comment.user_id, flag.flaggable_user_id
  end

  def test_should_be_editable
    comment = build_comment
    assert comment.created?, 'should be created'
    assert comment.editable?, 'should be editable'
    assert comment.save
    assert comment.editable?, 'should be editable'
  end
  
  def test_should_not_be_editable
    comment = build_comment(:created_at => Time.now.utc - 16.minutes)
    assert comment.editable?, 'should be editable'
    assert comment.activate!, 'should activate'
    assert comment.active?, 'should be active'
    assert !comment.editable?, 'should not be editable'
  end

  def test_subclass_param_ids
    assert_equal [:clarification_id, :clarification_request_id, :clarification_response_id].to_set,
      Comment.subclass_param_ids.to_set
    assert_equal [:clarification_request_id, :clarification_response_id].to_set, Clarification.subclass_param_ids.to_set
    assert_equal [].to_set, ClarificationRequest.subclass_param_ids.to_set
  end

  def test_self_and_subclass_param_ids
    assert_equal [:comment_id, :clarification_id, :clarification_request_id, :clarification_response_id].to_set,
      Comment.self_and_subclass_param_ids.to_set
    assert_equal [:clarification_id, :clarification_request_id, :clarification_response_id].to_set,
      Clarification.self_and_subclass_param_ids.to_set
    assert_equal [:clarification_request_id].to_set, ClarificationRequest.self_and_subclass_param_ids.to_set
  end

  def test_should_get_language_code
    comment = Comment.new
    assert_equal 'en', comment.language_code

    I18n.switch_locale :"de-DE" do
      comment = Comment.new
      assert_equal 'de', comment.language_code
    end

    comment = build_comment
    assert_equal comment.person.default_language, comment.language_code

    comment = Comment.new(:language_code => 'es')
    assert_equal 'es', comment.language_code
  end
  
  def test_should_update_comments_count
    comment = create_comment
    assert comment.activate!
    comment.reload  # works without reload as well, just try to be compatible once bug is fixed
    assert_equal 1, comment.commentable.comments_count, "should update commentable comment count as it is activated"
  end

  def test_should_not_update_comments_count
    comment = create_comment
    # note: we are not activating the comment here!
    comment.reload
    assert_equal 0, comment.commentable.comments_count, "should not update comment count as it is not activated"
  end

  def test_should_create_without_person
    assert_difference Comment, :count do 
      comment = create_comment({:sender => nil, :sender_email => "hans@zimmer.tt"})
      assert_equal :created, comment.current_state
      assert comment.activation_code, "should have an activation code"
      assert_nil comment.published_at, "should not be published"
      assert_equal 1, ActionMailer::Base.deliveries.size, "should send activation mail"
    end
  end
  
  def test_should_not_create_without_person
    assert_no_difference Comment, :count do 
      comment = create_comment({:sender => nil})
    end
  end
  
  def test_should_not_activate_without_person_and_email
    assert_difference Comment, :count do 
      comment = create_comment(:sender => nil, :sender_email => "homer@simpson.tt")
      comment.activate!
      assert_equal :created, comment.current_state
    end
  end
  
  def test_should_not_activate_without_matching_email
    assert_difference Comment, :count do 
      comment = create_comment(:sender => nil, :sender_email => "no@match.tt")
      comment.sender = people(:homer)
      
      comment.activate!
      assert_equal :created, comment.current_state

      assert !comment.valid?, "should not be valid, due to email mismatch"
      assert_equal "activation (no@match.tt) does not match your email (homer@simpson.tt)", comment.errors.on(:sender_email)
    end
  end
  
  def test_should_activate_with_person_and_email
    assert_difference Comment, :count do 
      comment = create_comment(:sender => nil, :sender_email => "homer@simpson.tt")
      comment.sender = people(:homer)

      comment.activate!
      assert_equal :active, comment.current_state

      assert comment.valid?, "should be valid"

      comment.reload

      assert comment.published_at, "should set published_at time"
      assert_nil comment.sender_email, "should remove email"
    end
  end
  
  def test_should_be_anonymous
    comment = build_comment
    assert_equal false, comment.anonymous?
    comment.anonymous = true
    assert_equal true, comment.anonymous?
  end
  
  protected
  
  def valid_comment_attributes(options={})
    {
      :sender => people(:homer),
      :commentable => kases(:probono_problem),
      :message => "this is a test comment"
    }.merge(options)
  end
  
  def build_comment(options={})
    Comment.new(valid_comment_attributes(options))
  end

  def create_comment(options={})
    Comment.create(valid_comment_attributes(options))
  end
  
end
