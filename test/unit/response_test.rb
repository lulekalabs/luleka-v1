require File.dirname(__FILE__) + '/../test_helper'

class ResponseTest < ActiveSupport::TestCase
  all_fixtures

  def setup
    ActionMailer::Base.deliveries.clear
    tiers(:powerplant).update_attributes(
      :accept_default_reputation_points => true, 
        :accept_default_reputation_threshold => true, 
          :accept_person_total_reputation_points => true)
  end

  # Replace this with your real tests.
  def test_simple_instantiation
    assert_difference Response, :count do
      assert response = create_response
      assert response.valid?
    end
  end
  
  def test_state_machine
    assert response = create_response
    assert_equal :created, response.current_state
    assert_nil response.activated_at
    assert_nil response.suspended_at
    assert_nil response.deleted_at
    assert_nil response.accepted_at

    assert response.activate!
    assert_equal :active, response.current_state
    assert response.activated_at, 'activated_at should be set'

    assert response.accept!
    assert_equal :accepted, response.current_state
    assert response.accepted_at, 'accepted_at should be set'

    assert response.suspend!
    assert_equal :suspended, response.current_state
    assert response.suspended_at, 'suspended_at should be set'

    assert response.unsuspend!
    assert_equal :accepted, response.current_state
    assert_nil response.suspended_at
    
    assert response.reject!
    assert_equal :active, response.current_state
    assert_nil response.accepted_at
    
    assert response.delete!
    assert_equal :deleted, response.current_state
    assert response.deleted_at, 'deleted_at should be set'
  end

  def test_state_machine_suspend_before_activate
    assert response = create_response
    assert_equal :created, response.current_state
    assert response.suspend!
    assert_equal :suspended, response.current_state
    assert response.unsuspend!
    assert_equal :created, response.current_state
    assert response.delete!
    assert_equal :deleted, response.current_state
  end

  def test_should_not_validate_without_person
    assert response = build_response(:person => nil)
    assert !response.valid?
    assert response.errors.on(:person)
  end

  def test_should_validate_responses_with_owners_probono_kase
    kase = kases(:probono_problem)
    assert response = build_response(:person => kase.person, :kase => kase)
    assert response.valid?, "should validate probono cases"
  end

  def xtest_should_not_validate_response_with_owners_fixed_price_kase
    kase = kases(:fixed_price_problem)
    assert kase.offers_reward?, "should offer reward"
    assert response = build_response(:person => kase.person, :kase => kase)
    assert !response.valid?, "should not allow kase author to respond to rewarded kases"
