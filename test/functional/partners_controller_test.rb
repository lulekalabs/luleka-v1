require File.dirname(__FILE__) + '/../test_helper'
require 'partners_controller'

# Re-raise errors caught by the controller.
class PartnersController; def rescue_action(e) raise e end; end

class PartnersControllerTest < Test::Unit::TestCase
  all_fixtures
  
  def setup
    @controller = PartnersController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new

    @request.with_subdomain('us')

    @person = people(:lisa)
    login_as :lisa
  end

  def test_should_route_new
    assert_routing '/user/partner/new', hash_for_path(:new_user_partner)
  end

  def test_should_redirect_on_new
    logout
    get :new
    assert_response :redirect
    assert_redirected_to new_session_path
  end

  def test_should_get_new
    get :new
    assert_response :success
    assert @selected = assigns(:selected)
    assert_equal "CartLineItem", @selected.class.name
    assert_equal "Three-Month Partner Membership", @selected.name
  end

  def test_should_get_new_with_partner_voucher
    assert assign_current_voucher(PartnerMembershipVoucher.create)
    get :new
    assert_response :success
    assert @selected = assigns(:selected)
    assert_equal "PartnerMembershipVoucher", @selected.class.name
  end

  def test_should_post_create_with_membership_selection_and_redirect_to_edit
    post :create, {"partner_membership"=>"SU00101EN-US"}
    assert_response :redirect
    assert @cart = assigns(:cart)
    assert_equal 'SU00101EN-US', @cart.line_items.first.product.sku
    assert @cart = current_cart, 'should have a cart'
    assert_equal "$29.85", @cart.total.format
    assert_redirected_to edit_user_partner_path
  end

  def test_should_create_with_valid_partner_voucher
    voucher = PartnerMembershipVoucher.create(:consignee => people(:lisa))
    voucher.code_confirmation = voucher.code
    post :create, {"partner_membership" => "voucher", "voucher"=>{"code_confirmation_attributes"=>{
      "3s"=> voucher.code_confirmation(3), "2s"=>voucher.code_confirmation(2), "1s"=>voucher.code_confirmation(1)
    }}}
    assert_response :redirect
    assert_redirected_to edit_user_partner_path
    assert current_voucher, 'should have voucher'
    assert @cart = current_cart, 'should have a cart'
    assert @cart.total.zero?, 'cart should have a total of $0'
  end

  def test_should_create_with_non_existing_voucher
    post :create, {"partner_membership"=>"voucher", "voucher"=>{"code_confirmation_attributes"=>{
      "3s"=>'xxxx', "2s"=>'xxxx', "1s"=>'xxxx'
    }}}
    assert_response :success
    assert_template "new"
    assert @voucher = assigns(:voucher), 'should assign a voucher'
    assert !@voucher.valid?, 'should be wrong voucher code'
  end

  def test_should_not_redeem_voucher_as_existing_partner
    login_as :homer
    voucher = PartnerMembershipVoucher.create(:consignee => people(:homer))
    voucher.code_confirmation = voucher.code
    post :create, {"partner_membership"=>"voucher", "voucher"=>{"code_confirmation_attributes"=>{
      "3s"=> voucher.code_confirmation(3), "2s"=>voucher.code_confirmation(2), "1s"=>voucher.code_confirmation(1)
    }}}
    assert_response :success
    assert_template "new"
    assert @voucher = assigns(:voucher)
    assert !@voucher.valid?, 'voucher should not be valid'
    assert_equal "works for new Partners only", @voucher.errors.on(:code)
  end

  def test_should_route_edit
    assert_routing '/user/partner/edit', hash_for_path(:edit_user_partner)
  end

  def test_should_get_edit_without_cart_and_redirect_to_new
    get :edit
    assert_response :redirect
    assert_redirected_to new_user_partner_path
  end
  
  def test_should_get_edit_with_card
    create_and_assign_current_cart_with_membership_for @person
    get :edit
    assert_response :success
    assert @person = assigns(:person)
    assert_equal @person.personal_address.to_s, @person.business_address.to_s, 'should have copied address'
  end

  def test_should_get_edit_as_partner_and_redirect_to_payment
    login_as :homer
    @person = people(:homer)
    create_and_assign_current_cart_with_membership_for @person
    get :edit
    assert_response :redirect
    assert_redirected_to payment_user_partner_path
  end
  
  def test_should_update_save_and_reload
    create_and_assign_current_cart_with_membership_for @person
    put :update, update_person_attributes("_property"=>"save")
    assert @person = assigns(:person)
    assert @person.valid?, 'person should be valid'
    assert_partner_profile @person
    assert_response :redirect
    assert_redirected_to edit_user_partner_path
  end
  
  def test_should_update_and_redirect_to_payment
    create_and_assign_current_cart_with_membership_for @person
    put :update, update_person_attributes
    assert @person = assigns(:person)
    assert @person.valid?, 'person should be valid'
    assert_partner_profile @person
    assert_response :redirect
    assert_redirected_to payment_user_partner_path
  end
  
  def test_should_update_not_validate_and_reload
    create_and_assign_current_cart_with_membership_for @person
    put :update, update_person_attributes("person" => {})
    assert @person = assigns(:person)
    assert !@person.valid?, 'person should not be valid'
    assert_response :success
  end

  def test_should_route_payment
    assert_routing '/user/partner/payment', hash_for_path(:payment_user_partner)
  end

  def test_should_get_payment
    @person = create_person_profile(@person)
    create_and_assign_current_cart_with_membership_for @person
    get :payment
    assert_response :success
    assert @person = assigns(:person)
    assert @person.billing_address, "should have a billing address"
    assert_equal "Lisa Simpson, Moltkestraße 83, Reutlingen, BW, 72762, Germany", @person.billing_address.to_s
  end

  def test_update_payment_and_redirect_to_complete
    @person = create_person_profile(@person)
    create_and_assign_current_cart_with_membership_for @person
    put :update, update_payment_attributes(true, "_property"=>"pay")
    assert @person = assigns(:person)
    assert @payment_object = assigns(:payment_object)
    assert @order = assigns(:order)
    assert current_order, 'order should be in session'
    assert @payment = assigns(:payment)
    assert_equal "Lisa Simpson, Schmeizlerstr. 45, Blaufelden, BW, 74572, Germany", @person.billing_address.to_s
    assert_equal "DE", @person.billing_address.country_code
    assert_response :redirect
    assert_redirected_to complete_user_partner_path
  end

  def test_update_payment_with_invalid_payment_and_reload
    @person = create_person_profile(@person)
    create_and_assign_current_cart_with_membership_for @person
    put :update, update_payment_attributes(false, "_property"=>"pay")
    assert @person = assigns(:person)
    assert @payment_object = assigns(:payment_object)
    assert_response :success
  end

  def test_update_payment_without_cart_and_redirect_to_new
    put :update
    assert_response :redirect
    assert_redirected_to new_user_partner_path
  end

  def test_should_route_complete
    assert_routing '/user/partner/complete', hash_for_path(:complete_user_partner)
  end

  def test_should_get_complete_without_order_and_redirect_to_new
    get :complete
    assert_response :redirect
    assert_redirected_to new_user_partner_path
  end
  
  def test_should_get_complete
    create_and_assign_current_cart_with_membership_for(@person)
    @person.piggy_bank.direct_deposit(Money.new(10000, 'USD'))
    @order, @payment = @person.purchase_and_pay(current_cart, @person.piggy_bank)
    assert @payment.success?
    assign_current_order(@order)
    get :complete
    assert_response :success
    assert current_order, "current order should be remove through after_filter"
  end
    
  protected

  def create_and_assign_current_cart_with_membership_for(person)
    unless person.is_a?(Person)
      person = people(person)
    end
    @cart = person.cart
    @cart.add topics(:three_month_partner_membership_en)
    assign_current_cart(@cart)
  end
  
  def update_person_attributes(options={})
{"person"=>{"industry"=>"Fahrzeugtechnik", "profile"=>"Lisa ist eine Autoexpertin, spezialisiert in der Restauration von VW Käfern.", "personal_status_id"=>"#{PersonalStatus.find(:first).id}", "university"=>"University of Life", "academic_degree"=>"Mechaniker Meister", "professional_title"=>"Meister", "have_expertise"=>"automotoren, käfer, vw käfer, 4-zylinder", "business_address_attributes"=>{"city"=>"Reutlingen", "country_code"=>"DE", "postal_code"=>"72762", "mobile"=>"+49 (0)172/323 523 5", "province_code"=>"BW", "fax"=>"+49 (0)172/342 323 65", "phone"=>"+49 (0)7121/342 323 64", "street"=>"Moltkestraße 83"}, "tax_code"=>"000-00-0000", "profession"=>"Mechaniker"}}.merge(options)
  end
  
  def assert_partner_profile(person)
    assert_equal "Moltkestraße 83, Reutlingen, BW, 72762, Germany", person.business_address.to_s
    assert_equal "Fahrzeugtechnik", person.industry
    assert_equal "Lisa ist eine Autoexpertin, spezialisiert in der Restauration von VW Käfern.", person.profile
    assert_equal "Entrepreneur", person.personal_status.name
    assert_equal "University of Life", person.university
    assert_equal "Mechaniker Meister", person.academic_degree
    assert_equal "Meister", person.professional_title
    assert_equal "automotoren, käfer, vw käfer, 4-zylinder", person.have_expertise
    assert_equal "000-00-0000", person.tax_code
    assert_equal "Mechaniker", person.profession
  end

  def create_person_profile(person)
    person.attributes = update_person_attributes["person"]
    person.save
    person.business_address.save
    person
  end

  def update_payment_attributes(valid = true, options={})
    {
      "bogus"=>{"month"=>"5", "number"=>"#{valid ? '1' : '2'}", "verification_value"=>"123", "year"=>"2011", "first_name"=>"Herbert", "last_name"=>"Wenke"}, "payment_method"=>"bogus", "visa"=>{"month"=>"3", "number"=>"", "verification_value"=>"", "year"=>"2009", "first_name"=>"Herbert", "last_name"=>"Wenke"}, 
      "person"=>{"billing_address_attributes"=>{"city"=>"Blaufelden", "postal_code"=>"74572", "company_name"=>"Schmitthammer & Co.", "academic_title_id"=>"0", "gender"=>"f", "province_code"=>"BW", "street"=>"Schmeizlerstr. 45", "first_name"=>"Lisa", "last_name"=>"Simpson", "middle_name"=>""}}
    }.merge(options)
  end
  
end
