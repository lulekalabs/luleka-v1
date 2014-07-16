require File.dirname(__FILE__) + '/../test_helper'

class PiggyBankPaymentTest < ActiveSupport::TestCase
  fixtures :exchange_rates, :users, :people

  def setup
    @pb = create_5_euro_account
    @amount = Money.new(100, 'EUR')
  end

  def test_should_authorize
    auth = PiggyBankPayment.authorize(
      @amount,
      @pb
    )
    assert_equal true, auth.success
    assert_equal 'authorization', auth.action
    @transaction = @pb.transactions.find_by_action('authorize')
    assert_equal auth.reference, @transaction.authorization
    assert '5.00', @pb.balance.to_s
    assert '4.00', @pb.available_balance.to_s
  end

  def test_should_not_authorize
    auth = PiggyBankPayment.authorize(
      Money.new(501, 'EUR'),
      @pb
    )
    assert_equal false, auth.success
    assert_equal 'authorization', auth.action
    assert_nil auth.reference
    assert '5.00', @pb.balance.to_s
    assert '5.00', @pb.available_balance.to_s
  end

  def test_should_capture
    auth = authorize(@amount, @pb)
    assert auth.reference
    authorization = auth.reference

    assert '5.00', @pb.balance.to_s
    assert '4.00', @pb.available_balance.to_s
    
    result = PiggyBankPayment.capture(@amount, authorization, {:buyer => @pb.owner})
    
    assert_equal true, result.success
    assert_equal 'capture', result.action
    assert_equal result.reference, authorization
    assert '4.00', @pb.balance.to_s
    assert '4.00', @pb.available_balance.to_s
  end

  def test_should_not_capture
    auth = authorize(@amount, @pb)
    assert auth.reference
    authorization = auth.reference

    assert '5.00', @pb.balance.to_s
    assert '4.00', @pb.available_balance.to_s
    
    result = PiggyBankPayment.capture(Money.new(101, 'EUR'), authorization, {:buyer => @pb.owner})
    assert_equal false, result.success
    assert_equal 'capture', result.action
    assert_nil result.reference
    assert '5.00', @pb.balance.to_s
    assert '4.00', @pb.available_balance.to_s
  end
  
  def test_should_purchase
    payment = PiggyBankPayment.purchase(
      @amount,
      @pb,
      :payable => people(:homer)  # usually this is an invoice
    )
    assert_equal true, payment.success
    assert_equal 'purchase', payment.action
    assert @transaction = @pb.transactions.find_by_action('purchase')
    assert_equal people(:homer), @transaction.context
    assert '4.00', @pb.balance.to_s
    assert '4.00', @pb.available_balance.to_s
  end

  def test_should_void
    auth = authorize(@amount, @pb)
    assert auth.reference
    authorization = auth.reference

    assert '5.00', @pb.balance.to_s
    assert '4.00', @pb.available_balance.to_s
    
    result = PiggyBankPayment.void(@amount, authorization, {:buyer => @pb.owner})
    
    assert_equal true, result.success
    assert_equal 'void', result.action
    assert_equal result.reference, authorization
    assert '5.00', @pb.balance.to_s
    assert '5.00', @pb.available_balance.to_s
  end

  def test_should_credit
    auth = authorize(@amount, @pb)
    assert auth.success?
    assert auth.reference
    authorization = auth.reference
    assert '5.00', @pb.balance.to_s
    assert '4.00', @pb.available_balance.to_s

    payment = PiggyBankPayment.capture(@amount, authorization, {:buyer => @pb.owner})
    assert payment.success?
    assert '4.00', @pb.balance.to_s
    assert '4.00', @pb.available_balance.to_s
    
    result = PiggyBankPayment.credit(Money.new(50, 'EUR'), authorization, {:buyer => @pb.owner})
    assert_equal true, result.success?
    assert_equal 'credit', result.action
    assert_equal result.reference, authorization
    assert '4.50', @pb.balance.to_s
    assert '4.50', @pb.available_balance.to_s
  end

  def test_should_not_credit
    auth = authorize(@amount, @pb)
    assert auth.success?
    assert auth.reference
    authorization = auth.reference
    assert '5.00', @pb.balance.to_s
    assert '4.00', @pb.available_balance.to_s

    payment = PiggyBankPayment.capture(@amount, authorization, {:buyer => @pb.owner})
    assert payment.success?
    assert '4.00', @pb.balance.to_s
    assert '4.00', @pb.available_balance.to_s
    
    result = PiggyBankPayment.credit(Money.new(600, 'EUR'), authorization, {:buyer => @pb.owner})
    assert_equal false, result.success?
    assert '4.00', @pb.balance.to_s
    assert '4.00', @pb.available_balance.to_s
  end

  def test_should_transfer
    transfer = PiggyBankPayment.transfer(
      @amount,
      @pb
    )
    assert_equal true, transfer.success
    assert_equal 'transfer', transfer.action
    assert '6.00', @pb.balance.to_s
    assert '5.00', @pb.available_balance.to_s
  end

  protected

  def authorize(amount, account)
    PiggyBankPayment.authorize(
      amount,
      account
    )
  end

  def create_5_euro_account(options={})
    u = create_user(valid_random_user_attributes(options))
    assert u.valid?
    pb = u.person.piggy_bank
    assert u.person.valid?
    pb.deposit(Money.new(500, 'EUR') - u.person.piggy_bank.available_balance, 
      :created_at => Time.now.utc - PiggyBankAccount::COOLING_PERIOD_IN_DAYS.days - 10.day)
    pb
  end
  
  def valid_random_user_attributes(options={})
    name = [Array.new(12){(rand(25) + 65).chr}.join].pack("m").chomp
    {
      :login => name, :email => "#{name}@example.com", :password => name, :password_confirmation => name,
      :gender => 'm',
      :time_zone => 'Berlin',
      :language => 'en',
      :currency => 'EUR'
    }.merge(options)
  end
  
end
