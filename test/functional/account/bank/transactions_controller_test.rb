require File.dirname(__FILE__) + '/../../../test_helper'
require 'account/bank/transactions_controller'

# Re-raise errors caught by the controller.
class Account::Bank::TransactionsController; def rescue_action(e) raise e end; end

class Account::Bank::TransactionsControllerTest < Test::Unit::TestCase
  all_fixtures
  
  def setup
    @controller = Account::Bank::TransactionsController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
    
    @request.with_subdomain('us')
    
    login_person(:homer)
  end
  
  def test_should_route
    assert_routing '/account/bank/transactions', hash_for_path(:account_bank_transactions)
  end
  
  def test_should_index
    get :index
    assert_response :success
  end

  def test_should_show
    create_order
    transaction = PiggyBankAccountTransaction.find(:first)
    get :show, {"id"=>"#{transaction.number}"}
    assert_response :success
  end
  
  protected
  
  def login_person(person)
    @user = users(person)
    @person = people(person)
    login_as person
    account_login_as person
  end

  def create_order
    @person.piggy_bank.direct_deposit(Money.new(10000, 'USD'))
    @person.cart.add topics(:three_month_partner_membership_en)
    @order, @payment = @person.purchase_and_pay(@person.cart, @person.piggy_bank)
    @order if @payment.success?
  end

end
