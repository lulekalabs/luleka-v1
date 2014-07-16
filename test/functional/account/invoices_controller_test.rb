require File.dirname(__FILE__) + '/../../test_helper'
require 'account/invoices_controller'

# Re-raise errors caught by the controller.
class Account::InvoicesController; def rescue_action(e) raise e end; end

class Account::InvoicesControllerTest < Test::Unit::TestCase
  all_fixtures
  
  def setup
    @controller = Account::InvoicesController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
    
    @request.with_subdomain('us')
    
    login_person(:homer)
  end
  
  def test_should_route
    assert_routing '/account/invoices', hash_for_path(:account_invoices)
  end
  
  def test_should_index
    get :index
    assert_response :success
  end

  def test_should_index_with_orders
    create_invoice
    get :index
    assert_response :success
  end

  def test_should_index_with_orders_as_member
    login_person(:lisa)
    create_invoice
    get :index
    assert_response :success
  end

  def test_should_show
    @invoice = create_invoice
    get :show, {"id"=>"#{@invoice.number}"} 
    assert_response :success
    assert @response.body.include?(@invoice.short_number)
  end
  
  def test_should_show_pdf
    @invoice = create_invoice
    get :show, {"format"=>"pdf", "id"=>"#{@invoice.number}"}
    assert_response :success
  end
  
  protected
  
  def create_invoice
    @person.piggy_bank.direct_deposit(Money.new(10000, 'USD'))
    @person.cart.add topics(:three_month_partner_membership_en)
    @order, @payment = @person.purchase_and_pay(@person.cart, @person.piggy_bank)
    @order.invoice if @payment.success?
  end
  
  def login_person(person)
    @user = users(person)
    @person = people(person)
    login_as person
    account_login_as person
  end
end
