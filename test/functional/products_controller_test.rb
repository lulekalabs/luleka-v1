require File.dirname(__FILE__) + '/../test_helper'
require 'products_controller'

# Re-raise errors caught by the controller.
class ProductsController; def rescue_action(e) raise e end; end

class ProductsControllerTest < Test::Unit::TestCase
  all_fixtures
  
  def setup
    @controller = ProductsController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new

    @request.with_subdomain('us')

    login_as :homer
  end

  def test_security
    logout
    assert_requires_login :index
    assert_requires_login :new
    assert_requires_login :create
    assert_requires_login :show
  end
  
  def test_should_get_index
    get :index, :organization_id => "#{tiers(:powerplant).permalink}"
    assert_response :success
    assert assigns(:tier)
    assert assigns(:popular_topics)
  end

  def test_should_get_new
    get :new, :organization_id => "#{tiers(:powerplant).permalink}"
    assert_response :success
  end
  
  def test_should_get_show
    get :show, :organization_id => "#{tiers(:powerplant).permalink}",
      :id => "#{topics(:electricity).permalink}"
    assert_response :success
    assert assigns(:kases)
    assert assigns(:popular_topics)
    assert assigns(:recent_topics)
  end
  
  def test_should_create
    assert_difference Product, :count do
      post :create, {"organization_id" => "#{tiers(:powerplant).permalink}", "product" => valid_product_attributes.stringify_keys}
    end
    assert_response :redirect
    assert assigns(:topic)
    assert_equal people(:homer), assigns(:topic).created_by
    assert_equal :pending, assigns(:topic).current_state
  end

  def test_should_not_create
    assert_difference Product, :count, 0 do
      post :create, {"organization_id" => "#{tiers(:powerplant).permalink}", "product" => invalid_product_attributes.stringify_keys}
    end
    assert_response :success
    assert !assigns(:topic).valid?
  end


end
