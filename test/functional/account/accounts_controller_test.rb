require File.dirname(__FILE__) + '/../../test_helper'
require 'account/accounts_controller'

# Re-raise errors caught by the controller.
class Account::AccountsController; def rescue_action(e) raise e end; end

class Account::AccountsControllerTest < Test::Unit::TestCase
  all_fixtures

  def setup
    @controller = Account::AccountsController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
    
    @request.with_subdomain('us')
    
    logout
    account_logout
    admin_logout
  end

  def test_should_route_account
    assert_routing '/account', {:controller => 'account/accounts', :action => 'show'}
    assert_recognizes(hash_for_path(:account), {:path => '/account', :method => :get})
  end
  
  def xtest_should_show
    login_as :homer
    account_login_as :homer
    get :show
    assert_response :success
  end

  def test_should_not_show_and_redirect_to_account_login
    get :show
    assert_response :redirect
    assert_redirected_to new_account_session_path
  end
  

end