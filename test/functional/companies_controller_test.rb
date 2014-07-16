require File.dirname(__FILE__) + '/../test_helper'
require 'companies_controller'

# Re-raise errors caught by the controller.
class CompaniesController; def rescue_action(e) raise e end; end

class CompaniesControllerTest < Test::Unit::TestCase
  all_fixtures
  
  def setup
    @controller = CompaniesController.new
    @request    = ActionController::TestRequest.new

    @request.with_subdomain('us')

    @response   = ActionController::TestResponse.new
    
    login_as :homer
  end

  def test_post_create
    post :create, {"company"=>{"country_code"=>"", "name"=>"Test Inc", "site_url"=>"http://test.com", "description"=>"this is a test",
      "tag_list"=>"one two three", "site_name"=>"test", "owner"=>"0", "image"=>""}}
    assert_response :redirect
    assert @tier = assigns(:tier)
    assert_redirected_to companies_path
  end
  
  def test_get_show
    company = create_company(:site_name => "moveglobaly")
    company.activate!
    get :show, :id => "#{company.permalink}"
    assert_response :success
  end

  
end
