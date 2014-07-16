require File.dirname(__FILE__) + '/../test_helper'
require 'pages_controller'

# Re-raise errors caught by the controller.
class PagesController; def rescue_action(e) raise e end; end

class PagesControllerTest < Test::Unit::TestCase
  all_fixtures
  
  def setup
    @controller = PagesController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new

    @request.with_subdomain('us')

    logout
  end
  
  def test_should_get_about
    get :show, {:id => 'about'}
    assert :success
    assert @page = assigns(:page)
    assert_equal "About", @page.title
  end

  def test_should_not_get_bogus
    get :show, {:id => 'bogus'}
    assert :redirect
  end
  
end
