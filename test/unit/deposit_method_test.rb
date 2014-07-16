require File.dirname(__FILE__) + '/../test_helper'

class DepositMethodTest < ActiveSupport::TestCase
  all_fixtures

  def test_should_initialize
    pm = DepositMethod.new :paypal
    assert_equal :paypal, pm.type
    assert_nil pm.active_merchant_type
    assert_equal 'john@smith.com', pm.help_example
    assert_equal '/images/icons/payment-methods/paypal.png', pm.image
    assert_nil pm.help_image
    assert_equal "Paypal", pm.caption
    assert_equal PaypalDepositAccount, pm.klass
    assert_equal 'shared/paypal_entry', pm.partial
    
    assert_equal 50, pm.transaction_fee_cents
    assert_equal 100, pm.min_transfer_amount_cents
    assert_equal 10000, pm.max_transfer_amount_cents
  end

  def test_should_return_klass
    assert_equal PaypalDepositAccount, DepositMethod.klass(:paypal)
  end

  def test_should_not_return_klass
    assert_nil DepositMethod.klass(:bogus)
  end
  
  def test_should_build_deposit_account_instance
    account = DepositMethod.build :paypal, {:person => people(:homer), :paypal_account => 'adam@smith.tst'}
    assert account.is_a?(DepositAccount)
    assert account.valid?
  end

  def test_should_return_all_types
    assert_equal 1, DepositMethod.types.size
    [:paypal].each do |t|
      assert DepositMethod.types.include?(t)
    end
  end

  def test_should_return_types_with_only
    assert_equal 1, DepositMethod.types(:only => :paypal).size
    [:paypal].each do |t|
      assert DepositMethod.types(:only => :paypal).include?(t)
    end
  end

  def test_should_return_all_factory_objects
    assert_equal 1, DepositMethod.objects.size
    DepositMethod.objects.each do |o|
      assert [:paypal].include?(o.type)
    end
  end

  def test_should_get_partial
    assert_equal 'shared/paypal_entry', DepositMethod.partial(:paypal)
  end

  def test_should_get_help_image
    assert_nil DepositMethod.help_image(:paypal)
  end

  def test_should_get_help_example
    assert_equal 'john@smith.com', DepositMethod.help_example(:paypal)
  end

  def test_should_get_image
    assert_equal '/images/icons/payment-methods/paypal.png', DepositMethod.image(:paypal)
  end

  def test_should_get_caption
    assert_equal 'Paypal', DepositMethod.caption(:paypal)
    assert_equal 'Paypal', DepositMethod.type_s(:paypal)
  end

  def test_should_get_transaction_fee_cents
    assert_equal 50, DepositMethod.transaction_fee_cents(:paypal)
    assert_equal 50, DepositMethod.new(:paypal).transaction_fee_cents
  end

  def test_should_get_min_transfer_amount_cents 
    assert_equal 100, DepositMethod.min_transfer_amount_cents
    assert_equal 100, DepositMethod.min_transfer_amount_cents(:paypal)
    assert_equal 100, DepositMethod.min_transfer_amount_cents(:bogus)
    assert_equal 100, DepositMethod.new(:paypal).min_transfer_amount_cents
  end

  def test_should_get_max_transfer_amount_cents 
    assert_equal 10000, DepositMethod.max_transfer_amount_cents
    assert_equal 10000, DepositMethod.max_transfer_amount_cents(:paypal)
    assert_equal 10000, DepositMethod.max_transfer_amount_cents(:bogus)
    assert_equal 10000, DepositMethod.new(:paypal).max_transfer_amount_cents
  end
  
end
