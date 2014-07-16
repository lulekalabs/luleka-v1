# Handles sharing the kase with others
class EmailKase < Email
  extend SessionCaptcha::ActiveRecordHelpers
	
  #--- accessors
  attr_accessor :kase
  attr_accessor :validate_verification_code
  attr_protected :validate_verification_code
  
  #--- validators
  validates_presence_of :kase
	add_captcha_verification :verification_code, :if => :validate_verification_code?
  
  #--- instance methods

  # overrides from Email
  def deliver
    I18n.switch_locale self.language || Utility.language_code do 
      EmailMailer.deliver_share_kase(self, self.kase) if self.valid?
    end
  end
  
  # adds subject
  def subject
    unless @subject
      "%{name} wants to know what you think".t % {:name => self.sender_name}
    else
      @subject
    end
  end
  
  # returns true if the validation code (captcha) should be validated,
  # normally, this should return false
  def validate_verification_code?
    @validate_verification_code ||= true
  end
  
end
