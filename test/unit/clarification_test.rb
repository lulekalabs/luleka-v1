require File.dirname(__FILE__) + '/../test_helper'

class ClarificationTest < ActiveSupport::TestCase
  fixtures :comments, :users, :people, :tiers, :topics, :kases

  def test_simple_create
    assert clari = create_clarification
    assert clari.valid?
  end

  def test_create_request_with_counter_cache
    assert clari = create_clarification_request
    assert clari.valid?
    assert_equal ClarificationRequest, clari.class
    clari.clarifiable.reload
    assert_equal 1, clari.clarifiable.clarification_requests_count
    assert_equal 0, clari.clarifiable.clarification_responses_count
  end

  def test_should_not_validate_without_message
    assert clari = build_clarification(:message => nil)
    assert !clari.valid?
    assert clari.errors.on(:message)
  end

  def xtest_should_not_validate_without_clarifiable
    assert clari = build_clarification(:clarifiable => nil)
    assert !clari.valid?
    assert clari.errors.on(:clarifiable)
  end

  def test_should_not_validate_without_sender
    assert clari = build_clarification(:sender => nil)
    assert !clari.valid?
    assert clari.errors.on(:sender)
  end
  
  def test_create_simple_clarification_request
    assert_difference ClarificationRequest, :count do
      assert request = ClarificationRequest.create(valid_clarification_attributes)
      assert :request, request.kind
    end
  end

  def test_create_simple_clarification_response
    assert_difference ClarificationResponse, :count do
      assert response = ClarificationResponse.create(valid_clarification_attributes)
      assert :response, response.kind
    end
  end
  
  def test_should_instantiate_with_type
    request = Clarification.new(:type => :clarification_request)
    assert_equal 'ClarificationRequest', request.class.name
    request = Clarification.new(:type => 'ClarificationRequest')
    assert_equal 'ClarificationRequest', request.class.name
    request = Clarification.new(:type => ClarificationRequest)
    assert_equal 'ClarificationRequest', request.class.name

    response = Clarification.new(:type => :clarification_response)
    assert_equal 'ClarificationResponse', response.class.name
    response = Clarification.new(:type => 'ClarificationResponse')
    assert_equal 'ClarificationResponse', response.class.name
    response = Clarification.new(:type => ClarificationResponse)
    assert_equal 'ClarificationResponse', response.class.name
  end
  
  def test_should_create_kase_clarification_request
    old_size = ActionMailer::Base.deliveries.size
    assert request = create_clarification(:type => :clarification_request)
    assert request.valid?
    assert request.activate!
    assert request.repliable?, 'should be repliable'
    assert_not_equal old_size, size = ActionMailer::Base.deliveries.size
    assert_equal "Sent request to clarify Problem \"Dirt in the entrance\"", ActionMailer::Base.deliveries[size - 2].subject
    assert_equal "Received request to clarify Problem \"Dirt in the entrance\"", ActionMailer::Base.deliveries[size - 1].subject
  end

  def test_should_create_kase_clarification_response
    request = create_clarification(:type => :clarification_request)
    assert_equal 'ClarificationRequest', request.class.name

    old_size = ActionMailer::Base.deliveries.size
    response = request.create_reply(:message => "repsone to request")
    assert_equal 'ClarificationResponse', response.class.name
    assert !response.repliable?, 'should not be repliable'
    
    response.clarifiable.reload
    assert_equal 1, response.clarifiable.clarification_requests_count
    assert_equal 1, response.clarifiable.clarification_responses_count
    
    assert_equal request, response.parent
    assert_equal request, response.clarification
    assert_equal response, request.clarifications.first
    
    assert_equal request.sender, response.receiver
    assert_equal request.receiver, response.sender
    assert_equal "repsone to request", response.message
    
    assert_not_equal old_size, size = ActionMailer::Base.deliveries.size
    assert_equal "Sent response to clarify Problem \"Dirt in the entrance\"", ActionMailer::Base.deliveries[size - 2].subject
    assert_equal "Received response to clarify Problem \"Dirt in the entrance\"", ActionMailer::Base.deliveries[size -1 ].subject
  end

  def test_should_not_create_kase_clarification_response
    response = create_clarification(:type => :clarification_response)
    dummy = response.create_reply(:message => "dummy")
    assert_nil dummy
  end
  
  def test_flag_with_user_flags
    clarification = create_clarification
    user = users(:lisa)
    
    flag = user.flags.create :flaggable => clarification, :reason => "spam", :description => "not acceptable spam"
    assert_equal flag, user.flags.first
    assert_equal "not acceptable spam", flag.description
    assert_equal "spam", flag.reason
    assert_equal user.id, flag.user_id
    assert_equal clarification.user_id, flag.flaggable_user_id
  end
  
  def test_flag_with_flaggable_add_flag
    clarification = create_clarification
    user = users(:lisa)
    
    clarification.add_flag(:user => user, :reason => "spam", :description => "not acceptable spam")
    flag = clarification.flags.first
    assert_equal flag, user.flags.first
    assert_equal "not acceptable spam", flag.description
    assert_equal "spam", flag.reason
    assert_equal user.id, flag.user_id
    assert_equal clarification.user_id, flag.flaggable_user_id
  end

  def test_clarification_kind
    assert_nil Clarification.kind
  end
  
  def test_clarification_request_kind
    assert_equal :clarification_request, ClarificationRequest.kind
    assert_equal "Clarification Request", ClarificationRequest.human_name
  end

  def test_clarification_response_kind
    assert_equal :clarification_response, ClarificationResponse.kind
    assert_equal "Clarification Response", ClarificationResponse.human_name
  end
  
  
  protected
  
  def valid_clarification_attributes(options={})
    {
      :sender => people(:homer),
      :receiver => people(:marge),
      :clarifiable => kases(:probono_problem),
      :message => "this is a test clarification"
    }.merge(options)
  end

  def valid_clarification_request_attributes(options={})
    {
      :type => 'ClarificationRequest',
      :sender => people(:homer),
      :receiver => people(:marge),
      :clarifiable => kases(:probono_problem),
      :message => "this is a test clarification"
    }.merge(options)
  end
  
  def build_clarification(options={})
    Clarification.new(valid_clarification_attributes(options))
  end

  def create_clarification(options={})
    Clarification.create(valid_clarification_attributes(options))
  end

  def build_clarification_request(options={})
    Clarification.new(valid_clarification_request_attributes(options))
  end

  def create_clarification_request(options={})
    Clarification.create(valid_clarification_request_attributes(options))
  end
  
end