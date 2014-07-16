require File.dirname(__FILE__) + '/../test_helper'

class PaymentMethodTest < ActiveSupport::TestCase
  fixtures :people, :users

  def test_should_initialize
    pm = PaymentMethod.new :visa
    assert_equal :visa, pm.type
    assert_equal :visa, pm.kind
    assert_equal 'visa', pm.active_merchant_type
    assert_equal '1234 5678 9012 3456', pm.help_example
    assert_equal '/images/icons/payment-methods/visa.png', pm.image
    assert_equal '/images/icons/payment-methods/cvv_visa.png', pm.help_image
    assert_equal "Visa", pm.caption
    assert_equal "Visa", pm.type_s
    assert_equal ActiveMerchant::Billing::CreditCard, pm.klass
    assert_equal 'shared/credit_card_entry', pm.partial
  end
  
  def test_should_build_visa_card_instance
    visa_card = PaymentMethod.build :visa, valid_credit_card_attributes(
      :type => "visa",
      :number => "4381258770269608"
    )
    assert visa_card.is_a?(ActiveMerchant::Billing::CreditCard)
    assert visa_card.valid?, "#{visa_card.errors.full_messages.to_sentence}"
  end
  
  def test_should_build_piggy_bank_instance
    piggy_bank = PaymentMethod.build :piggy_bank
    assert piggy_bank.is_a?(PiggyBankAccount)
  end

  def test_should_build_get_piggy_bank_instance_from_current_user
    User.current_user = users(:lisa)
    piggy_bank = PaymentMethod.build :piggy_bank
    assert piggy_bank.is_a?(PiggyBankAccount)
    assert_equal people(:lisa), piggy_bank.owner
  end

  def test_should_return_all_types
    assert_equal 6, PaymentMethod.types.size
    [:visa, :mastercard, :amex, :piggy_bank, :discover, :bogus].each do |t|
      assert PaymentMethod.types.include?(t)
    end
  end

  def test_should_return_all_active_merchant_types
    assert_equal 5, PaymentMethod.active_merchant_types.size
    ['master', 'visa', 'american_express', 'discover', 'bogus'].each do |t|
      assert PaymentMethod.active_merchant_types.include?(t)
    end
  end

  def test_should_return_types_with_only
    assert_equal 2, PaymentMethod.types(:only => [:visa, :piggy_bank]).size
    [:visa, :piggy_bank].each do |t|
      assert PaymentMethod.types(:only => [:visa, :piggy_bank]).include?(t)
    end
  end

  def test_should_return_types_without_except
    assert_equal 5, PaymentMethod.types(:except => [:discover]).size
    [:visa, :mastercard, :amex, :piggy_bank].each do |t|
      assert PaymentMethod.types(:except => :discover).include?(t)
    end
  end

  def test_should_return_all_objects
    assert_equal 6, PaymentMethod.objects.size
    PaymentMethod.objects.each do |o|
      assert [:visa, :mastercard, :amex, :piggy_bank, :discover, :bogus].include?(o.type)
    end
  end

  def test_should_return_objects_with_only
    assert_equal 1, PaymentMethod.objects(:only => :piggy_bank).size
    PaymentMethod.objects(:only => :piggy_bank).each do |o|
      assert [:piggy_bank].include?(o.type)
    end
  end

  def test_should_return_objects_without_except
    assert_equal 5, PaymentMethod.objects(:except => :piggy_bank).size
    PaymentMethod.objects(:except => :piggy_bank).each do |o|
      assert [:visa, :mastercard, :amex, :discover, :bogus].include?(o.type)
    end
  end

  def test_should_return_klass
    assert_equal ActiveMerchant::Billing::CreditCard, PaymentMethod.klass(:visa)
  end

  def test_should_not_return_klass
    assert_nil PaymentMethod.klass(:sepp)
  end

  def test_should_normalize_type
    assert_equal :piggy_bank, PaymentMethod.normalize_type('piggy_bank')
    assert_equal :piggy_bank, PaymentMethod.normalize_type(:piggy_bank)
    assert_equal :amex, PaymentMethod.normalize_type('american_express')
    assert_equal :amex, PaymentMethod.normalize_type(:american_express)
    assert_equal :amex, PaymentMethod.normalize_type(:amex)
    assert_equal :visa, PaymentMethod.normalize_type('visa')
    assert_equal :visa, PaymentMethod.normalize_type(:visa)
  end

  def test_should_not_normalize_type
    assert_nil PaymentMethod.normalize_type('sepp')
    assert_nil PaymentMethod.normalize_type(:sepp)
    assert_nil PaymentMethod.normalize_type(nil)
    assert_nil PaymentMethod.normalize_type(NilClass)
    assert_nil PaymentMethod.normalize_type(String)
  end
  
  def test_should_get_partial
    assert_equal 'shared/credit_card_entry', PaymentMethod.partial(:visa)
  end

  def test_should_get_help_image
    assert_equal '/images/icons/payment-methods/cvv_visa.png', PaymentMethod.help_image(:visa)
  end

  def test_should_get_help_example
    assert_equal '1234 5678 9012 3456', PaymentMethod.help_example(:visa)
  end

  def test_should_get_image
    assert_equal '/images/icons/payment-methods/visa.png', PaymentMethod.image(:visa)
  end

  def test_should_get_caption
    assert_equal 'Visa', PaymentMethod.caption(:visa)
    assert_equal 'Visa', PaymentMethod.type_s(:visa)
  end

  def test_should_be_credit_card
    assert PaymentMethod.credit_card?(:visa)
    assert PaymentMethod.credit_card?(PaymentMethod.build(:visa))
    assert PaymentMethod.credit_card?(:mastercard)
    assert PaymentMethod.credit_card?(PaymentMethod.build(:mastercard))
    assert PaymentMethod.credit_card?(:amex)
    assert PaymentMethod.credit_card?(PaymentMethod.build(:amex))
    assert PaymentMethod.credit_card?(:discover)
    assert PaymentMethod.credit_card?(PaymentMethod.build(:discover))
  end

  def test_should_not_be_credit_card
    assert !PaymentMethod.credit_card?(:piggy_bank)
    assert !PaymentMethod.credit_card?("")
  end

  def test_should_be_piggy_bank
    assert PaymentMethod.piggy_bank?(:piggy_bank)
    assert PaymentMethod.piggy_bank?(PaymentMethod.build(:piggy_bank))
  end

  def test_should_not_be_piggy_bank
    assert !PaymentMethod.piggy_bank?(:visa)
    assert !PaymentMethod.piggy_bank?(PaymentMethod.build(:visa))
  end
  
  protected
  
  
end
