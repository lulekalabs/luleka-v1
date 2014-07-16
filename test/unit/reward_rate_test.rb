require File.dirname(__FILE__) + '/../test_helper'

class RewardRateTest < ActiveSupport::TestCase
  all_fixtures
  
  def test_should_create
    assert_difference RewardRate, :count do 
      RewardRate.create(:tier => tiers(:powerplant), :source_class => "Response", 
        :beneficiary_type => :sender, :action => :accept_response,
          :funding_source => tiers(:luleka), :cents => 50, :max_events_per_month => 27, :points => 5, :percent => 7.5)
    end
  end

  def test_should_create_bonus_reward
    assert_difference BonusReward, :count do 
      BonusReward.create(:tier => tiers(:powerplant), :source_class => "Response", 
        :beneficiary_type => :sender, :action => :accept_response,
          :funding_source => tiers(:luleka), :cents => 50)
    end
  end

  def test_should_create_reputation_point
    assert_difference ReputationReward, :count do 
      ReputationReward.create(:tier => tiers(:powerplant), :source_class => "Response", 
        :beneficiary_type => :sender, :action => :accept_response,
          :funding_source => tiers(:luleka), :points => 50)
    end
  end

  def test_should_create_reputation_threshold
    assert_difference ReputationThreshold, :count do 
      ReputationThreshold.create(:tier => tiers(:powerplant), :source_class => "Response", 
        :action => :accept_response, :funding_source => tiers(:luleka), :points => 50)
    end
  end
  
  def test_should_validate_reputation_reward
    br = ReputationReward.new
    assert_equal false, br.valid?, "should not be valid"
    assert br.errors.on(:tier), "should not be valid without tier"
    assert br.errors.on(:action), "should not be valid without action"
    assert br.errors.on(:source_class), "should not be valid without source class"
    assert br.errors.on(:points), "should not be valid without points"
  end

  def test_should_validate_reputation_threshold
    br = ReputationThreshold.new
    assert_equal false, br.valid?, "should not be valid"
    assert br.errors.on(:tier), "should not be valid without tier"
    assert br.errors.on(:action), "should not be valid without action"
    assert br.errors.on(:points), "should not be valid without points"
  end

  def test_should_validate_bonus_reward
    br = BonusReward.new
    assert_equal false, br.valid?, "should not be valid"
    assert br.errors.on(:tier), "should not be valid without tier"
    assert br.errors.on(:action), "should not be valid without action"
    assert br.errors.on(:source_class), "should not be valid without source class"
    assert br.errors.on(:cents), "should not be valid without cents"
  end

  def test_should_funding_source
    br = RewardRate.new :tier => tiers(:powerplant)
    assert_equal tiers(:powerplant), br.funding_source
    
    br = RewardRate.new :tier => tiers(:powerplant), :funding_source => tiers(:luleka)
    assert_equal tiers(:luleka), br.funding_source
  end

  def test_should_create_bonus_rate
    assert_difference BonusReward, :count do 
      br = BonusReward.create(:tier => tiers(:powerplant), :source_class => "Response", 
        :beneficiary_type => :sender, :action => :accept_response,
          :funding_source => tiers(:luleka), :cents => 50)
      assert_equal [br], tiers(:powerplant).bonus_rewards
    end
  end

  def test_bonus_reward_should_be_valid_with_cents
    br = BonusReward.new(:tier => tiers(:powerplant), :source_class => "Response", :beneficiary_type => :receiver,
      :action => :accept_response, :cents => 100)
    assert_equal true, br.valid?
  end

  def test_bonus_reward_should_be_valid_with_percent
    br = BonusReward.new(:tier => tiers(:powerplant), :source_class => "Response", :beneficiary_type => :receiver,
      :action => :accept_response, :percent => 7.5)
    assert_equal true, br.valid?
  end
  
end
