require File.dirname(__FILE__) + '/../../test_helper'
require 'account/closes_controller'

# Re-raise errors caught by the controller.
class Account::ClosesController; def rescue_action(e) raise e end; end

class Account::ClosesControllerTest < Test::Unit::TestCase
  all_fixtures
  
  def setup
    @controller = Account::ClosesController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
    
    @request.with_subdomain('us')
    
    @user = users(:homer)
    @person = people(:homer)
    login_as :homer
    account_login_as :homer
  end
  
  def test_should_route
    assert_routing '/account/close', hash_for_path(:account_close)
    assert_recognizes(hash_for_path(:account_close, :action => 'update'), {:path => '/account/close', :method => :put})
  end
  
  def test_should_show
    get :show
    assert_response :success
  end

  def test_should_update
    put :update, params_for("homer", true)
    assert_equal Account::ClosesController::MESSAGE_SUCCESS, @response.flash[:notice]
    assert_response :redirect
    assert @user = assigns(:user)
    assert_equal :suspended, @user.current_state
  end

  def test_should_not_update_no_confirm
    put :update, params_for("homer", false)
    assert_equal Account::ClosesController::MESSAGE_ERROR, @response.flash[:error]
    assert_response :success
  end

  def test_should_not_update_wrong_password
    put :update, params_for("bogus", true)
    assert_equal Account::ClosesController::MESSAGE_ERROR, @response.flash[:error]
    assert_response :success
  end

  protected
  
  def params_for(password, destroy=false, options={})
    {"user"=>{"destroy_confirmation"=>"#{destroy ? '1' : '0'}", "password"=>"#{password}"}.merge(options)}
  end
  
end
