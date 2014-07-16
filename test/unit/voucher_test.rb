require File.dirname(__FILE__) + '/../test_helper'

class VoucherTest < ActiveSupport::TestCase
  fixtures :vouchers, :users, :people, :topics

  def setup
  end

  def test_should_create_simple_voucher
    voucher = create_voucher
    assert voucher.valid?
    assert_equal people(:homer), voucher.consignor
    assert_equal people(:barney), voucher.consignee
    assert_equal PartnerMembershipVoucher::PROMOTABLE_SKU, voucher.promotable_sku
    assert /[a-z]{4}-[a-z]{4}-[a-z]{4}/i.match(voucher.code)
    assert_equal false, voucher.expired?
  end
  
  def test_should_generate_and_redeem_vouchers
    vouchers = Voucher.generate(5,
      :expires_at => Time.now.utc + 1.day,
      :type => :partner_membership
    )
    assert_equal 5, vouchers.size
    assert_equal 1, vouchers.first.batch
    assert_equal false, vouchers.first.expired?
    vouchers.each do |voucher|
      user = create_user(:login => voucher.undasherized_code, :email => "#{voucher.undasherized_code}@test.tt")
      user.person.create_billing_address(valid_address_attributes)
      assert Voucher.redeem_by_code(voucher, user), 'could not be redemped'
    end
  end

  def test_should_generate_partner_membership_vouchers
    vouchers = Voucher.generate(5,
      :expires_at => Time.now.utc + 1.day,
      :type => :partner_membership)
    assert_equal 5, vouchers.size
    assert_equal 1, vouchers.first.batch
    assert_equal false, vouchers.first.expired?
    vouchers.each do |voucher|
      assert voucher.is_a?(PartnerMembershipVoucher)
      assert_equal 'SU00101', voucher.promotable_sku
    end
  end

  # for_business_cards
  def test_should_generate_partner_membership_vouchers_for_business_cards
    vouchers = Voucher.for_business_cards(5)
    assert_equal 5, vouchers.size
    assert_equal 1, vouchers.first.batch
    assert_equal false, vouchers.first.expired?
    vouchers.each do |voucher|
      assert voucher.is_a?(PartnerMembershipVoucher)
      assert_equal 'SU00101', voucher.promotable_sku
    end
  end
  
  def test_should_be_expired?
    voucher = create_voucher(:expires_at => Time.now.utc - 1.hour)
    assert_equal true, voucher.expired?
    assert_equal false, voucher.valid?
  end
  
  def test_should_validate_expires
    voucher = create_voucher
    voucher.update_attribute(:expires_at, Time.now.utc - 1.hour)
    voucher = Voucher.find_by_id(voucher.id)
    assert !voucher.valid?
    assert voucher.errors.invalid?(:code)
    assert_equal 'has already expired', voucher.errors.on(:code)
  end
  
  def test_should_be_redeemed?
    voucher = create_voucher(:redeemed_at => Time.now.utc)
    assert true, voucher.redeemed?
    assert_equal false, voucher.valid?
  end

  def test_should_validate_redeemed
    voucher = create_voucher
    voucher.update_attribute(:redeemed_at, Time.now.utc - 1.hour)
    voucher = Voucher.find_by_id(voucher.id)
    assert !voucher.valid?
    assert voucher.errors.invalid?(:code)
    assert_equal 'has already been redeemed', voucher.errors.on(:code)
  end
  
  def test_redeem_with_valid_consignee_and_order_and_invoice
    user = create_user
    user.person.create_billing_address(valid_address_attributes)
    assert user.person.activate!
    voucher = create_voucher(:consignee => user.person)
    assert_equal false, voucher.consignee.partner?, 'should not be partner yet'
    assert_difference Order, :count do
      assert_difference Invoice, :count do
        assert_nil voucher.promotable
        assert voucher.redeem!(true)
        assert voucher.promotable
        assert_equal "-29.85", voucher.price.to_s
      end
    end
    assert Order.find(:all, :order => "created_at DESC").first.total.zero?
    assert_equal true, voucher.redeemed?
    assert_equal true, voucher.consignee.partner?, 'not converted into partner'
  end
  
  def test_should_not_redeem_partner_membership_with_invalid_consignee_as_partner
    voucher = create_voucher(:consignee => people(:homer))
    assert_equal true, voucher.consignee.partner?, 'homer is partner'
    assert !voucher.redeem!
    assert_equal false, voucher.redeemed?
    assert_equal true, voucher.consignee.partner?
  end

  def test_should_redeem_with_voucher_code
    voucher = create_voucher
    assert voucher.valid?
    assert_equal false, voucher.consignee.partner?, 'should not be partner yet'
    assert_difference Order, :count do
      assert_difference Invoice, :count do
        voucher = Voucher.redeem_by_code(voucher.code)
      end
    end
    assert_equal true, voucher.redeemed?
    assert_equal true, voucher.consignee.partner?, 'not converted into partner'
  end

  def test_should_not_redeem_with_invalid_voucher_code
    assert_nil Voucher.redeem_by_code('abcd-efgh-ijkl')
    assert_nil Voucher.redeem_by_code('abcd-efgh-ijkl', users(:bart))
  end

  def test_should_not_redeem_with_voucher_assigned_to_other_consignee
    barney_voucher = create_voucher(:consignee => people(:barney))
    bart_voucher = create_voucher(:consignee => people(:bart))
    assert_nil Voucher.redeem_by_code(barney_voucher.code, users(:bart))
  end
  
  def test_should_get_code_with_to_s
    voucher = create_voucher(:consignee => people(:barney))
    assert_equal voucher.code, voucher.to_s
  end

  def test_should_undasherize_code
    assert_equal 'abcdefghijkl', Voucher.undasherize_code('abcd-efgh-ijkl')
  end

  def test_should_dasherize_code
    assert_equal 'abcd-efgh-ijkl', Voucher.dasherize_code('abcdefghijkl')
    assert_equal 'abcd-efgh-ijkl', Voucher.dasherize_code('abcd-efgh-ijkl')
  end

  def test_should_obfuscate_code
    assert_equal 'abcdefgh****', Voucher.obfuscate_code('abcd-efgh-ijkl')
    assert_equal 'abcd-efgh-****', Voucher.dasherize_code(Voucher.obfuscate_code('abcd-efgh-ijkl'))
  end

  def test_should_be_anonymous?
    voucher = Voucher.new
    assert voucher.anonymous?
  end

  def test_should_not_be_consignee?
    voucher = Voucher.new
    assert !voucher.consignee?
  end

  def test_should_parameterize_code_confirmation_attributes
    voucher = Voucher.new(:code_confirmation_attributes => {'1s' => 'abcd', '2s' => 'efgh', '3s' => 'ijkl'})
    assert_equal 'abcd-efgh-ijkl', voucher.code_confirmation
    assert_equal 'abcd', voucher.code_confirmation(1)
    assert_equal 'efgh', voucher.code_confirmation(2)
    assert_equal 'ijkl', voucher.code_confirmation(3)

    voucher = Voucher.new(:code_confirmation => 'abcd-efgh-ijkl')
    assert_equal 'abcd-efgh-ijkl', voucher.code_confirmation
    assert_equal 'abcd', voucher.code_confirmation(1)
    assert_equal 'efgh', voucher.code_confirmation(2)
    assert_equal 'ijkl', voucher.code_confirmation(3)
  end

  def test_should_not_parameterize_code_confirmation_attributes
    voucher = Voucher.new(:code_confirmation_attributes => {})
    assert_nil voucher.code_confirmation
    assert_nil voucher.code_confirmation(1)
    assert_nil voucher.code_confirmation(2)
    assert_nil voucher.code_confirmation(3)
    assert_nil voucher.code_confirmation(4)
    
    voucher = Voucher.new(:code_confirmation_attributes => '')
    assert_nil voucher.code_confirmation
  end

  def test_should_validate_consignee_confirmation
    voucher = create_voucher
    voucher.consignee_confirmation = voucher.consignee
    assert voucher.valid?
  end

  def test_should_not_validate_consignee_confirmation
    voucher = create_voucher
    voucher.consignee_confirmation = create_person
    assert !voucher.valid?
    assert voucher.errors.on(:consignee_confirmation)
  end

  def test_should_consignee_and_save
    voucher = create_voucher
    assert_equal people(:barney), voucher.consignee
    voucher.consignee_and_save = people(:bart)
    voucher = Voucher.find_by_id(voucher.id)
    assert_equal people(:bart), voucher.consignee
  end

  def test_should_get_promotable_product
    voucher = create_voucher
    assert_equal topics(:three_month_partner_membership_en), voucher.promotable_product
    # caches the product in an instance variable, but not sure how to test?
    assert_equal topics(:three_month_partner_membership_en), voucher.promotable_product
  end

  def test_should_find_by_code_confirmation_attributes
    voucher = create_voucher
    assert voucher.valid?
    voucher.code_confirmation = voucher.code
    assert_equal voucher.code, voucher.code_confirmation
    
    voucher_to_redeem = Voucher.find_by_code_confirmation_attributes(
      {:code_confirmation_attributes => {
        '1s' => voucher.code_confirmation(1),
        '2s' => voucher.code_confirmation(2),
        '3s' => voucher.code_confirmation(3)
      }}, voucher.consignee)
      
    assert voucher_to_redeem
    assert voucher_to_redeem.valid?
  end

  def test_code_confirmation_should_not_be_nil_with_partial_code
    voucher = Voucher.new(
      {:code_confirmation_attributes => {
        '1s' => 'abcd',
        '2s' => '',
        '3s' => ''
      }})
    assert voucher.code_confirmation
    assert_equal 'abcd', voucher.code_confirmation(1)
    assert_equal '', voucher.code_confirmation(2)
    assert_equal '', voucher.code_confirmation(3)
    
    voucher = Voucher.new(
      {:code_confirmation_attributes => {
        '1s' => '',
        '2s' => 'efgh',
        '3s' => ''
      }})
    assert voucher.code_confirmation
    assert_equal '', voucher.code_confirmation(1)
    assert_equal 'efgh', voucher.code_confirmation(2)
    assert_equal '', voucher.code_confirmation(3)

    voucher = Voucher.new(
      {:code_confirmation_attributes => {
        '1s' => '',
        '2s' => '',
        '3s' => 'ijkl'
      }})
    assert voucher.code_confirmation
    assert_equal '', voucher.code_confirmation(1)
    assert_equal '', voucher.code_confirmation(2)
    assert_equal 'ijkl', voucher.code_confirmation(3)
  end

  def test_code_confirmation_should_be_nil_with_empty_attributes
    voucher = Voucher.new(
      {:code_confirmation_attributes => {
        '1s' => '',
        '2s' => '',
        '3s' => ''
      }})
    assert_nil voucher.code_confirmation
    
    voucher = Voucher.new({})
    assert_nil voucher.code_confirmation
  end

  def test_should_not_find_by_code_confirmation_attributes_wrong_code
    voucher = create_voucher
    assert voucher.valid?
    voucher.code_confirmation = voucher.code
    assert_equal voucher.code, voucher.code_confirmation
    
    voucher_to_redeem = Voucher.find_by_code_confirmation_attributes(
      {:code_confirmation_attributes => {
        '1s' => voucher.code_confirmation(1),
        '2s' => voucher.code_confirmation(2),
        '3s' => 'xxxx'
      }}, voucher.consignee)
    assert_nil voucher_to_redeem
  end

  def test_should_not_find_by_code_confirmation_attributes_wrong_consignee
    voucher = create_voucher
    assert voucher.valid?
    voucher.code_confirmation = voucher.code
    assert_equal voucher.code, voucher.code_confirmation
    
    voucher_to_redeem = Voucher.find_by_code_confirmation_attributes(
      {:code_confirmation_attributes => {
        '1s' => voucher.code_confirmation(1),
        '2s' => voucher.code_confirmation(2),
        '3s' => voucher.code_confirmation(3)
      }}, people(:aaron))
    assert voucher_to_redeem
    assert_equal PartnerMembershipVoucher, voucher_to_redeem.class
    assert !voucher_to_redeem.valid?
    assert voucher_to_redeem.errors.invalid?(:consignee_confirmation)
  end
  
  def test_should_build_partner_membership_voucher
    voucher = PartnerMembershipVoucher.new({
      :consignor => people(:homer),
      :consignee => people(:barney),
      :email => people(:homer).email,
      :expires_at => Time.now.utc + 3.months
    })
    assert voucher.is_a?(PartnerMembershipVoucher)
    assert_equal 'SU00101', voucher.promotable_sku
    assert voucher.valid?
    assert voucher.save
    voucher = Voucher.find_by_id(voucher.id)
    assert voucher.is_a?(PartnerMembershipVoucher)
    assert_equal 'SU00101', voucher.promotable_sku
  end

  def test_should_build_voucher_by_type
    voucher = Voucher.new :type => :partner_membership
    assert_equal 'PartnerMembershipVoucher', voucher.class.name

    voucher = Voucher.new :type => 'PartnerMembershipVoucher'
    assert_equal 'PartnerMembershipVoucher', voucher.class.name

    voucher = Voucher.new :type => PartnerMembershipVoucher
    assert_equal 'PartnerMembershipVoucher', voucher.class.name
  end

  def test_should_create_voucher_by_type
    voucher = Voucher.create :type => :partner_membership
    assert voucher.valid?
    assert voucher.code
    assert_equal PartnerMembershipVoucher, voucher.class
  end
  
  def test_should_describe
    voucher = PartnerMembershipVoucher.create({
      :consignor => people(:homer),
      :consignee => people(:barney),
      :email => people(:homer).email,
      :expires_at => Time.now.utc + 3.months
    })
    assert_equal "Partner Membership Voucher from Homer Simpson for Three Month Partner Membership (%{obfuscated_code})" % {:obfuscated_code => voucher.obfuscated_code}, voucher.description
  end

  def test_should_find_promotable_product_cache_with_locale
    voucher = PartnerMembershipVoucher.generate(1)
    voucher = voucher.first
    assert_equal PartnerMembershipVoucher, voucher.class
    assert_equal topics(:three_month_partner_membership_en), voucher.promotable_product('en-US')
    assert_equal topics(:three_month_partner_membership_de), voucher.promotable_product('de-DE')
    assert_equal topics(:three_month_partner_membership_en), voucher.promotable_product('en-US')
  end

  def test_should_promotable_product_cache_with_consignee
    voucher = PartnerMembershipVoucher.generate(1, :consignee => people(:barney))
    voucher = voucher.first
    assert_equal PartnerMembershipVoucher, voucher.class
    assert_equal topics(:three_month_partner_membership_en), voucher.promotable_product
    assert_equal topics(:three_month_partner_membership_de), voucher.promotable_product('de-DE')
    assert_equal topics(:three_month_partner_membership_en), voucher.promotable_product
  end

  def test_should_not_find_promotable_product_cache_with_locale
    voucher = PartnerMembershipVoucher.generate(1)
    voucher = voucher.first
    assert_equal PartnerMembershipVoucher, voucher.class
    assert_nil voucher.promotable_product('ru-RU')
  end
  
  def test_should_not_validate_with_empty_code
    voucher = PartnerMembershipVoucher.new(:validate_code_confirmation => true)
    assert !voucher.valid?, 'empty code is invalid'
    assert voucher.errors.on(:code_confirmation), 'confirmation code is empty'
  end

  def test_should_not_validate_for_existing_partner_with_consignee
    partner = people(:homer)
    assert partner.partner?
    voucher = PartnerMembershipVoucher.create(:consignee => partner)
    assert !voucher.valid?
#    assert_equal 'works for new Partners only', voucher.errors.on(:code)
  end

  def test_should_not_validate_for_existing_partner_without_consignee
    partner = people(:homer)
    assert partner.partner?
    voucher = PartnerMembershipVoucher.create(:consignee_confirmation => partner)
    assert !voucher.valid?
#    assert_equal 'works for new Partners only', voucher.errors.on(:code)
  end

  def xtest_should_find_promotable_product_with_weird_locale
    user = create_user(:language => 'de')
    assert_equal 'de-US', user.person.default_locale
    voucher = PartnerMembershipVoucher.create(:consignee => user.person)
    assert voucher.valid?
    assert_equal topics(:three_month_partner_membership_en), voucher.promotable_product
    line_item = user.person.cart.cart_line_item(voucher)
#    assert_equal 'Gutschein für eine Partner Mitgliedschaft'.titleize, line_item.name
  end
  
end
