require File.dirname(__FILE__) + '/../../test_helper'
require 'account/emails_controller'

# Re-raise errors caught by the controller.
class Account::EmailsController; def rescue_action(e) raise e end; end

class Account::EmailsControllerTest < Test::Unit::TestCase
  all_fixtures
  
  def setup
    @controller = Account::EmailsController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
    
    @request.with_subdomain('us')
    
    @user = users(:homer)
    @person = people(:homer)
    login_as :homer
    account_login_as :homer
  end
  
  def test_should_route
    assert_routing '/account/email', hash_for_path(:account_email)
    assert_recognizes(hash_for_path(:account_email, :action => 'update'), {:path => '/account/email', :method => :put})
  end
  
  def test_should_new
    get :show
    assert_response :success
  end
  
  def test_should_update
    put :update, params_for(@user, {"password"=>"homer", "email"=>"newhomer@simpson.com"})
    assert_response :redirect
    assert @user = assigns(:user)
    assert @user.valid?, "user should be valid"
    assert_equal "newhomer@simpson.com", @user.email 
  end
  
  def test_should_not_update_wrong_password
    put :update, params_for(@user, {"password"=>"bogus", "email"=>"newhomer@simpson.com"})
    assert_response :success
  end

  def test_should_not_update_wrong_email_format
    put :update, params_for(@user, {"password"=>"homer", "email"=>"bogusemail"})
    assert_response :success
  end

  protected
  
  def params_for(user, options={})
    {"user"=>{"password"=>"#{user.password}", "email"=>"#{user.email}"}.merge(options)}
  end
  
end
