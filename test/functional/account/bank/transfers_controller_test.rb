require File.dirname(__FILE__) + '/../../../test_helper'
require 'account/bank/transfers_controller'

# Re-raise errors caught by the controller.
class Account::Bank::TransfersController; def rescue_action(e) raise e end; end

class Account::Bank::TransfersControllerTest < Test::Unit::TestCase
  all_fixtures
  
  def setup
    @controller = Account::Bank::TransfersController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
    
    @request.with_subdomain('us')
    
    login_person(:homer)
  end
  
  def test_should_route
    assert_routing '/account/bank/transfer/new', hash_for_path(:new_account_bank_transfer)
  end
  
  def test_should_get_new
    get :new
    assert_response :success
  end
  
  def test_should_not_create_without_amount
    post :create, {"deposit_object"=>{"transfer_amount"=>""}, "paypal"=>{"paypal_account"=>"sepp@meier.com"}}
    assert_response :success
  end
  
  def test_should_not_create_without_parameters
    post :create
    assert_response :success
  end
  
  def test_should_create
    @person.piggy_bank.direct_deposit(Money.new(500, 'USD'))
    post :create, {"deposit_object"=>{"transfer_amount"=>"5"}, "paypal"=>{"paypal_account"=>"sepp@meier.com"},  "deposit_method"=>"paypal"}
    assert_response :redirect
    assert_redirected_to complete_account_bank_transfer_path
    @person.piggy_bank.reload
    assert_equal Money.new(0, 'USD'), @person.piggy_bank.balance
    assert_equal Money.new(0, 'USD'), @person.piggy_bank.available_balance
  end

  def test_should_not_create_with_insufficient_funds
    @person.piggy_bank.direct_deposit(Money.new(500, 'USD'))
    post :create, {"deposit_object"=>{"transfer_amount"=>"5.01"}, "paypal"=>{"paypal_account"=>"sepp@meier.com"},  "deposit_method"=>"paypal"}
    assert_response :success
  end
  
  def test_should_not_create_underruns_minimum_transfer_amount
    @person.piggy_bank.direct_deposit(Money.new(500, 'USD'))
    post :create, {"deposit_object"=>{"transfer_amount"=>"#{money_format(PaypalDepositAccount.min_transfer_amount_cents - 1)}"}, "paypal"=>{"paypal_account"=>"sepp@meier.com"},  "deposit_method"=>"paypal"}
    assert_response :success
  end

  def test_should_not_create_overruns_maximum_transfer_amount
    @person.piggy_bank.direct_deposit(Money.new(500, 'USD'))
    post :create, {"deposit_object"=>{"transfer_amount"=>"#{money_format(PaypalDepositAccount.max_transfer_amount_cents + 1)}"}, "paypal"=>{"paypal_account"=>"sepp@meier.com"},  "deposit_method"=>"paypal"}
    assert_response :success
  end
  
  def test_should_not_get_complete
    get :complete
    assert_response :redirect
    assert_redirected_to new_account_bank_transfer_path
  end

  def test_should_get_complete
    assign_current_transfer_time Time.now.utc
    get :complete
    assert_response :success
#    assert_nil current_transfer_time
  end
  
  protected
  
  def money_format(cents, currency='USD')
    Money.new(cents, currency).format(:strip_symbol => true)
  end
  
  def login_person(person)
    @user = users(person)
    @person = people(person)
    login_as person
    account_login_as person
  end
  
  # hash key for transfer time
  def transfer_time_session_param
    :transfer_time
  end

  # Accesses the current transfer time from the session. 
  # Future calls avoid the database because nil is not equal to false.
  def current_transfer_time
    @current_transfer_time ||= load_transfer_time_from_session unless @current_transfer_time == false
  end

  # Store the given transfer time in the session.
  def current_transfer_time=(new_transfer_time)
    @request.session[transfer_time_session_param] = new_transfer_time ? new_transfer_time.to_s : nil
    @current_transfer_time = new_transfer_time || false
  end
  
  def assign_current_transfer_time(new_transfer_time)
    self.current_transfer_time = new_transfer_time
  end
  
  # loads the time object from session
  def load_transfer_time_from_session
    self.current_transfer_time = Time.parse(@request.session[transfer_time_session_param]) if @request.session[transfer_time_session_param]
  end
  
end
