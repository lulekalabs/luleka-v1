require File.dirname(__FILE__) + '/../test_helper'

class BonusEventTest < ActiveSupport::TestCase
  all_fixtures

  def test_should_create
    assert_difference BonusEvent, :count do 
      BonusEvent.create(:source => kases(:powerplant_leak), :action => :accept_response,
        :receiver => people(:homer), :sender => people(:marge), :tier => tiers(:powerplant))
    end
  end
  
  def test_should_not_validate
    be = BonusEvent.new
    assert_equal false, be.valid?
    assert be.errors.on(:source), "should validate source"
    assert be.errors.on(:action), "should validate action"
    assert be.errors.on(:receiver), "should validate receiver"
  end
  
  def test_should_find_cashables
    assert_difference BonusReward, :count do 
      assert_difference BonusEvent, :count do
        tier = tiers(:powerplant)
        tier.bonus_rewards.create(:tier => tier, :source_class => "Response", 
          :beneficiary_type => :receiver, :action => :accept_response,
            :funding_source => tiers(:luleka), :cents => 50, :max_events_per_month => 5)
        be = create_bonus_event(:action => :accept_response, :tier => tier)
        assert_equal [be], BonusEvent.find_all_cashables
      end
    end
  end

  def test_should_not_find_cashables
    assert_difference BonusEvent, :count do
      tier = tiers(:powerplant)
      be = create_bonus_event(:action => :accept_response, :tier => tier)
      assert_equal [], BonusEvent.find_all_cashables
    end
    
    assert_difference BonusReward, :count do 
      assert_difference BonusEvent, :count do
        tier = tiers(:powerplant)
        tier.bonus_rewards.create(:tier => tier, :source_class => "Response", 
          :beneficiary_type => :receiver, :action => :not_a_valid_action,
            :funding_source => tiers(:luleka), :cents => 50, :max_events_per_month => 5)
        be = create_bonus_event(:action => :accept_response, :tier => tier)
        assert_equal [], BonusEvent.find_all_cashables
      end
    end
  end
    
  def test_should_cash
    assert_difference BonusReward, :count do 
      assert_difference BonusEvent, :count do
        sender, receiver = people(:bart), people(:barney)
        tier = tiers(:powerplant).direct_deposit_and_return(Money.new(100, "USD"))
        tier.bonus_rewards.create(:tier => tier, :source_class => "Response", 
          :beneficiary_type => :receiver, :action => :accept_response, :cents => 100, :max_events_per_month => 5)
        response = create_response(:person => receiver)
        be = BonusEvent.create(:source => response, :action => :accept_response, :receiver => receiver, :sender => sender, :tier => tier)
        assert_equal true, be.valid?, "should be valid"
        assert_equal :created, be.current_state, "should be created"

        receiver.reload and sender.reload
        before_balance = receiver.piggy_bank.balance
        assert_equal Money.new(100, "USD"), tiers(:powerplant).piggy_bank.balance
        assert_equal true, be.cash!
        assert_equal Money.new(1, "EUR") + before_balance + Money.new(100, "USD") - Money.new(1, "EUR"), 
          receiver.piggy_bank.balance
        tier.piggy_bank.reload  
        assert_equal Money.new(0, "USD"), tier.piggy_bank.balance
        
        be.reload
        assert be.cashed_at, "should have cashed_at date"
        assert_equal "Transfer of 0.74 € ($1.00) from Community \"Springfield Nuclear Powerplant Inc.\" to Person \"barney\"",
          be.description, "should have description"
      end
    end
  end

  def test_should_cash_with_maxed_out_events
    assert_difference BonusReward, :count do 
      assert_difference BonusEvent, :count, 2 do
        sender, receiver = people(:bart), people(:barney)
        tier = tiers(:powerplant).direct_deposit_and_return(Money.new(500, "USD"))
        tier.bonus_rewards.create(:tier => tier, :source_class => "Response", 
          :beneficiary_type => :receiver, :action => :accept_response, :cents => 100, :max_events_per_month => 1)
        re1 = create_response(:person => receiver)
        re2 = create_response(:person => receiver)
        
        be1 = BonusEvent.create(:source => re1, :action => :accept_response, :receiver => receiver, :sender => sender, :tier => tier)
        assert_equal true, be1.valid?, "should be valid"

        be2 = BonusEvent.create(:source => re2, :action => :accept_response, :receiver => receiver, :sender => sender, :tier => tier)
        assert_equal true, be2.valid?, "should be valid"

        assert_equal true, be1.cash!
        assert_equal :cashed, be1.current_state, "should be cashed"
        assert_equal true, be2.cash!
        assert_equal :closed, be2.current_state, "should be closed"
      end
    end
  end

  protected
  
  def valid_bonus_event_attributes(options={})
    {:source => kases(:powerplant_leak), :action => :accept_response,
      :receiver => people(:homer), :sender => people(:marge), :tier => tiers(:powerplant)}.merge(options)
  end
  
  def create_bonus_event(options={})
    BonusEvent.create(valid_bonus_event_attributes(options))
  end

  def build_bonus_event(options={})
    BonusEvent.new(valid_bonus_event_attributes(options))
  end
  
end
