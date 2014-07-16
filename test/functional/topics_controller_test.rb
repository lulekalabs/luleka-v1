require File.dirname(__FILE__) + '/../test_helper'
require 'tiers_controller'

# Re-raise errors caught by the controller.
class TopicsController; def rescue_action(e) raise e end; end

class TopicsControllerTest < Test::Unit::TestCase
  all_fixtures
  
  def setup
    @controller = TopicsController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new

    @request.with_subdomain('us')

    login_as :homer
  end
  
  def test_simple
    assert true
  end
    

end
