require File.dirname(__FILE__) + '/../../test_helper'
require 'admin/sessions_controller'

# Re-raise errors caught by the controller.
class Admin::SessionsController; def rescue_action(e) raise e end; end

class Admin::SessionsControllerTest < Test::Unit::TestCase
  fixtures :admin_users

  def setup
    @controller = Admin::SessionsController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
    logout
    admin_logout
    account_logout
  end

  def test_should_route
    assert_routing '/admin/session/new', hash_for_path(:new_admin_session)
  end

  def test_should_new
    get :new
    assert_response :success
  end

  def test_should_create
    @user = create_admin_user(:password => 'want2test', :password_confirmation => 'want2test')
    assert @user.activate!
    post :create, user_attributes(@user, {:password => 'want2test'})
    assert current_admin_user, 'should assign current user'
    assert_response :redirect
  end

  def test_should_create_with_remember_me
    @user = create_admin_user(:password => 'want2test', :password_confirmation => 'want2test')
    assert @user.activate!
    post :create, user_attributes(@user, {"password"=>'want2test', "remember_me" => "1"})
    assert current_admin_user, 'should assign current user'
    assert_response :redirect
  end

  def test_should_not_create
    @user = create_admin_user(:password => 'want2test', :password_confirmation => 'want2test')
    @user.activate!
    post :create, user_attributes(@user, {"password"=>"bogus"})
    assert_response :success
  end

  def test_should_destroy
    admin_login_as :quentin
    assert_equal admin_users(:quentin), current_admin_user
    delete :destroy
    assert_nil current_admin_user
  end

  protected

  def user_attributes(user, options={})
    {"user"=>{"password"=>"#{user.password}", "login"=>"#{user.login}", "remember_me"=>"0"}.merge(options)}
  end

end
