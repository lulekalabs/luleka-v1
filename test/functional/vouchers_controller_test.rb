require File.dirname(__FILE__) + '/../test_helper'
require 'vouchers_controller'

# Re-raise errors caught by the controller.
class VouchersController; def rescue_action(e) raise e end; end

class VouchersControllerTest < Test::Unit::TestCase
  all_fixtures
  
  def setup
    @controller = VouchersController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
    
    @request.with_subdomain('us')
    
    logout
  end

  def test_should_route_show
    assert_routing '/voucher', hash_for_path(:voucher)
  end

  def test_should_route_complete
    assert_routing '/voucher/complete', hash_for_path(:complete_voucher)
  end

  # Replace this with your real tests.
  def test_should_get_show_without_user
    get :show
    assert_response :success
  end

  # Replace this with your real tests.
  def test_should_get_show_with_authenticated_user
    login_as :lisa
    get :show
    assert_response :success
  end
  
  def test_should_create_without_voucher
    post :create
    assert_response :success
    assert @voucher = assigns(:voucher)
    assert !@voucher.valid?, 'voucher should not be valid'
  end
  
  def test_should_create_without_voucher_with_user
    login_as :lisa
    post :create
    assert_response :success
    assert @voucher = assigns(:voucher)
    assert !@voucher.valid?, 'voucher should not be valid'
  end
  
  def test_should_create_with_expired_voucher_and_valid_verification_code
    post :create, voucher_attributes(PartnerMembershipVoucher.create(
      :expires_at => Time.now.utc - 1.day
    ), 'want2test')
    assert_response :success
    assert @voucher = assigns(:voucher)
    assert !@voucher.valid?, 'voucher should not be valid'
  end

  def test_should_create_with_valid_voucher_and_invalid_verification_code
    post :create, voucher_attributes(PartnerMembershipVoucher.create, 'invalid')
    assert_response :success
    assert @voucher = assigns(:voucher)
    assert !@voucher.valid?, 'voucher should not be valid'
  end

  def test_should_create_with_valid_partner_voucher_valid_verification_code
    post :create, voucher_attributes(PartnerMembershipVoucher.create, 'want2test')
    assert @voucher = assigns(:voucher)
    assert @voucher.valid?, 'voucher should be valid'
    assert current_voucher, 'current voucher should be assigned'
    assert_response :redirect
    assert_redirected_to complete_voucher_path
  end
  
  def test_should_create_with_invalid_voucher
    login_as :lisa
    post :create, voucher_attributes(PartnerMembershipVoucher.create(
      :expires_at => Time.now.utc - 1.day
    ))
    assert_response :success
    assert @voucher = assigns(:voucher)
    assert !@voucher.valid?, 'voucher should not be valid'
  end
  
  def test_should_create_with_valid_partner_voucher_and_redirect_to_new_partner
    login_as :lisa
    post :create, voucher_attributes(PartnerMembershipVoucher.create)
    assert @voucher = assigns(:voucher)
    assert @voucher.valid?, 'voucher should be valid'
    assert current_voucher, 'current voucher should be assigned'
    assert_response :redirect
    assert_redirected_to new_user_partner_path
  end

  def test_should_create_with_valid_voucher_and_redirect_to_complete
    login_as :lisa
    post :create, voucher_attributes(Voucher.create(:expires_at => Time.now.utc + 1.day))
    assert @voucher = assigns(:voucher)
    assert @voucher.valid?, 'voucher should be valid'
    assert current_voucher, 'current voucher should be assigned'
    assert_response :redirect
    assert_redirected_to complete_voucher_path
  end
  
  protected
  
  def voucher_attributes(voucher, verification_code=nil, options={})
    voucher.code_confirmation = voucher.code if voucher
    {"voucher"=>{"code_confirmation_attributes"=>{"3s"=>"#{voucher.code_confirmation(3) || ''}", "2s"=>"#{voucher.code_confirmation(2) || ''}", "1s"=>"#{voucher.code_confirmation(1) || ''}"}}.merge(verification_code ? {"verification_code"=>"#{verification_code}"} : {})}.merge(options)
  end

end
