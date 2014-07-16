require File.dirname(__FILE__) + '/../../test_helper'
require 'account/sessions_controller'

# Re-raise errors caught by the controller.
class Account::SessionsController; def rescue_action(e) raise e end; end

class Account::SessionsControllerTest < Test::Unit::TestCase
  all_fixtures
  
  def setup
    @controller = Account::SessionsController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
    
    logout
    account_logout
    login_as :homer

    with_subdomain('us')
  end

  def test_should_route
    assert_routing '/account/session/new', hash_for_path(:new_account_session)
  end

  def test_should_get_new
    @request.with_subdomain('us')
    get :new
    assert_response :success
  end
  
  def test_should_create
    @user = create_user(:password => 'want2test', :password_confirmation => 'want2test')
    assert @user.activate!
    post :create, user_attributes(@user, {:password => 'want2test'})
    assert current_account_user, 'should assign current account user'
    assert current_user, 'should assign current user'
    assert_response :redirect
  end

  def test_should_create_with_remember_me
    @user = create_user(:password => 'want2test', :password_confirmation => 'want2test')
    assert @user.activate!
    post :create, user_attributes(@user, {"password"=>'want2test', "remember_me" => "1"})
    assert current_account_user, 'should assign current account user'
    assert_response :redirect
  end

  def test_should_not_create
    @user = create_user(:password => 'want2test', :password_confirmation => 'want2test')
    @user.activate!
    post :create, user_attributes(@user, {"password"=>"bogus"})
    assert_response :success
  end
  
  def test_should_destroy
    account_login_as :lisa
    assert_equal users(:lisa), current_account_user
    delete :destroy
    assert_nil current_account_user, 'should destroy account user'
  end

  def test_should_destroy_app_and_account_user
    login_as :lisa
    account_login_as :lisa
    assert_equal users(:lisa), current_account_user
    assert_equal users(:lisa), current_user
    delete :destroy
    assert_nil current_account_user, 'should destroy account user'
    assert_nil current_user, 'should destroy user'
  end
  
  protected
  
  def user_attributes(user, options={})
    {"user"=>{"password"=>"#{user.password}", "login"=>"#{user.login}", "remember_me"=>"0"}.merge(options)}
  end
  
end
