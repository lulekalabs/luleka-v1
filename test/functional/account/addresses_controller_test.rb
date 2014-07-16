require File.dirname(__FILE__) + '/../../test_helper'
require 'account/addresses_controller'

# Re-raise errors caught by the controller.
class Account::AddressesController; def rescue_action(e) raise e end; end

class Account::AddressesControllerTest < Test::Unit::TestCase
  all_fixtures
  
  def setup
    @controller = Account::AddressesController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
    
    @request.with_subdomain('us')
    
    login_person(:homer)
  end
  
  def test_should_route
    assert_routing '/account/address', hash_for_path(:account_address)
    assert_routing '/account/address/personal', hash_for_path(:personal_account_address)
    assert_routing '/account/address/business', hash_for_path(:business_account_address)
    assert_routing '/account/address/billing', hash_for_path(:billing_account_address)
  end
  
  def test_should_show
    get :show
    assert_response :success
  end

  def test_should_get_personal
    get :personal
    assert_response :success
  end
  
  def test_should_get_business
    get :business
    assert_response :success
  end

  def test_should_get_business_only_for_partners
    login_person(:lisa)
    get :business
    assert_response :redirect
  end
  
  def test_should_get_billing
    get :billing
    assert_response :success
  end
  
  def test_should_update_personal
    put :update, {"_property"=>"personal", "address"=>{"personal_address_attributes"=>{"city"=>"München", "country_code"=>"DE", "postal_code"=>"80469", "mobile"=>"", "province_code"=>"BY", "fax"=>"", "phone"=>"+49 89 123456789", "street"=>"Dreimühlenstr. 21"}}}
    assert @address = assigns(:address)
    assert_equal :personal, @address.kind
    assert_equal "Dreimühlenstr. 21, München, Missouri, 80469, United States", @address.to_s
    assert_response :redirect
    assert_redirected_to account_path
  end

  def test_should_update_business
    put :update, {"_property"=>"business", "address"=>{"business_address_attributes"=>{"city"=>"San Francisco", "country_code"=>"US", "postal_code"=>"94112", "mobile"=>"+1 415 111 2222", "province"=>"","province_code"=>"CA", "fax"=>"", "phone"=>"+1 415 123 5678", "street"=>"100 Rousseau St"}}}
    assert @address = assigns(:address)
    assert_equal :business, @address.kind
    assert_equal "100 Rousseau St, San Francisco, CA, 94112, United States", @address.to_s
    assert_response :redirect
    assert_redirected_to account_path
  end
  
  def test_should_update_billing
    put :update, {"_property"=>"billing", "address"=>{"billing_address_attributes"=>{"city"=>"San Francisco", "postal_code"=>"94113", "company_name"=>"Funky Business LLC", "academic_title_id"=>"26", "gender"=>"m", "street"=>"100 Rousseau St", "first_name"=>"Simon", "last_name"=>"Garfunkel", "middle_name"=>""}}}
    assert @address = assigns(:address)
    assert_equal :billing, @address.kind
    assert_equal "Simon Garfunkel, 100 Rousseau St, San Francisco, Missouri, 94113, United States", @address.to_s
    assert_response :redirect
    assert_redirected_to account_path
  end
  
  protected
  
  def login_person(person)
    @user = users(person)
    @person = people(person)
    login_as person
    account_login_as person
  end
  
end
