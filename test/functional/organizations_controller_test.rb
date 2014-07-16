require File.dirname(__FILE__) + '/../test_helper'
require 'organizations_controller'

# Re-raise errors caught by the controller.
class OrganizationsController; def rescue_action(e) raise e end; end

class OrganizationsControllerTest < Test::Unit::TestCase
  all_fixtures
  
  def setup
    @controller = OrganizationsController.new
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
    get :index
    assert_response :success
    assert assigns(:tiers)
    assert assigns(:recent_tiers)
    assert assigns(:popular_tiers)
  end
  
  def test_should_get_show
    create_problems(5, :tier => tiers(:luleka), :person => people(:homer))
    get :show, :id => "#{tiers(:luleka).permalink}"
    assert assigns(:kases)
    assert_equal 5, assigns(:kases).size
    assert assigns(:popular_topics)
    assert assigns(:recent_topics)
  end

  def test_should_post_create
    assert_difference Organization, :count do
      post :create, {"organization" => valid_organization_attributes.stringify_keys}
    end
    assert_response :redirect
    assert assigns(:tier)
    assert_equal people(:homer), assigns(:tier).created_by
  end

  def test_should_get_new
    get :new
    assert_response :success
  end

  def test_should_not_post_create
    assert_no_difference Organization, :count do
      post :create, {"organization" => {}}
    end
    assert_response :success
    assert !assigns(:tier).valid?
  end

  protected
  

end
