require File.dirname(__FILE__) + '/../../test_helper'
require 'account/notifications_controller'

# Re-raise errors caught by the controller.
class Account::NotificationsController; def rescue_action(e) raise e end; end

class Account::NotificationsControllerTest < Test::Unit::TestCase
  all_fixtures
  
  def setup
    @controller = Account::NotificationsController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
    
    @request.with_subdomain('us')
    
    @user = users(:homer)
    @person = people(:homer)
    login_as :homer
    account_login_as :homer
  end
  
  def test_should_route
    assert_routing '/account/notification', hash_for_path(:account_notification)
    assert_recognizes(hash_for_path(:account_notification, :action => 'update'), {:path => '/account/notification', :method => :put})
  end
  
  def test_should_show
    get :show
    assert_response :success
  end

  def test_should_update
    put :update, params_for(@person)
    assert_equal Account::NotificationsController::MESSAGE_SUCCESS, @response.flash[:notice]
    assert_response :redirect
  end

  protected
  
  def params_for(person, options={})
    {"person"=>{"notify_on_follower"=>"0", "notify_on_clarification_request"=>"1", "notify_on_kase_matching"=>"1", "notify_on_following"=>"0", "notify_on_promotion"=>"0", "notify_on_newsletter"=>"1", "notify_on_kase_status"=>"0", "notify_on_clarification_response"=>"1"}}
    
  end
  
end
