require File.join(File.dirname(__FILE__), '../test_helper.rb')

class SessionCaptchaActionControllerTest < Test::Unit::TestCase  
  
  # Just a simple test of the image code. Most of the code was taken from simple_captcha
  def test_captcha_image
    image = SessionCaptcha::CaptchaImage.new
    assert_equal 6, image.code.length
    assert_not_nil image.code_image
  end
  
  
end
