require File.dirname(__FILE__) + '/../../../test_helper'
require 'account/bank/banks_controller'

# Re-raise errors caught by the controller.
class Account::Bank::BanksController; def rescue_action(e) raise e end; end

class Account::Bank::BanksControllerTest < Test::Unit::TestCase
  all_fixtures
  
  def setup
    @controller = Account::Bank::BanksController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
    
    @request.with_subdomain('us')
    
    login_person(:homer)
  end
  
  def test_should_route
    assert_routing '/account/bank', hash_for_path(:account_bank)
    assert_routing '/account/bank/transactions', hash_for_path(:account_bank_transactions)
  end
  
  def test_should_show
    get :show
    assert_response :redirect
    assert_redirected_to account_bank_transactions_path
  end
  
  protected
  
  def login_person(person)
    @user = users(person)
    @person = people(person)
    login_as person
    account_login_as person
  end

end
