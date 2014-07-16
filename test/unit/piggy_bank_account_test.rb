require File.dirname(__FILE__) + '/../test_helper'

class PiggyBankAccountTest < ActiveSupport::TestCase
  all_fixtures

  def test_should_create
    assert_difference PiggyBankAccount, :count do 
      pb = PiggyBankAccount.create(:currency => 'EUR')
      assert pb.valid?
      assert pb.balance.zero?
      assert_equal 'EUR', pb.currency 
    end
  end
  
  def test_should_create_account_when_person_is_created
    assert_difference User, :count do 
      assert_difference Person, :count do 
        assert_difference PiggyBankAccount, :count do 
          u = create_user(:currency => 'EUR')
          assert_equal 'EUR', u.person.piggy_bank.currency 
          assert Money.new(0, 'EUR'), u.person.piggy_bank.balance
          assert Money.new(0, 'EUR'), u.person.piggy_bank.available
        end
      end
    end
  end
  
  def test_should_be_type_piggy_bank
    pb = create_piggy_bank_account
    assert_equal :piggy_bank, pb.type
    assert_equal :piggy_bank, pb.kind
    assert_equal :piggy_bank, PiggyBankAccount.kind
  end

  def should_return_transaction_fee
    pb = create_piggy_bank_account
    assert_equal "0.50", pb.transaction_fee.to_s
    assert_equal "0.50", pb.fee.to_s
  end
  
  def test_should_deposit
    pb = create_piggy_bank_account
    assert_difference PiggyBankAccountTransaction, :count do
      result = pb.deposit(Money.new(500, 'EUR'))
      assert result.success?
      assert_equal Money.new(500, 'EUR'), result.amount
      assert_equal :deposit, result.action
    end
    assert_equal "5.00", pb.balance.to_s
    assert_equal "0.00", pb.available.to_s
  end

  def test_should_direct_deposit
    pb = create_piggy_bank_account
    assert_difference PiggyBankAccountTransaction, :count do
      result = pb.direct_deposit(Money.new(500, 'EUR'))
      assert result.success?
      assert_equal Money.new(500, 'EUR'), result.amount
      assert_equal :direct_deposit, result.action
    end
    assert_equal "5.00", pb.balance.to_s
    assert_equal "5.00", pb.available.to_s
  end

  def test_should_have_available_balance_on_cooling_period
    pb = create_piggy_bank_account
    result = pb.deposit(Money.new(500, 'EUR'), :created_at => Time.now.utc - PiggyBankAccount::COOLING_PERIOD_IN_DAYS.days)
    assert result.success?
    assert_equal "5.00", pb.balance.to_s
    assert_equal "5.00", pb.available.to_s
  end

  def test_should_have_available_balance_with_less_than_cooling_period
    pb = create_piggy_bank_account
    result = pb.deposit(Money.new(500, 'EUR'), :created_at => Time.now.utc - PiggyBankAccount::COOLING_PERIOD_IN_DAYS.days + 1.day)
    assert result.success?
    assert_equal "5.00", pb.balance.to_s
    assert_equal "0.00", pb.available.to_s
  end

  def test_should_have_available_balance_with_more_than_cooling_period
    pb = create_piggy_bank_account
    result = pb.deposit(Money.new(500, 'EUR'), :created_at => Time.now.utc - PiggyBankAccount::COOLING_PERIOD_IN_DAYS.days - 1.day)
    assert result.success?
    assert_equal "5.00", pb.balance.to_s
    assert_equal "5.00", pb.available.to_s
  end
  
  def test_should_have_balance_with_ending_at
    pb = create_piggy_bank_account
    result = pb.deposit(Money.new(500, 'EUR'), :created_at => Time.now.utc - 200.days)
    assert result.success?
    assert_equal '5.00', pb.balance.to_s
    result = pb.deposit(Money.new(500, 'EUR'), :created_at => Time.now.utc - 100.days)
    assert result.success?
    assert_equal '10.00', pb.balance.to_s
    
    assert_equal '0.00', pb.balance(Time.now.utc - 201.days).to_s
    assert_equal '5.00', pb.balance(Time.now.utc - 101.days).to_s
    assert_equal '10.00', pb.balance(Time.now.utc - 99.days).to_s
  end

  def test_should_have_available_balance_with_ending_at
    pb = create_piggy_bank_account
    result = pb.deposit(Money.new(500, 'EUR'), :created_at => Time.now.utc - 200.days)
    assert result.success?
    assert_equal '5.00', pb.available_balance.to_s
    result = pb.deposit(Money.new(500, 'EUR'), :created_at => Time.now.utc - 100.days)
    assert result.success?
    assert_equal '10.00', pb.available_balance.to_s
    
    assert_equal '0.00', pb.available_balance(Time.now.utc - 201.days).to_s
    assert_equal '5.00', pb.available_balance(Time.now.utc - 101.days).to_s
    assert_equal '10.00', pb.available_balance(Time.now.utc - 99.days).to_s
  end

  
  def test_should_withdraw
    pb = create_5_euro_account
    assert_difference PiggyBankAccountTransaction, :count do  # 2 from pb and one for organization
      result = pb.withdraw(Money.new(100, 'EUR'))
      assert result.success?
      assert_equal :withdraw, result.action
      assert_equal '4.00', pb.balance.to_s
      assert_equal '4.00', pb.available_balance.to_s
    end

    assert_difference PiggyBankAccountTransaction, :count do
      result = pb.withdraw(Money.new(50, 'EUR'), :fee => false)
      assert result.success?
      assert_equal :withdraw, result.action
      assert_equal Money.new(50, 'EUR'), result.amount
      assert_equal '3.50', pb.balance.to_s
      assert_equal '3.50', pb.available_balance.to_s
    end

    assert_difference PiggyBankAccountTransaction, :count, 2 + 1 do
      result = pb.withdraw(Money.new(125, 'EUR'), :fee => Money.new(75, 'EUR'))
      assert result.success?
      assert_equal :withdraw, result.action
      assert_equal '1.50', pb.balance.to_s
      assert_equal '1.50', pb.available_balance.to_s
    end
  end

  def test_should_withdraw_and_book_fee_to_company
    pb = create_5_euro_account
    result = pb.withdraw(Money.new(100, 'EUR'), :fee => true)
    assert result.success?
    assert_equal '3.50', pb.balance.to_s
    assert_equal '3.50', pb.available.to_s
    # Note: probono is a USD account and the transaction fee is in EUR,
    #       henceforth, we are looking at 67 cents in the probono account
    assert_equal Money.new(67, 'USD'), Organization.probono.piggy_bank.balance
    assert_equal Money.new(0, 'USD'), Organization.probono.piggy_bank.available_balance
  end

  def test_should_not_withdraw
    pb = create_5_euro_account
    result = pb.withdraw(Money.new(501, 'EUR'))
    assert !result.success?, 'insufficient funds on withdraw'
  end

  def test_should_purchase
    pb = create_5_euro_account
    result = pb.purchase(Money.new(300, 'EUR'))
    assert result.success?
    assert_equal :purchase, result.action
    assert_equal Money.new(300, 'EUR'), result.amount
    assert_equal '2.00', pb.balance.to_s
    assert_equal '2.00', pb.available.to_s
  end

  def test_should_not_purchase
    pb = create_5_euro_account
    result = pb.purchase(Money.new(501, 'EUR'))
    assert !result.success?, 'insufficient funds on purchase'
  end

  def test_should_authorize
    pb = create_5_euro_account
    result = pb.deposit(Money.new(100, 'EUR'))
    assert result.success?
    assert_equal '6.00', pb.balance.to_s, 'balance'
    assert_equal '5.00', pb.available.to_s, 'available balance'
    result = pb.authorize(Money.new(300, 'EUR'))
    assert result.success?
    assert_equal :authorize, result.action
    assert_equal Money.new(300, 'EUR'), result.amount
    assert_equal 40, result.authorization.size
    assert_equal 1, pb.authorizations_count
    assert_equal '6.00', pb.balance.to_s, 'balance'
    assert_equal '2.00', pb.available.to_s, 'available balance'
  end

  def test_should_not_authorize
    pb = create_5_euro_account
    result = pb.deposit(Money.new(100, 'EUR'))
    assert result.success?
    
    result = pb.authorize(Money.new(600, 'EUR'))
    assert !result.success?, 'should not authorize'
    assert_equal :authorize, result.action
    assert_equal Money.new(600, 'EUR'), result.amount
    assert_nil result.authorization
    assert_equal 0, pb.authorizations_count
    assert_equal '6.00', pb.balance.to_s, 'balance'
    assert_equal '5.00', pb.available.to_s, 'available balance'
  end

  def test_should_authorize_until_available_balance_is_depleted
    pb = create_5_euro_account
    result = pb.deposit(Money.new(100, 'EUR'))
    assert result.success?
    assert_equal '6.00', pb.balance.to_s, 'balance'
    assert_equal '5.00', pb.available.to_s, 'available balance'
    
    5.times do |index|
      result = pb.authorize(Money.new(100, 'EUR'))
      assert result.success?, "should authorize #{index}, #{result.amount.to_s}"
      assert_equal index + 1, pb.authorizations_count
      assert_equal '6.00', pb.balance.to_s, 'balance'
      assert_equal Money.new(500 - ((index + 1) * 100), 'EUR').to_s, pb.available.to_s, 'available balance'
    end
    assert_equal 5, pb.transactions.authorized.pending.count
    
    result = pb.authorize(Money.new(1, 'EUR'))
    assert !result.success?, "should not authorize"
    assert_equal '6.00', pb.balance.to_s, 'balance'
    assert_equal '0.00', pb.available.to_s, 'available balance'
    assert_equal 5, pb.authorizations_count
  end


  def test_should_capture_exact_amount
    pb = create_5_euro_account
    result = pb.deposit(Money.new(100, 'EUR'))
    assert result.success?
    result = pb.authorize(Money.new(300, 'EUR'))
    assert result.success?
    assert_equal '6.00', pb.balance.to_s, 'balance'
    assert_equal '2.00', pb.available.to_s, 'available balance'
    authorization = result.authorization 
    assert_equal 1, pb.authorizations_count
    assert 40, authorization.size
    
    result = pb.capture(Money.new(300, 'EUR'), authorization)
    assert result.success?
    assert_equal :capture, result.action
    assert_equal authorization, pb.transactions.find_by_action('capture').authorization
    assert_equal 0, pb.authorizations_count
    assert_equal '3.00', pb.balance.to_s, 'balance'
    assert_equal '2.00', pb.available.to_s, 'available balance'
  end

  def test_should_not_capture_larger_amount
    pb = create_5_euro_account
    result = pb.deposit(Money.new(100, 'EUR'))
    assert result.success?
    result = pb.authorize(Money.new(300, 'EUR'))
    assert result.success?
    assert_equal '6.00', pb.balance.to_s, 'balance'
    assert_equal '2.00', pb.available.to_s, 'available balance'
    authorization = result.authorization 
    assert_equal 1, pb.authorizations_count
    assert 40, authorization.size
    
    result = pb.capture(Money.new(301, 'EUR'), authorization)
    assert !result.success?
    assert_equal "amount cannot exceed authorized amount", result.description
    assert_equal 1, pb.authorizations_count
    assert_equal '6.00', pb.balance.to_s, 'balance'
    assert_equal '2.00', pb.available.to_s, 'available balance'
  end

  def test_should_capture_smaller_amount
    pb = create_5_euro_account
    result = pb.deposit(Money.new(100, 'EUR'))
    assert result.success?
    result = pb.authorize(Money.new(300, 'EUR'))
    assert result.success?
    assert_equal '6.00', pb.balance.to_s, 'balance'
    assert_equal '2.00', pb.available.to_s, 'available balance'
    authorization = result.authorization 
    assert_equal 1, pb.authorizations_count
    assert 40, authorization.size
    
    result = pb.capture(Money.new(200, 'EUR'), authorization)
    assert result.success?
    assert_equal 0, pb.authorizations_count
    assert_equal '4.00', pb.balance.to_s, 'balance'
    assert_equal '3.00', pb.available.to_s, 'available balance'
  end

  def test_should_not_capture_expired_authorization
    pb = create_5_euro_account
    result = pb.deposit(Money.new(100, 'EUR'))
    assert result.success?
    result = pb.authorize(Money.new(300, 'EUR'),
      :created_at => Time.now.utc - PiggyBankAccount::AUTHORIZATION_EXPIRY_PERIOD - 1.day,
      :expires_at => Time.now.utc - 1.day
    )
    assert result.success?
    
    assert_equal (Time.now.utc - PiggyBankAccount::AUTHORIZATION_EXPIRY_PERIOD - 1.day).to_date.to_s,
      pb.transactions.authorized.first.created_at.to_date.to_s
    assert_equal (Time.now.utc - 1.day).to_date.to_s,
      pb.transactions.authorized.first.expires_at.to_date.to_s
      
    assert_equal '6.00', pb.balance.to_s, 'balance'
    assert_equal '2.00', pb.available.to_s, 'available balance'
    authorization = result.authorization 
    assert_equal 1, pb.authorizations_count
    assert 40, authorization.size
    
    result = pb.capture(Money.new(300, 'EUR'), authorization)
    assert !result.success?
    assert_equal "authorization not found or authorization expired", result.description
    assert_equal 1, pb.authorizations_count
    assert_equal '6.00', pb.balance.to_s, 'balance'
    assert_equal '2.00', pb.available.to_s, 'available balance'
  end

  def test_should_not_capture
    pb = create_5_euro_account
    result = pb.capture(Money.new(300, 'EUR'), 'bogus_authorization')
    assert !result.success?
    assert_equal "authorization not found or authorization expired", result.description
  end
  
  def test_should_void
    pb = create_5_euro_account
    result = pb.deposit(Money.new(100, 'EUR'))
    assert result.success?
    result = pb.authorize(Money.new(300, 'EUR'))
    assert result.success?
    assert_equal '6.00', pb.balance.to_s, 'balance'
    assert_equal '2.00', pb.available.to_s, 'available balance'
    authorization = result.authorization 
    assert_equal 1, pb.authorizations_count
    assert 40, authorization.size
    
    result = pb.void(authorization)
    assert result.success?
    assert_equal :void, result.action
    assert_equal authorization, pb.transactions.find_by_action('void').authorization
    assert_equal 0, pb.authorizations_count
    assert_equal '6.00', pb.balance.to_s, 'balance'
    assert_equal '5.00', pb.available.to_s, 'available balance'
  end

  def test_should_not_void
    pb = create_5_euro_account
    result = pb.deposit(Money.new(100, 'EUR'))
    assert result.success?
    result = pb.authorize(Money.new(300, 'EUR'))
    assert result.success?
    assert_equal '6.00', pb.balance.to_s, 'balance'
    assert_equal '2.00', pb.available.to_s, 'available balance'
    authorization = result.authorization 
    assert_equal 1, pb.authorizations_count
    assert 40, authorization.size

    result = pb.void('asdf')
    assert !result.success?
    assert_equal :void, result.action
    assert_equal "authorization not found", result.description
    assert_equal 1, pb.authorizations_count
    assert_equal '6.00', pb.balance.to_s, 'balance'
    assert_equal '2.00', pb.available.to_s, 'available balance'
  end

  def test_void_all_pending_expired_authorizations
    pb = prepare_expired_authorizations
    
    PiggyBankAccount.void_pending_expired_authorizations
    assert_equal 0, pb.transactions.authorized.pending.expired.count
    pb.reload
    assert_equal 0, pb.authorizations_count
  end

  def test_should_void_all_pending_expired_authorizations_for_system
    pb = prepare_expired_authorizations
    
    PiggyBankAccount.void_pending_expired_authorizations
    assert_equal 0, pb.transactions.authorized.pending.expired.count
    pb.reload
    assert_equal 0, pb.authorizations_count
    assert_equal "50.00", pb.balance.to_s
    assert_equal "50.00", pb.available_balance.to_s
  end

  def test_should_void_all_pending_expired_authorizations_for_account
    pb = prepare_expired_authorizations
    
    pb.void_pending_expired_authorizations
    assert_equal 0, pb.transactions.authorized.pending.expired.count
    pb.reload
    assert_equal 0, pb.authorizations_count
    assert_equal "50.00", pb.balance.to_s
    assert_equal "50.00", pb.available_balance.to_s
  end

  def test_should_transfer
    from = create_5_euro_account
    to = create_5_euro_account
    result = from.transfer(to, Money.new(200, 'EUR'))
    assert result.success?
    assert_equal :transfer, result.action
    assert_equal "7.00", to.balance.to_s
    assert_equal "5.00", to.available_balance.to_s
    assert_equal "3.00", from.balance.to_s
    assert_equal "3.00", from.available_balance.to_s
  end

  def test_should_not_transfer_insufficient_from_funds
    from = create_piggy_bank_account
    to = create_5_euro_account
    result = from.transfer(to, Money.new(100, 'EUR'))
    assert !result.success?
    assert_equal "5.00", to.balance.to_s
    assert_equal "5.00", to.available_balance.to_s
    assert_equal "0.00", from.balance.to_s
    assert_equal "0.00", from.available_balance.to_s
  end

  def test_should_not_transfer_amount_too_small
    from = create_5_euro_account
    to = create_5_euro_account
    result = from.transfer(to, Money.new(99, 'EUR'))
    assert !result.success?
    assert_equal "5.00", to.balance.to_s
    assert_equal "5.00", to.available_balance.to_s
    assert_equal "5.00", from.balance.to_s
    assert_equal "5.00", from.available_balance.to_s
  end

  def test_should_not_transfer_amount_too_high
    from = create_5_euro_account
    to = create_5_euro_account
    result = from.transfer(to, Money.new(10001, 'EUR'))
    assert !result.success?
    assert_equal "5.00", to.balance.to_s
    assert_equal "5.00", to.available_balance.to_s
    assert_equal "5.00", from.balance.to_s
    assert_equal "5.00", from.available_balance.to_s
  end

  def test_should_not_transfer_amount_to_unknown_account_type
    from = create_5_euro_account
    to = create_5_euro_account
    result = from.transfer(String.new, Money.new(100, 'EUR'))
    assert !result.success?
    assert_equal "5.00", from.balance.to_s
    assert_equal "5.00", from.available_balance.to_s
  end

  def test_should_not_transfer_amount_to_self
    from = create_5_euro_account
    result = from.transfer(from, Money.new(100, 'EUR'))
    assert !result.success?
    assert_equal "5.00", from.balance.to_s
    assert_equal "5.00", from.available_balance.to_s
  end

  def test_should_deposit_usd_amount_into_filled_eur_account
    pb = create_5_euro_account
    result = pb.deposit(Money.new(100, 'USD'))
    assert result.success?
    assert_equal :deposit, result.action
    assert_equal Money.new(100, 'USD'), result.amount
    assert_equal Money.new(574, 'EUR'), pb.balance
  end

  def test_should_deposit_usd_amount_into_empty_eur_account
    pb = create_piggy_bank_account(:currency => 'EUR')
    assert pb.balance.zero?
    result = pb.deposit(Money.new(100, 'USD'))
    assert_equal Money.new(74, 'EUR'), pb.balance
  end

  def test_should_transfer_between_different_currency_accounts
    from = create_5_euro_account
    to = create_5_usd_account
    
    result = from.transfer(to, Money.new(100, 'EUR'))
    assert result.success?
    assert_equal Money.new(400, 'EUR'), from.balance
    assert_equal Money.new(634, 'USD'), to.balance
  end

  def test_should_transfer_between_same_currency_accounts
    from = create_5_euro_account
    to = create_5_euro_account
    
    result = from.transfer(to, Money.new(100, 'EUR'))
    assert result.success?, 'should transfer'
    assert_equal Money.new(400, 'EUR'), from.balance
    assert_equal Money.new(600, 'EUR'), to.balance
  end

  def test_should_transfer_between_different_currency_accounts_and_mixed_transfer_amount
    from = create_5_euro_account
    to = create_5_usd_account
    
    result = from.transfer(to, Money.new(100, 'USD'))
    assert result.success?, 'should transfer'
    assert_equal Money.new(425, 'EUR'), from.balance
    assert_equal Money.new(600, 'USD'), to.balance
  end

  def test_should_transfer_within_limits
    from = create_5_euro_account
    to = create_5_euro_account
    
    result = from.transfer(to, Money.new(50, 'EUR'), :limits => [50, 10000])
    assert result.success?, 'should transfer'
    assert_equal Money.new(450, 'EUR'), from.balance
    assert_equal Money.new(550, 'EUR'), to.balance
  end

  def test_should_transfer_within_money_limits
    from = create_5_euro_account
    to = create_5_euro_account
    
    result = from.transfer(to, Money.new(30, 'EUR'), :limits => [Money.new(30, 'EUR'), Money.new(100, 'EUR')])
    assert result.success?, 'should transfer'
    assert_equal Money.new(470, 'EUR'), from.balance
    assert_equal Money.new(530, 'EUR'), to.balance
  end

  def test_should_transfer_without_limits
    from = create_5_euro_account
    to = create_5_euro_account
    
    result = from.transfer(to, Money.new(1, 'EUR'), :limits => false)
    assert result.success?, 'should transfer'
    assert_equal Money.new(499, 'EUR'), from.balance
    assert_equal Money.new(501, 'EUR'), to.balance
  end

  def test_should_not_transfer_without_limits_exceeding_balance
    from = create_5_euro_account
    to = create_5_euro_account
    
    result = from.transfer(to, Money.new(501, 'EUR'), :limits => false)
    assert !result.success?, 'should not transfer'
    assert_equal Money.new(500, 'EUR'), from.balance
    assert_equal Money.new(500, 'EUR'), to.balance
  end

  def test_should_not_transfer_outside_lower_limit
    from = create_5_euro_account
    to = create_5_euro_account
    
    result = from.transfer(to, Money.new(30, 'EUR'), :limits => [50, 100])
    assert !result.success?, 'should not transfer'
    assert_equal Money.new(500, 'EUR'), from.balance
    assert_equal Money.new(500, 'EUR'), to.balance
  end

  def test_should_not_transfer_outside_upper_limit
    from = create_5_euro_account
    to = create_5_euro_account
    
    result = from.transfer(to, Money.new(101, 'EUR'), :limits => [50, 100])
    assert !result.success?, 'should not transfer'
    assert_equal Money.new(500, 'EUR'), from.balance
    assert_equal Money.new(500, 'EUR'), to.balance
  end

  def test_should_switch_test_mode
    old_mode = PiggyBankAccount.mode
    PiggyBankAccount.mode = :test
    pb = create_piggy_bank_account
    assert_equal true, PiggyBankAccount.test?
    assert_equal true, pb.test?

    PiggyBankAccount.mode = :na
    assert_equal false, PiggyBankAccount.test?
    assert_equal false, pb.test?
    PiggyBankAccount.mode = old_mode
  end
  
  def test_should_credit
    pb = create_5_euro_account
    result = pb.authorize(Money.new(400, 'EUR'))
    assert result.success?
    authorization = result.authorization
    
    result = pb.capture(Money.new(400, 'EUR'), authorization)
    assert result.success?
    assert_equal authorization, pb.transactions.find_by_action('capture').authorization
    assert_equal '1.00', pb.balance.to_s
    assert_equal '1.00', pb.available_balance.to_s
    
    result = pb.credit(Money.new(200, 'EUR'), authorization)
    assert result.success?
    assert_equal :credit, result.action
    assert_equal authorization, pb.transactions.find_by_action('credit').authorization
    assert_equal '2.00', result.amount.to_s
    assert_equal '3.00', pb.balance.to_s
    assert_equal '3.00', pb.available_balance.to_s
  end

  def test_should_not_credit_larger_amount_than_was_authorized_and_captured
    pb = create_5_euro_account
    result = pb.authorize(Money.new(400, 'EUR'))
    assert result.success?
    authorization = result.authorization
    
    result = pb.capture(Money.new(400, 'EUR'), authorization)
    assert result.success?
    assert_equal authorization, pb.transactions.find_by_action('capture').authorization
    assert_equal '1.00', pb.balance.to_s
    assert_equal '1.00', pb.available_balance.to_s
    
    result = pb.credit(Money.new(500, 'EUR'), authorization)
    assert !result.success?, 'credit amount exceeds captured amount'
    assert_equal "amount exceeds authorized/captured amount", result.description
    assert_equal '1.00', pb.balance.to_s
    assert_equal '1.00', pb.available_balance.to_s
  end

  def test_should_not_credit_authorized_but_not_captured_transaction
    pb = create_5_euro_account
    result = pb.authorize(Money.new(400, 'EUR'))
    assert result.success?
    authorization = result.authorization
    
    result = pb.credit(Money.new(500, 'EUR'), authorization)
    assert !result.success?, 'was not captured'
    assert_equal "authorization not found, captured, expired or voided", result.description
    assert_equal '5.00', pb.balance.to_s
    assert_equal '1.00', pb.available_balance.to_s
  end

  def test_should_not_credit_with_bogus_authorization
    pb = create_5_euro_account
    result = pb.credit(Money.new(500, 'EUR'), '2323jk23423423k4h')
    assert !result.success?, 'was not captured'
  end

  def test_should_store_transaction_context
    pb = create_5_euro_account
    result = pb.deposit(Money.new(500, 'EUR'), :context => people(:homer))
    assert result.success?
    assert_equal people(:homer), pb.transactions.find(:first, :order => "created_at DESC").context
  end

  def test_should_transfer_remaining_funds_on_destroy
    account = create_5_euro_account
    assert_equal Money.new(500, 'EUR'), account.balance
    assert_equal Money.new(500, 'EUR'), account.available_balance
    assert_equal Money.new(0, 'USD'), Organization.probono.piggy_bank.available_balance
    account.destroy
    assert_equal Money.new(672, 'USD'), Organization.probono.piggy_bank.balance
  end
  

  protected

  def create_user(options = {})
    record = User.create(valid_user_attributes(options))
    record.register! if record.valid?
    record
  end
  
  def valid_user_attributes(options={})
    {
      :login => 'quire', :email => 'quire@example.com', :password => 'quire', :password_confirmation => 'quire',
      :gender => 'm',
      :verification_code => 'want2test',
      :time_zone => 'Berlin',
      :language => 'en',
      :currency => 'USD'
    }.merge(options)
  end
  
  def valid_piggy_bank_account_attributes(options={})
    {:currency => 'EUR'}.merge(options)
  end
  
  def create_piggy_bank_account(options={})
    PiggyBankAccount.create(valid_piggy_bank_account_attributes(options))
  end

  def create_5_euro_account(options={})
    pb = create_piggy_bank_account
    pb.deposit(Money.new(500, 'EUR'), :created_at => Time.now.utc - PiggyBankAccount::COOLING_PERIOD_IN_DAYS.days - 10.day)
    pb
  end

  def create_5_usd_account(options={})
    pb = create_piggy_bank_account(:currency => 'USD')
    pb.deposit(Money.new(500, 'USD'), :created_at => Time.now.utc - PiggyBankAccount::COOLING_PERIOD_IN_DAYS.days - 10.day)
    pb
  end

  def prepare_expired_authorizations
    pb = create_piggy_bank_account
    result = pb.deposit(Money.new(5000, 'EUR'), :created_at => Time.now.utc - 200.days)
    assert_difference PiggyBankAccountTransaction, :count, 5 do
      5.times do |index|
        result = pb.authorize(Money.new(1000, 'EUR'))
        assert result.success?
      end
    end
    pb.transactions.authorized.each_with_index {|t, i| t.update_attributes(
      :created_at => Time.now.utc - 100.days + i.days,
      :expires_at => Time.now.utc - 70.days + i.days
    )}
    assert_equal 5, pb.transactions.authorized.pending.expired.count
    pb
  end
  
  
end
