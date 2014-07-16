require File.dirname(__FILE__) + '/../test_helper'
require 'sessions_controller'

# Re-raise errors caught by the controller.
class SessionsController; def rescue_action(e) raise e end; end

class SessionsControllerTest < Test::Unit::TestCase
  all_fixtures
  
  def setup
    @controller = SessionsController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
    
    @request.with_subdomain('us')
    
    logout
  end

  def test_should_route
    assert_routing '/session/new', hash_for_path(:new_session)
  end

  def test_should_new
    get :new
    assert_response :success
  end
  
  def test_should_create
    @user = create_user(:password => 'want2test', :password_confirmation => 'want2test')
    assert @user.valid?, 'user should be valid'
    assert @user.activate!
    post :create, user_attributes(@user, {:password => 'want2test'})
    assert current_user, 'should assign current user'
    assert_response :redirect
  end

  def test_should_create_with_remember_me
    @user = create_user(:password => 'want2test', :password_confirmation => 'want2test')
    assert @user.activate!
    post :create, user_attributes(@user, {"password"=>'want2test', "remember_me" => "1"})
    assert current_user, 'should assign current user'
    assert_response :redirect
  end

  def test_should_not_create
    @user = create_user(:password => 'want2test', :password_confirmation => 'want2test')
    @user.activate!
    post :create, user_attributes(@user, {"password"=>"bogus"})
    assert_response :success
  end
  
  def test_should_destroy
    login_as :lisa
    assert_equal users(:lisa), current_user
    delete :destroy
    assert_nil current_user
  end

  def test_should_destroy_app_and_account_user
    login_as :lisa
    account_login_as :lisa
    assert_equal users(:lisa), current_user
    assert_equal users(:lisa), current_account_user
    delete :destroy
    assert_nil current_user
    assert_nil current_account_user
  end
  
  protected
  
  def user_attributes(user, options={})
    {"user"=>{"password"=>"#{user.password}", "login"=>"#{user.login}", "remember_me"=>"0"}.merge(options)}
  end
  
end
