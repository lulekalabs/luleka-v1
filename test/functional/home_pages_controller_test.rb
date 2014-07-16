require File.dirname(__FILE__) + '/../test_helper'
require 'home_pages_controller'

# Re-raise errors caught by the controller.
class HomePagesController; def rescue_action(e) raise e end; end

class HomePagesControllerTest < Test::Unit::TestCase
  all_fixtures
  
  def setup
    @controller = HomePagesController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new

    @request.with_subdomain('us')

    logout
  end
  
  def test_should_get_index
    get :index
    assert :success
  end
  
  def test_should_get_index_with_user
    login_as :homer
    get :index
    assert :success
  end
  
  def test_should_set_locale_through_param
    @request.with_subdomain('de')
    self.current_locale = nil
    get :index
    assert :success
    assert_equal 'de-DE', @current_locale = assigns(:current_locale)
  end

  def test_should_set_locale_through_session
    @request.with_subdomain('de')
    self.current_locale = 'de-DE'
    get :index
    assert :success
    assert_equal 'de-DE', @current_locale = assigns(:current_locale)
  end

  def test_should_set_locale_through_user
    login_as :homer
    self.current_locale = 'de-DE'
    get :index
    assert :success
    assert_equal 'en-US', users(:homer).default_locale
  end

  
end
