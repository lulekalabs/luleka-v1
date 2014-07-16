require File.dirname(__FILE__) + '/../test_helper'
require 'tiers_controller'

# Re-raise errors caught by the controller.
class TiersController; def rescue_action(e) raise e end; end

class TiersControllerTest < Test::Unit::TestCase
  all_fixtures
  
  def setup
    @controller = TiersController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new

    @request.with_subdomain('us')

    login_as :homer
  end

  def test_simple
    assert true
  end
  
end
