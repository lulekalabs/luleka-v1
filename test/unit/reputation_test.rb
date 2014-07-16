require File.dirname(__FILE__) + '/../test_helper'

class ReputationTest < ActiveSupport::TestCase
  all_fixtures
  
  def setup
    @kase = create_problem
    @kase.activate!
  end
  
  def test_should_create
    assert_difference Reputation, :count do
      reputation = Reputation.create(:reputable => @kase, :sender => people(:homer), :receiver => people(:barney), 
        :action => :vote_up, :points => 5, :validate_threshold => false)
      assert_equal true, reputation.success?
    end
  end

  def test_should_not_validate_unsufficient_sender_reputation_count
    assert_no_difference Reputation, :count do
      reputation = Reputation.create(:reputable => @kase, :sender => people(:homer), :receiver => people(:barney), 
        :action => :vote_up, :points => 5)
      assert_equal false, reputation.success?
      assert_equal "Vote Up requires 15 <a href=\"/faq\">Reputation Points</a>, you currently have 0. For more information, please visit our <a href=\"/faq\">FAQ page</a>.",
        reputation.message
    end
  end
  
  def test_should_be_sender_threshold
    reputation = Reputation.new :validate_threshold => true
    assert_equal true, reputation.validate_threshold?

    reputation = Reputation.new :validate_threshold => false
    assert_equal false, reputation.validate_threshold?

    reputation = Reputation.new :validate_threshold => nil
    assert_equal true, reputation.validate_threshold?
  end

  def test_should_activate
    assert_difference Reputation, :count, 1 do
      reputation = Reputation.create(:reputable => @kase, :sender => people(:homer), :receiver => people(:barney), 
        :action => :vote_up, :points => 5, :validate_threshold => false)
      assert_equal true, reputation.success?
      assert_equal true, reputation.activate!
      reputation.receiver.reload
      assert_equal 5, reputation.receiver.reputation_points
    end
  end

  def test_should_sum
    assert_difference Reputation, :count, 3 do
      rp1 = Reputation.create(:reputable => @kase, :sender => people(:homer), :receiver => people(:barney), 
        :action => :vote_up, :points => 5, :validate_threshold => false)
      assert_equal true, rp1.activate!
      rp2 = Reputation.create(:reputable => @kase, :sender => people(:homer), :receiver => people(:barney), 
        :action => :vote_down, :points => -7, :validate_threshold => false)
      assert_equal true, rp2.activate!
      rp3 = Reputation.create(:reputable => @kase, :sender => people(:homer), :receiver => people(:barney), 
        :action => :vote_up, :points => 3, :validate_threshold => false)
      assert_equal true, rp3.activate!

      rp1.receiver.reload
      assert_equal 1, rp1.receiver[:reputation_points]
      
      assert_equal true, rp3.cancel!
      rp1.receiver.reload
      assert_equal -2, rp1.receiver[:reputation_points]
    end
  end
  
  def test_should_handle_vote_up
    response = create_response
    receiver = people(:barney)
    sender = people(:bart).repute_and_return(15)
    result = Reputation.handle(response, :vote_up, receiver, :sender => sender)
    assert_equal true, result.success?
    receiver.reload
    assert_equal 5, receiver.reputation_points
  end

  def test_should_handle_vote_down
    response = create_response
    receiver = people(:barney).repute_and_return(10)
    sender = people(:bart).repute_and_return(100)
    result = Reputation.handle(response, :vote_down, receiver, :sender => sender, :validate_sender => false)
    assert_equal true, result.success?
    receiver.reload
    sender.reload
    assert_equal 8, receiver.reputation_points
    assert_equal 99, sender.reputation_points
  end

  def test_should_cancel_vote_down
    response = create_response
    receiver = people(:barney).repute_and_return(10)
    sender = people(:bart).repute_and_return(100)
    result = Reputation.handle(response, :vote_down, receiver, :sender => sender, :validate_sender => false)
    assert_equal true, result.success?
    receiver.reload and assert_equal 8, receiver.reputation_points
    sender.reload and assert_equal 99, sender.reputation_points
    
    result = Reputation.cancel(response, :vote_down, receiver, :sender => sender)
    receiver.reload and assert_equal 10, receiver.reputation_points
    sender.reload and assert_equal 100, sender.reputation_points
  end

  def test_should_lookup_treshold_and_not_be_success
    th1 = Reputation::Threshold.lookup(:vote_up, people(:homer))
    assert_equal false, th1.success?
    assert_equal "Vote Up requires 15 <a href=\"/faq\">Reputation Points</a>, you currently have 0. For more information, please visit our <a href=\"/faq\">FAQ page</a>.",
      th1.message
  end

  def test_should_lookup_treshold_and_be_success
    th1 = Reputation::Threshold.lookup(:vote_up, people(:homer).repute_and_return(15))
    assert_equal true, th1.success?
    assert_equal nil, th1.message
  end

  def test_should_lookup_treshold_without_validate_sender_and_be_success
    th1 = Reputation::Threshold.lookup(:vote_up, people(:homer), :validate_sender => false)
    assert_equal true, th1.success?
    assert_equal nil, th1.message
  end

  def test_should_lookup_treshold_with_validate_sender_and_not_be_success
    th1 = Reputation::Threshold.lookup(:vote_up, people(:homer), :validate_sender => true)
    assert_equal false, th1.success?
  end

  def test_should_lookup_treshold_with_tier_and_be_success
    th1 = Reputation::Threshold.lookup(:vote_up, people(:homer).repute_and_return(10, tiers(:powerplant)), 
      :tier => tiers(:powerplant))
    assert_equal true, th1.success?
    assert_equal nil, th1.message
  end

  def test_should_not_lookup_treshold_with_tier
    assert_difference ReputationThreshold, :count do
      tier = tiers(:powerplant)
      tier.reputation_thresholds.create(:action => :vote_up, :points => 11)
      assert_equal false, tier.accept_person_total_reputation_points
      th1 = Reputation::Threshold.lookup(:vote_up, people(:homer).repute_and_return(10), :tier => tier)
      assert_equal false, th1.success?
      assert th1.message
    end
  end
  
  def test_should_lookup_threshold_with_tier_accept_person_total_reputation
    tiers(:powerplant).update_attributes(:accept_person_total_reputation_points => true)
    th1 = Reputation::Threshold.lookup(:vote_up, people(:homer).repute_and_return(10), 
      :tier => tiers(:powerplant))
    assert_equal true, th1.success?
    assert_equal nil, th1.message
  end

  def test_should_lookup_threshold_with_tier_accept_person_total_reputation_and_default_threshold
    tiers(:persil_us).accept_person_total_reputation_points = true
    tiers(:persil_us).accept_default_reputation_threshold = true
    assert tiers(:persil_us).save
    th1 = Reputation::Threshold.lookup(:vote_up, people(:homer).repute_and_return(14), 
      :tier => tiers(:persil_us))
    assert_equal false, th1.success?
    
    th1 = Reputation::Threshold.lookup(:vote_up, people(:homer).repute_and_return(1), 
      :tier => tiers(:persil_us))
    assert_equal true, th1.success?
  end

  def test_should_lookup_threshold_without_tier_threshold_being_defined
    tiers(:persil_us).accept_person_total_reputation_points = true
    tiers(:persil_us).accept_default_reputation_threshold = false
    assert tiers(:persil_us).save
    assert_equal 0, tiers(:persil_us).reputation_thresholds.count
    th1 = Reputation::Threshold.lookup(:vote_up, people(:homer), 
      :tier => tiers(:persil_us))
    assert_equal true, th1.success?
  end
  
  def test_should_handle_vote_up_with_tier
    assert_difference ReputationReward, :count do
      assert_difference ReputationThreshold, :count do
        tier = tiers(:powerplant)
        tr = tier.reputation_rewards.create(:source_class => "Response", 
          :beneficiary_type => :receiver, :action => :vote_up, :points => 5)
        th = tier.reputation_thresholds.create(:action => :vote_up, :points => 10)
        response = create_response
        receiver = people(:barney)
        sender = people(:bart).repute_and_return(10, tier)
        result = Reputation.handle(response, :vote_up, receiver, :sender => sender, :tier => tier)
        assert_equal true, result.success?
        receiver.reload
        assert_equal 5, receiver.reputation_points
        assert_equal 5, receiver.reputation_points(tier)
      end
    end
  end

  def test_should_handle_vote_down_with_tier
    assert_difference ReputationReward, :count, 2 do
      assert_difference ReputationThreshold, :count do
        tier = tiers(:powerplant)
        tier.reputation_rewards.create(:source_class => "Response", 
          :beneficiary_type => :receiver, :action => :vote_down, :points => -2)
        tier.reputation_rewards.create(:source_class => "Response", 
          :beneficiary_type => :sender, :action => :vote_down, :points => -5)
        tier.reputation_thresholds.create(:action => :vote_down, :points => 50)
        
        response = create_response
        receiver = people(:barney).repute_and_return(10)
        sender = people(:bart).repute_and_return(50, tiers(:powerplant))
        result = Reputation.handle(response, :vote_down, receiver, :sender => sender, :validate_sender => false, :tier => tier)
        assert_equal true, result.success?
        receiver.reload and sender.reload
        assert_equal 8, receiver.reputation_points
        assert_equal -2, receiver.reputation_points(tier)
        assert_equal 45, sender.reputation_points
      end
    end
  end

  def test_should_cancel_vote_down_with_tier
    assert_difference ReputationReward, :count, 2 do
      assert_difference ReputationThreshold, :count do
        tier = tiers(:powerplant)
        tier.reputation_rewards.create(:source_class => "Response", 
          :beneficiary_type => :receiver, :action => :vote_down, :points => -2)
        tier.reputation_rewards.create(:source_class => "Response", 
          :beneficiary_type => :sender, :action => :vote_down, :points => -5)
        tier.reputation_thresholds.create(:action => :vote_up, :points => 50)
        
        response = create_response
        receiver = people(:barney).repute_and_return(10)
        sender = people(:bart).repute_and_return(50, tiers(:powerplant))
        result = Reputation.handle(response, :vote_down, receiver, :sender => sender, :validate_sender => false, :tier => tier)
        assert_equal true, result.success?
        receiver.reload and assert_equal 8, receiver.reputation_points
        sender.reload and assert_equal 45, sender.reputation_points
    
        result = Reputation.cancel(response, :vote_down, receiver, :sender => sender, :tier => tier)
        receiver.reload and assert_equal 10, receiver.reputation_points
        sender.reload and assert_equal 50, sender.reputation_points
      end
    end
  end

  def test_should_handle_vote_up_with_parent_tier
    assert_difference ReputationReward, :count do
      assert_difference ReputationThreshold, :count do
        copy_reputation_settings(tiers(:powerplant), tiers(:powerplant_de))
        parent_tier, tier = tiers(:powerplant), tiers(:powerplant_de)
        tr = parent_tier.reputation_rewards.create(:source_class => "Response", 
          :beneficiary_type => :receiver, :action => :vote_up, :points => 5)
        th = parent_tier.reputation_thresholds.create(:action => :vote_up, :points => 10)
        response = create_response
        receiver = people(:barney)
        sender = people(:bart).repute_and_return(10, parent_tier)
        result = Reputation.handle(response, :vote_up, receiver, :sender => sender, :tier => tier)
        assert_equal true, result.success?
        receiver.reload
        assert_equal 5, receiver.reputation_points
        assert_equal 5, receiver.reputation_points(tier)
      end
    end
  end

  def test_should_lookup_treshold_with_parent_tier
    assert_difference ReputationThreshold, :count do
      copy_reputation_settings(tiers(:powerplant), tiers(:powerplant_de))
      parent_tier, tier = tiers(:powerplant), tiers(:powerplant_de)
      parent_tier.reputation_thresholds.create(:action => :vote_up, :points => 11)
      assert_equal false, parent_tier.accept_person_total_reputation_points
      assert_equal false, tier.accept_person_total_reputation_points
      assert_equal false, parent_tier.accept_default_reputation_threshold
      assert_equal false, tier.accept_default_reputation_threshold
      th1 = Reputation::Threshold.lookup(:vote_up, people(:homer).repute_and_return(10), :tier => tier)
      assert_equal false, th1.success?
      assert th1.message
    end
  end

  def test_should_not_handle_with_sender_equal_receiver
    response = create_response
    receiver = people(:barney)
    sender = people(:bart).repute_and_return(15)
    result = Reputation.handle(response, :vote_up, receiver, :sender => receiver)
    assert_equal false, result.success?
    assert_equal "Action is not allowed on your own post", result.message
    receiver.reload
    assert_equal 0, receiver.reputation_points
  end

  def test_should_handle_with_sender_equal_receiver_and_validate_self
    response = create_response
    receiver = people(:barney).repute_and_return(15)
    result = Reputation.handle(response, :vote_up, receiver, :sender => receiver, :validate_self => false)
    assert_equal true, result.success?
    receiver.reload
    assert_equal 20, receiver.reputation_points
  end

  protected
  
  def copy_reputation_settings(from_tier, to_tier)
    to_tier.accept_person_total_reputation_points = from_tier.accept_person_total_reputation_points
    to_tier.accept_default_reputation_threshold = from_tier.accept_default_reputation_threshold
    to_tier.accept_default_reputation_points = from_tier.accept_default_reputation_points
    to_tier.save!
    to_tier
  end

end
