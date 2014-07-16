require File.dirname(__FILE__) + '/../../test_helper'
require 'account/internationals_controller'

# Re-raise errors caught by the controller.
class Account::InternationalsController; def rescue_action(e) raise e end; end

class Account::InternationalsControllerTest < Test::Unit::TestCase
  all_fixtures
  
  def setup
    @controller = Account::InternationalsController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
    
    @request.with_subdomain('us')
    
    @user = users(:homer)
    @person = people(:homer)
    login_as :homer
    account_login_as :homer
  end
  
  def test_should_route
    assert_routing '/account/international', hash_for_path(:account_international)
    assert_recognizes(hash_for_path(:account_international, :action => 'update'), {:path => '/account/international', :method => :put})
  end
  
  def test_should_show
    get :show
    assert_response :success
  end

  def test_should_update
    @user.time_zone = "Berlin"
    @user.language = 'de'
    put :update, params_for(@user)
    assert_equal Account::InternationalsController::MESSAGE_SUCCESS, @response.flash[:notice]
    assert_response :redirect
    assert @user = assigns(:user)
    assert_equal 'de', @user.language
    assert_equal 'Berlin', @user.time_zone
  end

  protected
  
  def params_for(user, options={})
    {"user"=>{"language"=>"#{user.language}", "time_zone"=>"#{user.time_zone}"}}
  end
  
end
