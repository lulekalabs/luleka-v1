require File.dirname(__FILE__) + '/../test_helper'
require 'claimings_controller'

# Re-raise errors caught by the controller.
class ClaimingsController; def rescue_action(e) raise e end; end

class ClaimingsControllerTest < Test::Unit::TestCase
  all_fixtures
  
  def setup
    @controller = ClaimingsController.new
    @request    = ActionController::TestRequest.new

    @request.with_subdomain('us')

    @response   = ActionController::TestResponse.new
    
    login_as :homer
  end

  def test_security
    logout
    assert_requires_login :index
    assert_requires_login :new
    assert_requires_login :create
  end

  def should_get_new
    get :new, :organization_id => "#{tiers(:powerplant).permalink}"
    assert_response :success
  end

  def test_should_create
    assert_difference Claiming, :count, tiers(:luleka).products.active.current_region.size + 1 do
      post :create, {"organization_id" => "#{tiers(:luleka).permalink}", "claiming" => {
        "description" => "I am a new employee, please add me.",
        "email" => "homer@luleka.net",
        "phone" => "+1 123 344 2345",
        "role" => "Product Manager",
        "product_ids" => tiers(:luleka).products.active.current_region.map(&:id).map(&:to_s)
      }}
    end
    assert_response :redirect
    assert assigns(:claiming)
    assert assigns(:topics)
    assert_equal tiers(:luleka).products.active.current_region.size, assigns(:claiming).products.size
    assert_equal :pending, assigns(:claiming).current_state
  end

  def test_should_not_create
    assert_difference Claiming, :count, 0 do
      post :create, {"organization_id" => "#{tiers(:luleka).permalink}", "claiming" => {}}
    end
    assert_response :success
    assert_template "claimings/new"
  end

  def test_should_get_confirm
    assert_difference Employment, :count do 
      assert claiming = create_claiming(:person => people(:homer), :organization => tiers(:powerplant))
      assert claiming.register!
    
      get :confirm, {"organization_id" => "#{tiers(:powerplant).permalink}", "id"=>"#{claiming.activation_code}"}
      assert_response :redirect
      assert @claiming = assigns(:claiming), "should assign claiming"
      assert_equal :accepted, @claiming.current_state
      assert_redirected_to person_path(claiming.person)
    end
  end

  def test_should_get_confirm_already_accepted
    assert claiming = create_claiming(:person => people(:homer), :organization => tiers(:powerplant))
    assert claiming.register!
    assert claiming.accept!
    
    assert_no_difference Employment, :count do 
      get :confirm, {"organization_id" => "#{tiers(:powerplant).permalink}", "id"=>"#{claiming.activation_code}"}
      assert_response :redirect
      assert_redirected_to organization_path(tiers(:powerplant))
    end
  end
  
  def test_should_not_get_confirm
    get :confirm
    assert_response :redirect
    assert_redirected_to organizations_path
  end

  protected
  
  def valid_claiming_attributes(options={})
    {
      :person => people(:homer),
      :organization => tiers(:luleka),
      :description => "Man, I am an employee.",
      :email => 'homer@luleka.net',
      :role => 'Product Manager'
    }.merge(options)
  end
  
  def create_claiming(options={})
    Claiming.create(valid_claiming_attributes(options))
  end

  def build_claiming(options={})
    Claiming.new(valid_claiming_attributes(options))
  end
  
end
