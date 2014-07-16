# SessionCaptcha
module SessionCaptcha
  
  module ActionControllerHelpers        
    
    # Creates an action method with the given method name that returns a captcha image
    # and stores the associated captcha code in the session under the given session_key. 
    def create_captcha_image_action(method_name=:verification_code, session_key=:verification_code)
      include InstanceMethods
      hide_action :get_and_clear_captcha_code
      define_method(method_name) do
        captcha = CaptchaImage.new # (:image_style => 'almost_invisible')
        session[session_key] = captcha.code    
        send_data captcha.code_image, :type => 'image/jpeg', :disposition => 'inline'
      end
    end
    
    module InstanceMethods
      # Returns the captcha code with the associated key and clears the captcha code 
      # from the session.
      def get_and_clear_captcha_code session_key = :verification_code
        captcha_code = session[session_key]
        session[session_key] = nil
        return captcha_code
      end
    end
  end
  
  
end