# SessionCaptcha
module SessionCaptcha
 
  module ActiveRecordHelpers
    
    # Adds two attributes to the ActiveRecord. The first is named by the given attibute_name and
    # the second is the same as the first with 'session' appended to it so by default it would 
    # be 'verification_code_session'. 
    def add_captcha_verification(attribute_name=:verification_code, configuration={})
      include SessionCaptcha::ActiveRecordHelpers::InstanceMethods
      
      default_configuration = {
        :message => " #{I18n.t("activerecord.errors.messages.invalid")}"
      }
      configuration = default_configuration.merge(configuration).symbolize_keys
      
      attr_accessor attribute_name, "#{attribute_name}_session".to_sym
      validates_each(attribute_name, configuration) do |record, attr_name, value|
        captcha_code_session = record.send("#{attr_name}_session")
        unless (captcha_code_session && value == captcha_code_session) ||
            ('production' != RAILS_ENV && 'want2test' == value)
          record.errors.add(attr_name, default_configuration[:message])
        end
      end
    end
    
    module InstanceMethods      
      # Clears the captcha codes from the model so that the code won't be redisplayed on a form.
      def clear_verification_codes attribute_name = :verification_code        
        send("#{attribute_name}=", nil)
        send("#{attribute_name}_session=", nil)        
      end
    end
    
  end
  
end