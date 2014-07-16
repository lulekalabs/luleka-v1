require File.join(File.dirname(__FILE__), '../test_helper.rb')
require 'action_controller/test_process'

class SessionCaptchaActionControllerTest < Test::Unit::TestCase
  include SessionCaptcha::ActionControllerHelpers::InstanceMethods
  
  class Controller < ActionController::Base
    extend SessionCaptcha::ActionControllerHelpers
    create_captcha_image_action
    create_captcha_image_action :foo, :bar
        
    def rescue_action(e) raise e end
  end

  def setup    
    @controller = Controller.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end 
  
  def test_image_action
    get :verification_code
        
    assert_response :success
    assert_image_response
    assert_not_nil @request.session[:verification_code]
  end
  
  def test_image_action_with_method_name
    get :foo
    assert_response :success
    assert_image_response
    assert_not_nil @request.session[:bar]
  end
  
  def test_get_and_clear_captcha_code
    get :verification_code
    assert_not_nil @request.session[:verification_code]
    captcha_code = @request.session[:verification_code]
    assert_equal captcha_code, get_and_clear_captcha_code
    assert_nil @request.session[:verification_code]
  end
  
  def test_get_and_clear_captcha_code_is_hidden
    begin
      get :get_and_clear_captcha_code
    rescue => exception      
      assert_equal ActionController::UnknownAction, exception.class
    end
    
  end
   
  def assert_image_response
    # TODO figure out how to test binary content
    #assert_not_nil @response.binary_content
    assert_equal 'image/jpeg', @response.content_type
  end

end
