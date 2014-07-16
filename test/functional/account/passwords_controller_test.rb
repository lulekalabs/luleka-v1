require File.dirname(__FILE__) + '/../../test_helper'
require 'account/passwords_controller'

# Re-raise errors caught by the controller.
class Account::PasswordsController; def rescue_action(e) raise e end; end

class Account::PasswordsControllerTest < Test::Unit::TestCase
  all_fixtures
  
  def setup
    @controller = Account::PasswordsController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
    @user = users(:homer)
    @person = people(:homer)
    
    @request.with_subdomain('us')
    
    login_as :homer
    account_login_as :homer
  end
  
  def test_should_route
    assert_routing '/account/password', hash_for_path(:account_password)
    assert_recognizes(hash_for_path(:account_password, :action => 'update'), {:path => '/account/password', :method => :put})
  end
  
  def test_should_new
    get :show
    assert_response :success
  end

  def test_should_update
    put :update, params_for("homer", "newpassword", "newpassword")
    assert_response :redirect
    assert @user = assigns(:user)
    assert_equal Account::PasswordsController::MESSAGE_SUCCESS, @response.flash[:notice]
  end
  
  def test_should_not_update_wrong_password
    put :update, params_for("bogus", "newpassword", "newpassword")
    assert_response :success
    assert_equal Account::PasswordsController::MESSAGE_ERROR, @response.flash[:error]
  end

  def test_should_not_update_wrong_confirmation_1st
    put :update, params_for("homer", "newpassword", "bogus")
    assert_response :success
    assert_equal Account::PasswordsController::MESSAGE_ERROR, @response.flash[:error]
  end

  protected
  
  def params_for(pw, new_pw, new_pw_confirmation, options={})
    {"user"=>{"new_password_confirmation"=>"#{new_pw_confirmation}", "new_password"=>"#{new_pw}", "password"=>"#{pw}"}.merge(options)}
  end
  
end
