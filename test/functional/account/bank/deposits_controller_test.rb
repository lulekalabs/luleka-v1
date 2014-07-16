require File.dirname(__FILE__) + '/../../../test_helper'
require 'account/bank/deposits_controller'

# Re-raise errors caught by the controller.
class Account::Bank::DepositsController; def rescue_action(e) raise e end; end

class Account::Bank::DepositsControllerTest < Test::Unit::TestCase
  all_fixtures
  
  def setup
    @controller = Account::Bank::DepositsController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
    
    @request.with_subdomain('us')
    
    login_person(:homer)
  end
  
  def test_should_route
    assert_routing '/account/bank/deposit/new', hash_for_path(:new_account_bank_deposit)
  end
  
  def test_should_get_new
    get :new
    assert_response :success
  end
  
  def test_should_post_create_with_one_5usd_purchasing_credit
    post :create, {"times"=>{"PC00601EN-US"=>"1"}, "credits"=>["PC00601EN-US"]}
    assert_response :redirect
    assert_redirected_to edit_account_bank_deposit_path
    assert @cart = current_cart
    assert_equal Money.new(500, 'USD'), @cart.total
  end

  def test_should_post_create_with_nine_5usd_purchasing_credits
    post :create, {"times"=>{"PC00601EN-US"=>"9"}, "credits"=>["PC00601EN-US"]}
    assert_response :redirect
    assert_redirected_to edit_account_bank_deposit_path
    assert @cart = current_cart
    assert_equal Money.new(500 * 9, 'USD'), @cart.total
  end

  def test_should_post_create_with_zero_purchasing_credits
    post :create, {"times"=>{"PC00601EN-US"=>"0"}, "credits"=>["PC00601EN-US"]}
    assert_response :success
  end

  def test_should_post_create_without_parameters
    post :create
    assert_response :success
  end
  
  def test_should_get_edit
    @person.cart.add(topics(:five_purchasing_credit_en))
    assign_current_cart @person.cart
    get :edit
    assert_response :success
  end
  
  def test_should_put_update
    @person.cart.add(topics(:five_purchasing_credit_en))
    assign_current_cart @person.cart
    put :update, payment_params_for(true, @person)
    assert @person = assigns(:person)
    assert_response :redirect
    assert_redirected_to complete_account_bank_deposit_path
  end

  def test_should_not_put_update_invalid_payment
    @person.cart.add(topics(:five_purchasing_credit_en))
    assign_current_cart @person.cart
    put :update, payment_params_for(false, @person)
    assert_response :success
  end
  
  def test_should_get_complete
    @person.cart.add(topics(:five_purchasing_credit_en))
    assign_current_cart @person.cart
    @order, @payment = @person.purchase_and_pay(@person.cart, PaymentMethod.build(:bogus, {
      "month"=>"4", "number"=>"1", "verification_value"=>"", "year"=>"2009", "first_name"=>"#{@person.first_name}", "last_name"=>"#{@person.last_name}"
    }))
    assert @payment.success?
    assign_current_order(@order)
    get :complete
    assert_response :success
    assert_nil current_order, 'should remove current order from session'
  end
  
  def test_should_not_get_complete
    get :complete
    assert_response :redirect
    assert_redirected_to new_account_bank_deposit_path
  end
  
  def test_should_not_get_complete_missing_order
    @person.cart.add(topics(:five_purchasing_credit_en))
    assign_current_cart @person.cart
    get :complete
    assert_response :redirect
    assert_redirected_to new_account_bank_deposit_path
  end
  
  protected
  
  def login_person(person)
    @user = users(person)
    @person = people(person)
    login_as person
    account_login_as person
  end
  
  def payment_params_for(valid, person)
    {"bogus"=>{"month"=>"4", "number"=>"#{valid ? '1' : '2'}", "verification_value"=>"", "year"=>"2011", "first_name"=>"#{person.first_name}", "last_name"=>"#{person.last_name}"}, "payment_method"=>"bogus", "person"=>{"billing_address_attributes"=>{"city"=>"San Francisco", "postal_code"=>"94113", "company_name"=>"Funky Business LLC", "academic_title_id"=>"#{person.academic_title ? person.academic_title.id : ''}", "gender"=>"#{person.gender}", "street"=>"100 Rousseau St", "first_name"=>"#{person.first_name}", "last_name"=>"#{person.last_name}", "middle_name"=>""}}}
  end
  
end
