require File.join(File.dirname(__FILE__), '../test_helper.rb')

class SessionCaptchaActionControllerTest < Test::Unit::TestCase
  include SessionCaptcha::ActionControllerHelpers::InstanceMethods
  
  class TestModel < ActiveRecord::BaseWithoutTable
    extend SessionCaptcha::ActiveRecordHelpers
    add_captcha_verification :verification_code, :on => :create            
        
  end
  
  def test_clear_verification_codes
    model = TestModel.new    
    model.verification_code = 'foo'
    model.verification_code_session = 'bar'
    model.clear_verification_codes           
    assert_nil model.verification_code
    assert_nil model.verification_code_session
  end
  
  def test_verification_validation
    model = TestModel.new
    model.verification_code = 'foo'
    model.verification_code_session = 'bar'
    assert !model.valid?
    assert model.errors.invalid?(:verification_code)
    assert_equal 'Verification code is invalid', model.errors.full_messages[0]
    
    model.verification_code = 'foo'
    model.verification_code_session = nil
    assert !model.valid?
    assert model.errors.invalid?(:verification_code)
    
    model.verification_code = 'foo'
    model.verification_code_session = 'foo'
    assert model.valid?
    
    model.verification_code = 'want2test'
    model.verification_code_session = 'want2test'
    assert model.valid?
    
  end

end
