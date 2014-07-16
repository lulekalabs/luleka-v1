# Email instances 
class Email < Message
	extend SessionCaptcha::ActiveRecordHelpers
  
  #--- columns
  attr_accessor :subject

  attr_accessor :sender_name
  attr_accessor :sender_email
  attr_accessor :receiver_email

  add_captcha_verification :verification_code, :on => :create

  #--- validation
  validates_presence_of :subject, :sender_name, :sender_email, :receiver_email
  validates_email_format_of :sender_email
  validates_length_of :subject, :within => 0..100

  #--- instance methods
  
  # returns sender name from sender instance or instance variable
  def sender_name
    if self.sender
      self.sender.name
    else
      @sender_name
    end
  end

  # returns sender email from sender instance or instance variable
  def sender_email
    if self.sender
      self.sender.email
    else
      @sender_email
    end
  end
  
  def from
    "#{self.sender_name} <#{self.sender_email}>"
  end
  
  # returns name and email as "name <name@test.com>" if available
  def to
    if self.receiver
      self.receiver.name_and_email
    else
      @receiver_email
    end
  end

  # just the email address of the recipient
  def to_email
    if self.receiver
      self.receiver.email
    else
      @receiver_email
    end
  end
  
  # returns a comma delimited string of email receiver or receivers
  def receiver_email
    self.to_email_a.join(", ")
  end

  # returns an array of email receivers that can also be of "name <name@test.com>"
  #
  # e.g.
  #
  #   ["first@test.com", "Adam <second@test.com>"]
  #
  def to_a
    self.to ? self.to.split(',').map(&:strip).compact.uniq : []
  end
  
  # returns a pure array of email receivers
  #
  # e.g. 
  #
  #   ["first@test.com", "adam@test.com"]
  #
  def to_email_a
    self.to ? self.to_email.split(',').map(&:strip).compact.uniq : []
  end
  
  def validate
    # validates each receiver email
    self.to_email_a.each do |address|
      unless address =~ ValidatesEmailFormatOf::Regex
        self.errors.add(:receiver_email, I18n.t("activerecord.errors.messages.email_format"))
        break
      end
    end
  end

  # basic mailer, override in subclasses, e.g. EmailKase
  def deliver
    I18n.switch_locale self.language || Utility.language_code do 
      EmailMailer.deliver_message(self) if self.valid?
    end
  end
  
end
