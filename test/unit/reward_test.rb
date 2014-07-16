require File.dirname(__FILE__) + '/../test_helper'

class RewardTest < ActiveSupport::TestCase
  all_fixtures

  def setup
    I18n.locale = :"en-US"
    ExchangeRate.load_money_bank
  end
  
  def test_should_create
    person = people(:barney)
    kase = kases(:powerplant_leak)
    person.piggy_bank.direct_deposit(Money.new(100, 'USD'))
    
    assert_difference Reward, :count do
      reward = create_reward(:sender => person, :kase => kase)
    end
  end
  
  def test_should_copy_expires_at_from_kase
    time = Time.now.utc + 1.hour + 15.minutes + 27.seconds
    kase = create_problem(:expires_at => time)
    assert kase.activate!, "should activate"
    assert_equal time.to_i, kase.expires_at.to_i
    reward = Reward.new(:sender => people(:homer), :kase => kase)
    assert_equal time.to_i, reward.expires_at.to_i
  end

  def test_should_assign_string_price
    reward = build_reward(:price => "2.00")
    assert_equal "EUR", reward.default_currency
    assert_equal Money.new(200, "EUR"), reward.price
  end
  
  def test_should_assign_payment_type
    reward = build_reward(:payment_type => :piggy_bank)
    assert_equal :piggy_bank, reward.payment_type
  end

  def test_should_set_expiry_days
    reward = Reward.new(:expiry_days => 4)
    assert_equal 4, reward.expiry_days
  end

  def test_should_set_expiry_option
    reward = Reward.new
    assert_equal :in, reward.expiry_option
    assert reward.expiry_in?
    reward.expiry_option = 'in'
    assert_equal :in, reward.expiry_option
    assert reward.expiry_in?, "should expire in days"
    reward.expiry_option = 'on'
    assert_equal :on, reward.expiry_option
    assert reward.expiry_on?
  end
  
  def test_should_not_validate_minimum_fixed_price_with_payment_object_credit_card
    reward = build_reward(:sender => people(:marge),
      :price => "1.99", :payment_object => PaymentMethod.build(:visa))
    assert PaymentMethod.credit_card?(reward.payment_object), "should be credit card"
    assert_equal false, reward.valid?
    assert_equal true, reward.errors.invalid?(:price)
    assert_equal "must be between $2.00 and $200.00", reward.errors.on(:price)
  end
  
  def test_should_not_validate_minimum_fixed_price_with_payment_object_piggy_bank
    person = people(:marge)
    person.piggy_bank.direct_deposit(Money.new(100, 'USD'))
    reward = build_reward(:sender => person,
      :price => "0.04")
    assert PaymentMethod.piggy_bank?(reward.payment_object), "should be piggy bank"
    assert_equal false, reward.valid?
    assert_equal true, reward.errors.invalid?(:price)
    assert_equal "must be between $0.05 and $200.00", reward.errors.on(:price)
  end
  
  def test_should_not_validate_negative_minimum_fixed_price_with_payment_object_piggy_bank
    person = people(:marge)
    person.piggy_bank.direct_deposit(Money.new(100, 'USD'))
    reward = build_reward(:sender => person,
      :price => Money.new(-100, 'USD'))
    assert_equal false, reward.valid?
    assert_equal true, reward.errors.invalid?(:price)
    assert_equal "must be between $0.05 and $200.00", reward.errors.on(:price)
  end
  
  def test_should_not_validate_maximum_fixed_price_with_payment_type_piggy_bank
    person = people(:marge)
    person.piggy_bank.direct_deposit(Money.new(30000, 'USD'))
    reward = build_reward(:sender => person,
      :price => "200.01")
    assert_equal false, reward.valid?
    assert_equal true, reward.errors.invalid?(:price)
    assert_equal "must be between $0.05 and $200.00", reward.errors.on(:price)
  end
  
  def test_should_expire_in
    expiry_date = Time.now.utc + 4.days
    reward = build_reward(:expiry_option => 'in', :expiry_days => '4')
    assert_equal :in, reward.expiry_option
    assert_equal 4, reward.expiry_days
    reward.valid?
    assert expiry_date - reward.expires_at < 1.second, "should set expires_at"
  end
  
  def test_should_be_taxable
    reward = build_reward
    assert_equal true, reward.taxable?, 'all rewards are taxable'
  end
  
  def test_should_be_gross_price
    reward = build_reward
    assert_equal true, reward.price_is_gross?, 'offer prices are gross prices'
    assert_equal false, reward.price_is_net?
  end
  
  def test_should_purchase_and_authorize_with_piggy_bank
    people(:barney).piggy_bank.direct_deposit(Money.new(500, 'EUR'))
    reward = build_reward_with_kase_and_n_responses(:price => "5.00", :sender => people(:barney))

    order, payment = reward.send(:purchase_and_authorize)
    assert reward.valid?
    assert order
    assert_equal :pending, order.current_state
    assert payment
    assert payment.success?, 'payment should be valid'
    assert_equal Money.new(500, 'EUR'), order.gross_total
    assert_equal Money.new(0, 'EUR'), reward.sender.piggy_bank.available_balance
    assert_equal Money.new(500, 'EUR'), reward.sender.piggy_bank.balance
  end
  
  def test_should_calculate_taxes_on_purchase
    TaxRate.stubs(:find_tax_rate).returns(19.0)
    credit_card = build_credit_card(:type => 'bogus', :number => 1)
    assert credit_card.valid?

    reward = build_reward_with_kase_and_n_responses(:price => "5.00", :sender => people(:homer), 
      :payment_type => :credit_card)
    
    order, payment = reward.send(:purchase_and_authorize, credit_card)
    assert payment.success?, 'payment should be valid'

    assert_equal 19.0, order.line_items.first.tax_rate
    assert_equal Money.new(500, 'USD'), order.line_items.first.gross_total
    assert_equal Money.new(80, 'USD'), order.line_items.first.tax_total
    assert_equal Money.new(420, 'USD'), order.line_items.first.net_total

    assert_equal Money.new(500, 'USD'), order.gross_total
    assert_equal Money.new(80, 'USD'), order.tax_total
    assert_equal Money.new(420, 'USD'), order.net_total
  end
  
  def test_should_capture_and_cash
    owner = people(:lisa)
    owner.piggy_bank.direct_deposit(Money.new(5, 'USD'))
    acceptor = people(:marge)

    reward = build_reward_with_kase_and_n_responses({:price => "0.05", :sender => owner},
      {:person => owner})
    assert_equal true, reward.activate!, "should activate reward"
    assert_equal :active, reward.current_state

    assert_equal true, reward.kase.responses.first.accept!, "should accept first response and kick-off capture and cash"
    assert_equal :accepted, reward.kase.responses.first.current_state
    owner.reload

    assert_equal Money.new(0, 'USD'), owner.piggy_bank.balance
    assert_equal Money.new(4, 'USD'), acceptor.piggy_bank.balance
    assert_equal Money.new(1, 'USD'), Organization.probono.piggy_bank.balance

    # owner's kase purchase
    assert_equal 1, owner.purchase_orders.size, "should have one purchase order"
    assert_equal Money.new(5, 'USD'), owner.purchase_orders.first.total
    assert owner.purchase_orders.first.approved?, "owner's purchase order should be paid"
    assert owner.purchase_orders.first.invoice.paid?, "owner's purchase invoice should be paid"
    assert_nil owner.purchase_orders.first.shipping_address
    assert_equal "#{owner.name(:middle => false)}, #{owner.find_default_address.to_s}",
      owner.purchase_orders.first.billing_address.to_s
    assert_equal acceptor.billing_address.to_s,
      owner.purchase_orders.first.origin_address.to_s
    
    assert 0, owner.sales_orders.size
    
    # patner's kase sale
    assert 1, acceptor.sales_orders.size
    assert acceptor.sales_orders.first.approved?, "acceptor's sales order should be paid"
    assert Money.new(5, 'USD'), acceptor.sales_orders.first.total
    
    assert_equal "#{owner.name(:middle => false)}, #{owner.find_default_address.to_s}",
      acceptor.sales_orders.first.billing_address.to_s
    assert_equal acceptor.billing_address.to_s,
      acceptor.sales_orders.first.origin_address.to_s
    
    # acceptor's service fee purchase
    assert 1, acceptor.purchase_orders.size
    assert acceptor.purchase_orders.first.approved?, "acceptor's purchase order should be paid"
    assert Money.new(1, 'USD'), acceptor.purchase_orders.first.total
    assert_equal acceptor.billing_address.to_s, acceptor.purchase_orders.first.billing_address.to_s
    assert_equal Organization.probono.find_default_address.to_s, acceptor.purchase_orders.first.origin_address.to_s
    
    # probono's service fee sale
    assert 1, Organization.probono.sales_orders.size
    assert Organization.probono.sales_orders.first.approved?, "probono's sales order should be paid"
    assert Money.new(1, 'USD'), Organization.probono.sales_orders.first.total
    assert_equal acceptor.billing_address.to_s,
      Organization.probono.sales_orders.first.billing_address.to_s
    assert_equal Organization.probono.find_default_address.to_s,
      Organization.probono.sales_orders.first.origin_address.to_s
  end

  def test_should_cash
    owner = people(:lisa)
    owner.piggy_bank.direct_deposit(Money.new(5, 'USD'))
    partner = people(:marge)

    reward = build_reward_with_kase_and_n_responses({:price => "0.05", :sender => owner},
      {:person => owner})
    assert reward.activate!, "should activate reward"
    assert_equal :active, reward.current_state

    # partner accepts response
    assert reward.kase.responses.first.accept!, "should accept first response"
    
