require File.dirname(__FILE__) + '/../../test_helper'
require 'account/orders_controller'

# Re-raise errors caught by the controller.
class Account::OrdersController; def rescue_action(e) raise e end; end

class Account::OrdersControllerTest < Test::Unit::TestCase
  all_fixtures
  
  def setup
    @controller = Account::OrdersController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
    
    @request.with_subdomain('us')
    
    login_person(:homer)
  end
  
  def test_should_route
    assert_routing '/account/orders', hash_for_path(:account_orders)
  end
  
  def test_should_index_with_partner
    get :index
    assert_response :success
  end

  def test_should_index_with_orders
    create_order
    get :index
    assert_response :success
  end

  def test_should_index_without_partner
    login_person(:lisa)
    create_order
    get :index
    assert_response :success
  end

  def test_should_show
    @order = create_order
    get :show, {"id"=>"#{@order.number}"} 
    assert_response :success
    assert @response.body.include?(@order.short_number)
  end
  
  protected
  
  def create_order
    @person.piggy_bank.direct_deposit(Money.new(10000, 'USD'))
    @person.cart.add topics(:three_month_partner_membership_en)
    @order, @payment = @person.purchase_and_pay(@person.cart, @person.piggy_bank)
    @order if @payment.success?
  end
  
  def login_person(person)
    @user = users(person)
    @person = people(person)
    login_as person
    account_login_as person
  end
  
end