#    assert response.errors.on(:person)
  end

  def test_should_not_validate_without_kase
    assert response = build_response
    response.kase = nil
    assert !response.valid?
    assert response.errors.on(:kase)
  end
  
  def test_should_not_validate_without_description
    assert response = build_response(:description => nil)
    assert !response.valid?
    assert response.errors.on(:description)
  end

  def test_should_not_validate_short_description
    assert response = build_response(:description => "a" * 14)
    assert !response.valid?
    assert response.errors.on(:description)
  end

  def test_should_not_validate_long_description
    assert response = build_response(:description => "a" * 2001)
    assert !response.valid?, 'should not allow description larger than 2000 characters'
    assert response.errors.on(:description)
  end
  
  def test_has_many_assets
    assert response = create_response
    assert_equal 0, response.assets.size
  end

  def test_has_many_comments
    assert response = create_response
    assert_equal 0, response.comments.size
  end

  def test_has_many_clarifications
    assert response = create_response
    assert_equal 0, response.clarifications.size
  end
  
  def test_should_be_editable
    response = build_response
    assert response.editable?, "should be editable"

    response = create_response
    assert response.editable?, "should be editable"
    response.activate!
    assert response.editable?, "should be editable"

    reponse = create_response(:created_at => Time.now.utc - (14.minutes + 55.seconds))
    assert response.editable?, "should be editable"
  end
  
  def xtest_should_not_be_editable
    response = create_response(:created_at => Time.now.utc - 15.minutes)
    assert !response.editable?, "should not be editable"
  end

  def test_should_build_clarification_clarification
    assert_no_difference Clarification, :count do 
      assert response = create_response
      assert_equal true, response.activate!, "should activate"
      assert response.allows_clarification_request?(people(:aaron)), "should allow clarification"
      assert request = response.build_clarification_request(people(:aaron), :message => "question about your response")
      assert_equal "ClarificationRequest", request.class.name
      assert_equal people(:aaron), request.sender
      assert_equal response.person, request.receiver
      assert_equal response, request.clarifiable
      assert_equal "question about your response", request.message
    end
  end
  
  def test_should_not_allow_clarification_request
    assert response = create_response
    assert !response.allows_clarification_request?(response.person), "should not allow clarification"
  end

  def test_should_create_clarification_request
    assert_difference ClarificationRequest, :count do 
      request = create_clarification_request(people(:aaron))
      response = request.clarifiable
      
      assert_equal "ClarificationRequest", request.class.name
      assert_equal 1, request.clarifiable.clarification_requests_count
      assert_equal 0, request.clarifiable.clarification_responses_count
      assert request.clarifiable.pending_clarification_requests?
      assert_equal people(:aaron), request.sender
      assert_equal response.person, request.receiver
      assert_equal response, request.clarifiable
      assert_equal "question about your response", request.message
      assert_equal request, response.clarifications.first
    end
  end
  
  def test_should_build_clarification_response
    assert_no_difference ClarificationResponse, :count do 
      reply = create_clarification_request(people(:aaron))
      response = reply.clarifiable
      assert reply = response.build_clarification_response(response.person, :message => "reply to the clarification request"),
        "should build a clarification response"
    end
  end
  
  def test_should_create_multiple_clarification_requests_and_responses
    assert_difference ClarificationRequest, :count, 2 do 
      assert_difference ClarificationResponse, :count, 2 do 
        request = create_clarification_request(people(:aaron))
        response = request.clarifiable
        assert reply = response.create_clarification_response(response.person, :message => "reply to the clarification request"),
          "should build a clarification response"
        assert reply.active?, 'clarification should be active'
        response.reload
        assert !response.pending_clarification_requests?, "should not have any pending requests"
        
        assert request = response.create_clarification_request(people(:aaron), :message => "another request")
        response.reload
        
        assert_equal request, response.pending_clarification_request
        assert reply = response.create_clarification_response(response.person, :message => "another response")
      end
    end
  end
  
  def test_should_create_clarification_response
    assert_difference ClarificationResponse, :count do 
      request = create_clarification_request(people(:aaron))
      response = request.clarifiable
      assert reply = response.create_clarification_response(response.person, :message => "respond"),
        'should create clarification response'
        
      assert reply.active?, 'clarification should be active'
      response.reload
      assert_equal response, reply.clarifiable
      assert_equal response.person, reply.sender
      assert_equal people(:aaron), reply.receiver
      assert_equal "respond", reply.message
      assert !response.pending_clarification_requests?, "should not have any pending request"
    end
  end

  def test_build_comment
    assert_no_difference Comment, :count do 
      assert response = create_response
      assert response.activate!
      assert response.allows_comment?(people(:aaron)), "should allow comment"
      assert comment = response.build_comment(people(:aaron), :message => "comment about your response")
      assert_equal "Comment", comment.class.name
      assert_equal people(:aaron), comment.sender
      assert_equal response.person, comment.receiver
      assert_equal response, comment.commentable
      assert_equal "comment about your response", comment.message
    end
  end

  def test_create_comment
    assert_difference Comment, :count do 
      assert response = create_response
      assert response.activate!
      assert response.allows_comment?(people(:aaron)), "should allow comment"
      assert comment = response.create_comment(people(:aaron), :message => "comment about your response")
      assert_equal :active, comment.current_state
      assert_equal "Comment", comment.class.name
      assert_equal people(:aaron), comment.sender
      assert_equal response.person, comment.receiver
      assert_equal response, comment.commentable
      assert_equal "comment about your response", comment.message
      assert_equal comment, response.comments.first
    end
  end
  
  def test_mailer
    kase = create_problem(:person => people(:homer))
    assert response = create_response(:kase => kase, :person => people(:marge))
    assert response.activate!
    size = ActionMailer::Base.deliveries.size
    assert_equal "Answer posted on Problem for \"A new problem\"", ActionMailer::Base.deliveries[size - 2].subject
    assert_equal "Answer received on Problem for \"A new problem\"", ActionMailer::Base.deliveries[size -1 ].subject
    
    # make sure we only send once!
    assert response.suspend!
    assert response.activate!
    assert_equal size, ActionMailer::Base.deliveries.size
  end
  
  def test_receiver
    kase = create_problem(:person => people(:homer))
    assert response = create_response(:kase => kase, :person => people(:marge))
    assert_equal people(:homer), response.receiver
  end

  def test_flag_with_user_flags
    response = create_response
    user = users(:lisa)
    
    flag = user.flags.create :flaggable => response, :reason => 'spam', :description => "not acceptable spam"
    assert_equal flag, user.flags.first
    assert_equal "not acceptable spam", flag.description
    assert_equal 'spam', flag.reason
    assert_equal user.id, flag.user_id
    assert_equal response.user_id, flag.flaggable_user_id
  end
  
  def test_flag_with_flaggable_add_flag
    response = create_response
    user = users(:lisa)
    
    response.add_flag(:user => user, :reason => 'spam', :description => "not acceptable spam")
    flag = response.flags.first
    assert_equal flag, user.flags.first
    assert_equal "not acceptable spam", flag.description
    assert_equal 'spam', flag.reason
    assert_equal user.id, flag.user_id
    assert_equal response.user_id, flag.flaggable_user_id
  end

  def test_subclass_param_ids
    assert_equal [].to_set, Response.subclass_param_ids.to_set
  end

  def test_self_and_subclass_param_ids
    assert_equal [:response_id].to_set, Response.self_and_subclass_param_ids.to_set
  end

  def test_should_get_language_code
    response = Response.new
    assert_equal 'en', response.language_code

    I18n.switch_locale :"de-DE" do
      response = Response.new
      assert_equal 'de', response.language_code
    end

    response = build_response
    assert_equal response.person.default_language, response.language_code

    response = Response.new(:language_code => 'es')
    assert_equal 'es', response.language_code
  end
  
  def test_acts_as_voteable
    assert voteable = create_response
    assert voteable.votes_sum_column?
    assert voteable.votes_count_column?
    assert voteable.up_votes_count_column?
    assert voteable.down_votes_count_column?
    
    assert voter = people(:barney)
    
    assert voteable.vote_up(voter)
    assert_equal 1, voteable.votes_count
    assert_equal 1, voteable.up_votes_count
    assert_equal 0, voteable.down_votes_count
    assert_equal 1, voteable.votes_sum
  end

  def test_acts_as_rateable
    assert rateable = create_response
    assert rateable.ratings_average_column?
    assert rateable.ratings_count_column?
    
    assert rater = people(:barney)
    
    assert rateable.rate(5, rater)
    
    assert_equal 1, rateable.ratings_count
    assert_equal 5, rateable.rating
  end
  
  def test_finder
    assert_difference Response, :count do 
      response = create_response
      assert_equal :find, Response.finder_name
      assert_equal response, Response.finder(response.id)
    end
  end

  def test_should_update_responses_count
    kase = create_idea
    assert_equal true, kase.activate!
    rs1 = create_response(:kase => kase)
    assert_equal true, rs1.activate!
    kase.reload
    assert_equal 1, kase.responses_count
    rs2 = create_response(:kase => kase)
    assert_equal true, rs2.activate!
    kase.reload
    assert_equal 2, kase.responses_count
  end
  
  def test_should_have_comments_count
    response = create_response
    assert_equal 0, response.comments_count
  end

  def test_should_not_update_responses_count
    response = create_response
    response.reload
    assert_equal 0, response.kase.responses_count, "should not update responses count, since response is not active"
  end
  
  def test_should_be_acceptable
    response = create_response
    assert response.activate!, 'should active response'
    assert response.can_accept?, 'should be acceptable'
  end

  def test_should_not_be_acceptable
    response = build_response
    assert !response.can_accept?, 'should not be acceptable, because not saved'

    assert response.save, "should save"
    assert !response.can_accept?, 'should not be acceptable, because not active'

    assert response.activate!, 'should active response'

    assert response.kase.suspend!, 'should suspend kase'
    assert !response.can_accept?, 'should not be acceptable, because kase is not active'

    assert response.kase.unsuspend!, 'should activate kase'
    assert response.can_accept?, 'should be acceptable'
  end

  def test_should_be_acceptable_by
    response = create_response
    assert response.activate!, 'should active response'
    
    assert response.acceptable_by?(response.kase.person), 'should be acceptable'
  end

  def test_should_allow_response
    response = create_response({:person => people(:marge)}, 
      {:person => people(:homer)})
    assert response.allowed?, "response should be allowed with partner"
  end

  def test_should_validate_probono_partner_audience_type
    response = create_response({:person => people(:marge)}, 
      {:person => people(:homer)})
    assert response.valid?, "response should be valid with partner"
  end

  def test_should_create_response_without_person
    assert_difference Response, :count do 
      response = create_response({:person => nil, :sender_email => "hans@zimmer.tt"})
      assert_equal :created, response.current_state
      assert response.activation_code, "should have an activation code"
      assert_nil response.published_at, "should not be activated"
      assert_equal 2, ActionMailer::Base.deliveries.size, "should send activation mail"
    end
  end
  
  def test_should_not_create_without_person
    assert_no_difference Response, :count do 
      response = create_response({:person => nil})
    end
  end
  
  def test_should_not_activate_without_person_and_email
    assert_difference Response, :count do 
      response = create_response(:person => nil, :sender_email => "homer@simpson.tt")
      response.activate!
      assert_equal :created, response.current_state
    end
  end
  
  def test_should_not_activate_without_matching_email
    assert_difference Response, :count do 
      response = create_response(:person => nil, :sender_email => "no@match.tt")
      response.person = people(:homer)
      
      response.activate!
      assert_equal :created, response.current_state

      assert !response.valid?, "should not be valid, due to email mismatch"
      assert_equal "activation (no@match.tt) does not match your email (homer@simpson.tt)", response.errors.on(:sender_email)
    end
  end
  
  def test_should_activate_with_person_and_email
    assert_difference Response, :count do 
      response = create_response(:person => nil, :sender_email => "homer@simpson.tt")
      response.person = people(:homer)

      response.activate!
      assert_equal :active, response.current_state

      assert response.valid?, "should be valid"

      response.reload

      assert response.published_at, "should set published_at time"
      assert_nil response.sender_email, "should remove email"
    end
  end
  
  def test_should_accept
    kase = kases(:powerplant_leak)
    rs1 = create_response(:kase => kase)
    assert_equal true, rs1.activate!, "should accept response"
    assert_equal true, rs1.can_accept?, "should generally be acceptable"
    assert_equal true, rs1.can_be_accepted_by?(kase.person), "should be accepted by kase owner"
    assert_equal true, rs1.accept!, "should accept"
    assert_equal ReputationReward::Response::Receiver.accept_response, rs1.person.reputation_points
    assert_equal :accepted, rs1.current_state
    kase.reload
    assert_equal :resolved, kase.current_state
  end

  def test_should_not_be_accepted_by
    kase = kases(:powerplant_leak)
    rs1 = create_response(:kase => kase)
    assert_equal true, rs1.activate!, "should accept response"
    assert_equal false, rs1.can_be_accepted_by?(people(:bart)), "should not be accepted by bart (not kase owner)"
  end

  def test_should_be_accepted_by_with_offer_single_reward
    kase = kases(:powerplant_leak)
    rw1 = create_reward(:sender => kase.person.direct_deposit_and_return("5.00"), :price => "5.00", 
      :kase => kase, :expires_at => Time.now.utc + 1.day)
    assert_equal true, rw1.activate!
    
    rs1 = create_response(:kase => kase)
    assert_equal true, rs1.activate!, "should accept response"
    assert_equal true, rs1.can_be_accepted_by?(kase.person), "should be accepted by kase owner + reward sender"
  end

  def test_should_not_be_accepted_by_with_offer_single_reward
    kase = kases(:powerplant_leak)
    rw1 = create_reward(:sender => people(:marge).direct_deposit_and_return("5.00"), :price => "5.00", 
      :kase => kase, :expires_at => Time.now.utc + 1.day)
    assert_equal true, rw1.activate!
    
    rs1 = create_response(:kase => kase)
    assert_equal true, rs1.activate!, "should accept response"
    assert_equal false, rs1.can_be_accepted_by?(kase.person), 
      "should not be accepted by kase owner as a reward was given by someone else"
  end

  def test_should_repute_vote_up
    kase = kases(:powerplant_leak)
    receiver = people(:barney)
    rs1 = create_response(:kase => kase, :person => receiver)
    assert_equal true, rs1.activate!, "should accept response"
    result = rs1.send :repute_vote_up, people(:bart).repute_and_return(ReputationThreshold.vote_up)
    assert_equal true, result.success?
    receiver.reload
    assert_equal 5, receiver.reputation_points
  end

  def test_should_cancel_repute_vote_up
    kase = kases(:powerplant_leak)
    receiver = people(:barney)
    rs1 = create_response(:kase => kase, :person => receiver)
    assert_equal true, rs1.activate!, "should accept response"
    result = rs1.send :repute_vote_up, people(:bart).repute_and_return(ReputationThreshold.vote_up)
    assert_equal true, result.success?
    result = rs1.send :cancel_repute_vote_up, people(:bart)
    assert_equal true, result.success?
    receiver.reload
    assert_equal 0, receiver.reputation_points
  end

  def test_should_not_repute_vote_up_because_of_low_threshold
    kase = kases(:powerplant_leak)
    receiver = people(:barney)
    rs1 = create_response(:kase => kase, :person => receiver)
    assert_equal true, rs1.activate!, "should accept response"
    result = rs1.send :repute_vote_up, people(:bart)
    assert_equal false, result.success?
    assert_equal "Vote up requires 15 <a href=\"/faq\">Reputation Points</a>, you currently have 0. For more information, please visit our <a href=\"/faq\">FAQ page</a>.",
      result.message
  end

  def test_should_repute_vote_down
    kase = kases(:powerplant_leak)
    receiver = people(:barney).repute_and_return(5)
    sender = people(:bart).repute_and_return(ReputationThreshold.vote_down)
    rs1 = create_response(:kase => kase, :person => receiver)
    assert_equal true, rs1.activate!, "should accept response"
    result = rs1.send :repute_vote_down, sender
    assert_equal true, result.success?
    receiver.reload
    assert_equal 3, receiver.reputation_points
    assert_equal ReputationThreshold.vote_down - 1, sender.reputation_points
  end

  def test_should_cancel_repute_vote_down
    kase = kases(:powerplant_leak)
    receiver = people(:barney).repute_and_return(5)
    sender = people(:bart).repute_and_return(ReputationThreshold.vote_down)
    rs1 = create_response(:kase => kase, :person => receiver)
    assert_equal true, rs1.activate!, "should accept response"
    result = rs1.send :repute_vote_down, sender
    assert_equal true, result.success?
    result = rs1.send :cancel_repute_vote_down, sender
    assert_equal true, result.success?
    receiver.reload
    sender.reload
    assert_equal 5, receiver.reputation_points
    assert_equal ReputationThreshold.vote_down, sender.reputation_points
  end

  def test_should_not_repute_vote_down_because_of_low_threshold
    kase = kases(:powerplant_leak)
    receiver = people(:barney)
    rs1 = create_response(:kase => kase, :person => receiver)
    assert_equal true, rs1.activate!, "should accept response"
    result = rs1.send :repute_vote_down, people(:bart)
    assert_equal false, result.success?
    assert_equal "Vote down requires 100 <a href=\"/faq\">Reputation Points</a>, you currently have 0. For more information, please visit our <a href=\"/faq\">FAQ page</a>.",
      result.message
  end

  def test_should_repute_accept
    kase = kases(:powerplant_leak)
    receiver = people(:barney)
    rs1 = create_response(:kase => kase, :person => receiver)
    assert_equal true, rs1.activate!, "should accept response"
    result = rs1.send :repute_accept
    assert_equal true, result.success?
    receiver.reload
    assert_equal 10, receiver.reputation_points
  end

  def test_should_cancel_repute_accept
    kase = kases(:powerplant_leak)
    receiver = people(:barney)
    rs1 = create_response(:kase => kase, :person => receiver)
    assert_equal true, rs1.activate!, "should accept response"
    result = rs1.send :repute_accept
    assert_equal true, result.success?
    result = rs1.send :cancel_repute_accept
    assert_equal true, result.success?
    receiver.reload
    assert_equal 0, receiver.reputation_points
  end
  
  def test_should_be_anonymous
    response = build_response(:person => nil)
    assert_equal false, response.anonymous?
    response.anonymous = true
    assert_equal true, response.anonymous?
  end
  
  protected
  
  def create_clarification_request(sender, clarification_options={:message => "question about your response"},
      response_options={}, kase_options={})
    assert response = create_response(response_options, kase_options)
    assert response.activate!, "should activate response"
    assert response.allows_clarification_request?(sender), "should allow clarification"
    assert request = response.create_clarification_request(sender, clarification_options)
    request.clarifiable.reload
    request
  end

end