#    should aready be cashed through response.accept! assert reward.cash!, "should cash reward"
    reward.reload
    assert_equal :paid, reward.current_state
    
    reward.reload
    
    assert_equal "Reward for %{type}".t % {:type => reward.kase.class.human_name}, 
      reward.purchase_orders.first.line_items.first.sellable.name
    assert_equal "Reward for %{type} \"%{title}\"".t % {:type => reward.kase.class.human_name, :title => reward.kase.title}, 
      reward.purchase_orders.first.line_items.first.sellable.description
    
    assert_equal Money.new(0, 'USD'), reward.sender.piggy_bank.balance
    assert_equal Money.new(4, 'USD'), reward.receiver.piggy_bank.balance
    assert_equal Money.new(1, 'USD'), Organization.probono.piggy_bank.balance
  end
  
  def test_should_count_rewards_count
    people(:homer).piggy_bank.direct_deposit(Money.new(5000, 'USD'))
    people(:marge).piggy_bank.direct_deposit(Money.new(5000, 'USD'))
    assert_difference Reward, :count, 2 do
      r1 = create_reward(:sender => people(:homer))
      assert_equal true, r1.activate!
      r2 = create_reward(:sender => people(:marge))
      assert_equal true, r2.activate!
      kase = r1.kase
      kase.reload
      assert_equal 2, kase.rewards_count
    end
  end

  def test_should_count_rewards_count
    people(:homer).piggy_bank.direct_deposit(Money.new(5000, 'USD'))
    people(:marge).piggy_bank.direct_deposit(Money.new(5000, 'USD'))
    assert_difference Reward, :count, 2 do
      r1 = create_reward(:sender => people(:homer))
      r2 = create_reward(:sender => people(:marge))
      assert_equal true, r2.activate!, "should activate"
      assert_equal true, r2.cancel!, "should cancel"
      kase = r1.kase
      kase.reload
      assert_equal 0, kase.rewards_count
    end
  end

  def test_should_accumulate_kase_price_base_usd
    kase = create_problem(:person => people(:homer))
    assert_equal true, kase.activate!
    assert_equal Money.new(0, "USD"), kase.price
    assert_difference Reward, :count, 2 do
      r1 = create_reward(:kase => kase, :price => "1.47", :sender => people(:homer).direct_deposit_and_return(Money.new(5000, 'USD')))
      r2 = create_reward(:kase => kase, :price => "1.52", :sender => people(:marge).direct_deposit_and_return(Money.new(5000, 'USD')))
      assert_equal true, r1.activate!, "should activate"
      assert_equal true, r1.active_reward_from_sender?, "should have active reward"
      assert_equal true, r2.activate!, "should activate"
      kase = r1.kase
      kase.reload
      assert_equal Money.new(299, "USD"), kase.price
    end
  end

  def test_should_accumulate_kase_price_base_usd_with_mixed_currencies
    kase = create_problem(:person => people(:homer))
    assert_equal true, kase.activate!
    assert_equal Money.new(0, "USD"), kase.price
    assert_difference Reward, :count, 2 do
      r1 = create_reward(:kase => kase, :price => "1.34", :sender => people(:homer).direct_deposit_and_return(Money.new(5000, 'USD')))
      assert_equal true, r1.activate!, "should activate"
      
      r2 = create_reward(:kase => kase, :price => "1.04", :sender => people(:barney).direct_deposit_and_return(Money.new(5000, 'EUR')))
      assert_equal true, r2.activate!, "should activate"
      kase = r1.kase
      kase.reload
      assert_equal Money.new(273, "USD"), kase.price
    end
  end

  def test_should_accumulate_kase_price_base_eur_with_mixed_currencies
    kase = create_problem(:person => people(:bart))
    assert_equal true, kase.activate!
    assert_equal Money.new(0, "EUR"), kase.price
    assert_difference Reward, :count, 2 do
      r1 = create_reward(:kase => kase, :price => "2.47", :sender => people(:homer).direct_deposit_and_return(Money.new(5000, 'USD'))) # USD
      r2 = create_reward(:kase => kase, :price => "3.89", :sender => people(:barney).direct_deposit_and_return(Money.new(5000, 'EUR'))) # EUR
      assert_equal true, r1.activate!, "should activate"
      assert_equal true, r2.activate!, "should activate"
      kase = r1.kase
      kase.reload
      assert_equal Money.new(572, "EUR"), kase.price
    end
  end
  
  def test_should_accumulate_kase_price_with_cancel
    kase = create_problem(:person => people(:homer))
    assert_equal true, kase.activate!
    assert_equal Money.new(0, "USD"), kase.price
    assert_difference Reward, :count, 2 do
      r1 = create_reward(:kase => kase, :price => "1.47", :sender => people(:homer).direct_deposit_and_return(Money.new(5000, 'USD')))
      assert_equal true, r1.activate!, "should activate"
      r2 = create_reward(:kase => kase, :price => "1.52", :sender => people(:marge).direct_deposit_and_return(Money.new(5000, 'USD')))
      assert_equal true, r2.activate!, "should activate"
      assert_equal true, r1.cancel!
      r1.kase.reload
      assert_equal Money.new(152, "USD"), r1.kase.price
      assert_equal true, r2.cancel!
      r2.kase.reload
      assert_equal Money.new(0, "USD"), r2.kase.price
    end
  end
  
  def test_should_set_kase_expires_at
    kase = kases(:powerplant_leak)
    expires_at = Time.now.utc + 1.day + 1.hour + 1.minute
    assert_nil kase.expires_at, "should be not set"
    rw = create_reward(:kase => kase, :sender => kase.person.direct_deposit_and_return("1.00"), :price => "1.00",
      :expires_at => expires_at)
    assert_equal true, rw.activate!, "should activate"
    assert_equal expires_at.to_i, rw.expires_at.to_i, "should set expires at"
    assert_equal expires_at.to_i, kase.expires_at.to_i, "should set expires at for kase"
  end
  
  def test_should_validate_expires_at_less_than_minimum
    rw = build_reward(:expires_at => Time.now.utc + 1.hour)
    assert_equal false, rw.valid?, "should not validate"
    assert_equal "must be within #{Reward::MIN_EXPIRY_DAYS} and #{Reward::MAX_EXPIRY_DAYS} days from now", 
      rw.errors.on(:expires_at)
  end

  def test_should_not_validate_expires_at_less_than_maximum
    rw = build_reward(:expires_at => Time.now.utc + Reward::MAX_EXPIRY_DAYS.days + 1.hour)
    assert_equal false, rw.valid?, "should not validate"
    assert_equal "must be within #{Reward::MIN_EXPIRY_DAYS} and #{Reward::MAX_EXPIRY_DAYS} days from now", 
      rw.errors.on(:expires_at)
  end
  
  def test_should_have_min_price
    kase = kases(:powerplant_leak)
    rw1 = build_reward(:sender => kase.person.direct_deposit_and_return("1.00"), :price => "1.00", 
      :kase => kase, :expires_at => Time.now.utc + 1.day)
    assert_equal Money.new(5, "USD"), rw1.min_price
  end

  def test_should_have_min_price_based_on_active_reward
    kase = kases(:powerplant_leak)
    rw1 = build_reward(:sender => kase.person.direct_deposit_and_return("1.00"), :price => "1.00", 
      :kase => kase, :expires_at => Time.now.utc + 1.day)
    assert_equal Money.new(5, "USD"), rw1.min_price
    assert_equal true, rw1.save, "should save reward 1"
    assert_equal true, rw1.activate!, "should activate reward 1"
    
    # build another reward 1 EUR = 1.34
    rw2 = build_reward(:sender => people(:barney).direct_deposit_and_return("1.00"), :price => "1.00", 
      :kase => kase)
      
    # 1 USD => 0.743605 EUR
    assert_equal Money.new(79, "EUR"), rw2.min_price
  end
  
  def test_should_validate_price_range
    kase = kases(:powerplant_leak)
    assert_nil kase.max_reward_price, "should not have a max reward price"
    rw1 = create_reward(:sender => people(:marge).direct_deposit_and_return("1.00"), :price => "1.00")
    assert_equal true, rw1.activate!
    assert_equal Money.new(100, "USD"), kase.max_reward_price
    rw2 = build_reward(:sender => people(:bart).direct_deposit_and_return("1.00"), :price => "1.00")
    assert_equal Money.new(79, "EUR"), rw2.min_price # $1.00 in EUR
    assert_equal true, rw2.valid?, "should be valid as we are offering $1.34 (=1.00 Euro)"
    assert_equal true, rw2.activate!
    assert_equal Money.new(134, "USD"), kase.max_reward_price
    rw3 = build_reward(:sender => people(:lisa).direct_deposit_and_return("1.00"), :price => "1.00")
    assert_equal false, rw3.valid?, "should not be valid, due to lower min price"
    assert_equal "must be between $1.39 and $200.00", rw3.errors.on(:price)
  end

  def test_should_have_max_price
    kase = kases(:powerplant_leak)
    rw1 = build_reward(:sender => kase.person.direct_deposit_and_return("1.00"), :price => "1.00", 
      :kase => kase, :expires_at => Time.now.utc + 1.day)
    assert_equal Money.new(20000, "USD"), rw1.max_price
  end
  
  def test_should_have_min_price_based_existing_reward
    assert_difference Reward, :count, 1 do
      kase = kases(:powerplant_leak)
      rw1 = create_reward(:sender => kase.person.direct_deposit_and_return("5.00"), :price => "1.00", 
        :kase => kase, :expires_at => Time.now.utc + 1.day)
      assert_equal true, rw1.activate!, "should activate reward 1"
      kase = Kase.find_by_id(kase.id)
      rw2 = build_reward(:sender => kase.person.direct_deposit_and_return("1.00"), :price => "1.00", 
        :kase => kase, :expires_at => Time.now.utc + 1.day)
      assert_equal Money.new(105, "USD"), rw2.min_price
    end
  end

  def test_should_update_reward_from_same_sender
    assert_difference Reward, :count, 2 do
      people(:homer).piggy_bank.direct_deposit(Money.new(5000, 'USD'))
      kase = create_problem(:person => people(:homer))
      assert_equal true, kase.activate!
      r1 = create_reward(:kase => kase, :price => "2.00", :sender => people(:homer))
      assert_equal true, r1.activate!, "should activate"
      r2 = build_reward(:kase => kase, :price => "3.00", :sender => people(:homer))
      assert_equal true, r2.valid?, "should be valid"
      assert_equal true, r2.activate!, "should activate"
      kase = Kase.find_by_id(r2.kase.id)
      assert_equal Money.new(300, "USD"), r2.kase.price
      assert_equal Money.new(4700, "USD"), people(:homer).piggy_bank.available_balance
    end
  end

  def test_should_not_validate_on_closed_kase
    assert_no_difference Reward, :count do
      kase = create_problem(:person => people(:homer).direct_deposit_and_return("1.00"))
      assert_equal true, kase.activate!, "should activate kase"
      assert_equal true, kase.cancel!, "should close kase"
      rw1 = create_reward(:kase => kase, :price => "1.00", :sender => people(:homer))
      assert_equal false, rw1.valid?, "should not be valid on closed kase"
      assert_equal "cannot add new rewards", rw1.errors.on(:kase), "should not be able to add new reward"
    end
  end
  
  protected

  def build_reward_with_kase_and_n_responses(reward_options={}, kase_options={}, n=2, response_options={})
    kase = Kase.create(valid_kase_attributes({:title => "A new problem!", 
      :person => people(:homer), :type => :problem, :expires_at => Time.now.utc + 3.days}.merge(kase_options)))
    kase.activate!
    
    n.times do |index|
      response = kase.build_response(people([:marge, :bart, :lisa, :quentin, :aaron][index % n]), 
        {:description => "The answers is #{n + 1}!"}.merge(response_options))
      response.activate!
    end

    reward = build_reward(valid_reward_attributes({:sender => people(:barney),
      :kase => kase}.merge(reward_options)))
    reward  
  end
  
end
