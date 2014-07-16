require 'digest/sha2'
class User < ActiveRecord::Base
  include FacebookUserSupport
  include TwitterUserSupport

  #--- constants
  USERNAME_REGEXP          = /^\s*[a-z0-9_]+$/i
  LOGIN_MIN_CHARACTERS     = 2
  LOGIN_MAX_CHARACTERS     = 40
  EMAIL_MIN_CHARACTERS     = 5
  EMAIL_MAX_CHARACTERS     = 100
  PASSWORD_MIN_CHARACTERS  = 4
  PASSWORD_MAX_CHARACTERS  = 40
  
  #--- accessors
  cattr_accessor :password_deferred
  @@password_deferred = true # true means, we generally allow the user to choose a password later (on activate)
  cattr_accessor :current_user
  @@current_user = nil

  attr_accessor :password
  attr_accessor :encrypted_password  # helper attribute to transmit encrypted password for no HTTPS
  attr_accessor :email_new  # may have to change
  attr_accessor :destroy_confirmation
  attr_accessor :new_password
  attr_accessor :email
  attr_accessor :gender
  attr_accessor :first_name
  attr_accessor :last_name
  attr_writer   :password_required
  
  # prevents a user from submitting a crafted form that bypasses activation
  attr_protected :state, :password_required, :guest

  #--- compositions
  composed_of :tz,
    :class_name => '::ActiveSupport::TimeZone',# 'TZInfo::Timezone',
    :mapping => %w(time_zone name)
  
  #--- associations
  has_and_belongs_to_many :roles
  belongs_to :person, :include => :piggy_bank
  
  #--- validations
  validates_associated :person, :message => '', :unless => :guest?
  validates_presence_of :login, :email
  validates_format_of :login, :with => USERNAME_REGEXP
  validates_presence_of :password, :if => :password_required?
  validates_presence_of :password_confirmation, :if => :password_required?
  validates_length_of :password, :within => PASSWORD_MIN_CHARACTERS..PASSWORD_MAX_CHARACTERS, 
    :if => :password_required?
  validates_confirmation_of :password, 
    :if => :password_required?
  validates_length_of :login, :within => LOGIN_MIN_CHARACTERS..LOGIN_MAX_CHARACTERS
  validates_length_of :email, :within => EMAIL_MIN_CHARACTERS..EMAIL_MAX_CHARACTERS
  validates_uniqueness_of :login, :case_sensitive => false
  validates_email_format_of :email
  validates_presence_of :time_zone, :unless => :guest?
  validates_confirmation_of :new_password, :if => :password_changed?
  validates_presence_of :new_password_confirmation, :if => :password_changed?
  validates_confirmation_of :email
  validates_inclusion_of :language, :in => Utility.active_language_codes
  validates_inclusion_of :currency, :in => Utility.active_currency_codes
  validates_acceptance_of :terms_of_service
  validates_confirmation_of :activation_code, :if => :pending?
  
  #--- mixins
  can_flag
  acts_as_authorized_user
  acts_as_authorizable

  #--- named_scope
  named_scope :passive, :select => "DISTINCT users.*", 
    :conditions => ["users.state IN(?)", ['passive']]
  named_scope :pending, :select => "DISTINCT users.*", 
    :conditions => ["users.state IN(?)", ['pending']]
  named_scope :pre_active, :select => "DISTINCT users.*", 
    :conditions => ["users.state IN(?)", ['passive', 'pending', 'screening']]
  named_scope :active, :select => "DISTINCT users.*", 
    :conditions => ["users.state IN(?)", ['active']]

  #--- state machine
  acts_as_state_machine :initial => :passive
  state :passive
  state :screening, :enter => :do_screening
  state :pending, :enter => :make_activation_code_and_send_confirmation_request
  state :active,  :enter => :do_activate, :after => :after_activate
  state :suspended, :enter => :do_suspend, :exit => :do_unsuspend
  state :deleted, :enter => :do_delete

  event :register do
    transitions :from => :passive, :to => :screening, :guard => Proc.new {|u| Utility.pre_launch?}
    transitions :from => :passive, :to => :pending, :guard => Proc.new {|u| !(u.crypted_password.blank? && u.password.blank?)}
    transitions :from => :passive, :to => :pending, :guard => Proc.new {|u| u.guest? || u.password_deferred?}
  end
  
  event :accept do
    transitions :from => :screening, :to => :pending
  end
  
  event :activate do
    transitions :from => :pending, :to => :active, :guard => :can_activate?
  end
  
  event :suspend do
    transitions :from => [:passive, :pending, :active], :to => :suspended
  end
  
  event :delete do
    transitions :from => [:passive, :pending, :active, :suspended], :to => :deleted
  end

  event :unsuspend do
    transitions :from => :suspended, :to => :active,  :guard => Proc.new {|u| !u.activated_at.blank?}
    transitions :from => :suspended, :to => :pending, :guard => Proc.new {|u| !u.activation_code.blank? && u.activated_at.blank?}
    transitions :from => :suspended, :to => :passive
  end
  
  #--- acls
  allows_display_of :login,     :if => Proc.new {|o| o.accepts_right? :login, User.current_user}
  allows_display_of :email,     :if => :never?

  #--- callbacks
  before_save :encrypt_password, :update_currency_if_necessary
  after_save :save_person_if_necessary
  after_destroy :destroy_person
  
  def after_initialize
    self.build_person(:user => self) unless self.person
    self.email = @email if @email
    self.gender = @gender if @gender
    self.first_name = @first_name if @first_name
    self.last_name = @last_name if @last_name
    self.currency = self.default_currency
    self.language = self.default_language
    self.country = self.default_country
  end

  #--- class methods
  
  class << self
    
    # finds a user by login or email, e.g. used for reset password
    def find_by_login_or_email(login_or_email)
      find(:first, :conditions => ["users.login = ? OR people.email = ?", login_or_email, login_or_email], 
        :include => :person)
    end

    # find first user by email
    def find_by_email(email)
      find(:first, :conditions => ["people.email = ?", email], 
        :include => :person)
    end
    
    # find all user's by email
    def find_all_by_email(email)
      find(:all, :conditions => ["people.email = ?", email], 
        :include => :person)
    end
    
    # authenticates a user by login name and unencrypted password.  returns the user or nil.
    # options:
    #   :trace => true    ->   traces by last user sign_in in field signed_in_at
    def authenticate_by_login(login, password, options={})
      user = find_in_state(:first, :active, :conditions => {:login => login}) # need to get the salt
      if user && user.authenticated?(password)
        user.update_attribute(:signed_in_at, Time.now.utc) if !!options[:trace]
        user
      else
        nil
      end
    end
    alias_method :authenticate, :authenticate_by_login

    # same as authenticate_by_login but authenticates by login or email address
    def authenticate_by_login_or_email(login_or_email, password, options={})
      user = find_in_state(:first, :active, {
        :conditions => ["users.login = ? OR people.email = ?", login_or_email, login_or_email], :include => :person})
      if user && user.authenticated?(password)
        user.update_attribute(:signed_in_at, Time.now.utc) if !!options[:trace]
        user
      else
        nil
      end
    end

    # encrypts some data with the salt.
    def encrypt(password, salt)
      Digest::SHA1.hexdigest("--#{salt}--#{password}--")
    end

    # verifies the given activation code, together with login and password
    # returns the user if valid, nil if not
    def verify(username, password, activation_token)
      if u = User.find_in_state(:first, :pending, :conditions => {:login => username})
        crypted = encrypt(password, u.salt)
        if u.crypted_password == crypted && u.activation_code == activation_token
          u.activate!
          return u
        end
      end
      nil
    end
    
    # changes the user password, given the login, current password and new password + confirmation
    def change_password(username, current_password, new_password, confirm_password)
      if user = authenticate(username, current_password, :record => false)
        user.password = new_password
        user.password_confirmation = confirm_password
        user.new_password = new_password
        user.new_password_confirmation = confirm_password
        user.password_changed!
        user.valid?
        if !user.errors.invalid?(:password) && !user.errors.invalid?(:password_confirmation) &&
            !user.errors.invalid?(:new_password_confirmation)
          user.save(false)
          user.send_change_password
          return user
        end
      end
      nil
    end

    # safely change email address
    def change_email(username, password, current_email, new_email)
      if user = User.authenticate(username, password)
        user.email = new_email
        if user.valid?
          user.person.save
          user.save
          return user
        end
      end
      nil
    end

    # Request for confirmation has not been received, therefore, 
    # user can opt to have it resent. New activation code must 
    # be generated.
    def resend_confirmation_request(login, email)
      if user = User.find_by_login_and_email(login, email)
        user if user.resend_confirmation_request
      end
    end

    def password_deferred?
      !!@@password_deferred
    end
    
    protected 
    
    # finds a user by login and email
    def find_by_login_and_email(login, email)
      find(:first, :conditions => ["login = ? AND email = ?", login, email], :include => :person)
    end
    
  end
  
  #--- notifiers

  # Sends request for activation (RFA)
  def send_confirmation_request
    I18n.switch_locale self.default_language || Utility.language_code do 
      UserMailer.deliver_confirm_account(self)
    end
  end

  # creates a new activation code and sends the confirmation request again
  def resend_confirmation_request
    if self.pending?
      self.make_activation_code_and_send_confirmation_request(true)
      return true
    end
    false
  end
  
  # sets the flag that the password is about to change. Used for
  # validations
  # Sends out newly generated password
  def send_change_password
    I18n.switch_locale self.default_language || Utility.language_code do 
      UserMailer.deliver_change_password(self)
    end
  end

  # Sends out message to confirm that email address has changed
  def send_change_email
    I18n.switch_locale self.default_language || Utility.language_code do 
      UserMailer.deliver_change_email(self)
    end
  end

  # Sends out newly generated password
  def send_reset_password
    I18n.switch_locale self.default_language || Utility.language_code do 
      UserMailer.deliver_reset_password(self)
    end
  end

  # sends confirmation to be accepted in beta program
  def send_beta_activated
    if Utility.pre_launch?
      I18n.switch_locale self.default_language || Utility.language_code do 
        BetaUserMailer.deliver_activated(self)
      end
    end
  end

  # send registered for beta mail
  def send_beta_registered
    if Utility.pre_launch?
      I18n.switch_locale self.default_language || Utility.language_code do 
        BetaUserMailer.deliver_registered(self)
      end
    end
  end

  #--- instance methods
  
  # overrides default to_param to allow for permalinks
  def to_param
    "#{login}"
  end
  
  # email getter. since email is not stored with the user, fetch it from the associated contact
  def email
    return self.person.email if self.person
    nil
  end

  # email setter
  def email=(an_email)
    @email = an_email
    self.person.email = an_email if self.person
  end

  # gender getter
  def gender
    self.person ? self.person.gender : nil
  end

  # gender setter
  def gender=(value)
    @gender = value
    self.person.gender = value if self.person
  end

  # first_name getter
  def first_name
    self.person ? self.person.first_name : nil
  end

  # first_name setter
  def first_name=(value)
    @first_name = value
    self.person.first_name = value if self.person
  end

  # last_name getter
  def last_name
    self.person ? self.person.last_name : nil
  end

  # last_name setter
  def last_name=(value)
    @last_name = value
    self.person.last_name = value if self.person
  end

  # returns the login name and email 
  def name
    self.person.name if self.person
  end
  
  # Encrypts the password with the user salt
  def encrypt(password)
    self.class.encrypt(password, salt)
  end

  def authenticated?(password)
    crypted_password == encrypt(password)
  end

  def remember_token?
    remember_token_expires_at && Time.now.utc < remember_token_expires_at 
  end

  # These create and unset the fields required for remembering users between browser closes
  def remember_me
    remember_me_for 2.weeks
  end

  def remember_me_for(time)
    remember_me_until time.from_now.utc
  end

  def remember_me_until(time)
    self.remember_token_expires_at = time
    self.remember_token            = encrypt("#{email}--#{remember_token_expires_at}")
    save(false)
  end

  def forget_me
    self.remember_token_expires_at = nil
    self.remember_token            = nil
    save(false)
  end

  # Returns true if the user has just been activated.
  def recently_activated?
    @activated
  end
  
  def password_changed!
    @change_password = true
  end

  def password_changed?
    !!@change_password
  end
  
  # Generate time salt for security token
  def time_salt(date)
    date.year.to_s + date.month.to_s + date.day.to_s + date.hour.to_s + date.min.to_s + date.sec.to_s
  end
  
  # returns time zone
  def time_zone 
    self[:time_zone]
  end
  
  # Converts from the user set time zone and returns UTC time
  def user2utc(user_time)
    self.tz.dup.local_to_utc(user_time) rescue user_time # unadjust
  end
  
  # Expects a UTC time and converts it into the user's set time zones time
  def utc2user(utc_time)
    self.tz.dup.utc_to_local(utc_time) rescue utc_time # adjust
  end

  # standard validation method
  def validate
    validate_uniqueness_of_email
    
    # valid currency?
    unless Utility.active_currency_codes.find {|c| c == self.currency}
      self.errors.add(:currency, :invalid)
    end
    
    # change currency?
    if self.currency_changed? && !self.can_change_currency? && self.currency != self.person.piggy_bank.currency
      self.errors.add(:currency, :cannot_change)
    end
  end

  # returns true if currency column has changed
  def currency_changed?
    self.changes.symbolize_keys.keys.include?(:currency)
  end
    
  # is user allowed to change currency on new user or piggy bank is virgin
  def can_change_currency?
    if new_record?
      true
    else
      if self.person 
        if self.person.piggy_bank
          self.person.piggy_bank.virgin?
        else
          true
        end
      else
        true
      end
    end
  end

  # returns true if a activation code was provided for confirmation
  def activation_code_confirmation?
    self.respond_to?(:activation_code_confirmation) && self.send(:activation_code_confirmation) ? true : false
  end
  
  # assigns a time zone from a browser offset, so we don't need the user to select one
  # Note: the offset is understood as the javascript Date.now().getTimezoneOffset()
  def tz_offset_from_javascript=(offset)
    if zone = ::ActiveSupport::TimeZone[-offset.to_i * 60]
      self.tz = zone
    end
  end
  
  # getter to return javascript tz offset
  def tz_offset_from_javascript
    self.tz.utc_offset / -60 if self.tz
  end

  # set to true if password can be assigned afterwards
  def password_deferred?
    self.class.password_deferred?
  end

  # creates a reset code 
  def create_reset_code
    @reset = true
    self.attributes = {:reset_code => Digest::SHA1.hexdigest(Time.now.to_s.split(//).sort_by {rand}.join)}
    self.send_reset_password if save(false)
  end 

  # returns true if recently reset
  def recently_reset?
    @reset
  end 
  
  # removes the reset code again
  def delete_reset_code
    self.attributes = {:reset_code => nil}
    save(false)
  end
  
  # makes sure that password validation is required
  def password_required!
    self.password_required = true
  end

  # is this user account linked to any external accounts
  def linked_user?
    self.facebook_user? || self.twitter_user?
  end

  # setter to force this user a guest user
  def guest!
    self.guest = true
  end

  # setter to force this user not a guest user (see users_controller/update)
  def not_guest!
    self.guest = false
  end
  
  # returns true for guest users, or those which only casually sign up 
  # right now, just providing login and email
  def guest?
    !!self.guest
  end

  #--- locale settings
  
  # returns user locale, not necessary full locale, e.g. :en, or :"en-US"
  def locale
    result = []
    result << self.language
    result << self.country
    result.compact.reject(&:blank?).join("-").to_sym
  end
  
  # sets user locale as full locale language or country portions, e.g. :'en-US', :"de-DE", :"en"
  def locale=(value)
    if full_locale = Utility.full_locale(value)
      self.language = I18n.locale_language(full_locale)
      self.country = I18n.locale_country(full_locale)
    end
    full_locale
  end

  # returns a full locale or substitutes the missing locale information from active locales
  #
  # e.g.
  #
  #   :en -> :en-US
  #   
  #
  def default_locale
    Utility.full_locale(self.locale) || :"en-US"
  end
  
  #--- language settings
  
  # language getter
  def language
    self[:language].to_s.downcase if self[:language]
  end
  alias_method :language_code, :language

  # language setter
  def language=(value)
    self[:language] = value.to_s.downcase if value
  end
  alias_method :language_code=, :language=

  # returns db attribute and downcase default language
  def default_language
    # Note: leave self[:language], not self.language...trust me!
    self[:language] || Utility.language_code
  end

  #--- country settings

  # country getter
  def country
    self[:country].to_s.upcase if self[:country]
  end
  alias_method :country_code, :country

  # country setter
  def country=(value)
    self[:country] = value.to_s.upcase if value
  end
  alias_method :country_code=, :country=

  # returns db attribute and downcase default country
  def default_country
    # Note: leave self[:country], not self.country...trust me!
    self[:country] || Utility.country_code
  end
  
  #--- currency settings

  # returns content from currency column or default currency code, e.g. "USD"
  def default_currency
    self[:currency] || Utility.active_currency_codes.find {|c| c == Utility.currency_code} || "USD"
  end

  # returns true if associated person is valid?
  # see in users activation, we need to check if the person is complete, without validation
  # skips uniqueness validation by default
  def valid_person?(skip_uniqueness=true)
    result = false
    if self.person
      record = self.person.clone
      record.skip_uniqueness_validation! if skip_uniqueness
      result = record.valid?
    end
    result
  end

  protected

  # used in state machine
  def can_activate?
    !self.guest?
  end
  
  # validates if the user contact default email is unique within the realm 
  # of the organization if present
  def validate_uniqueness_of_email
    if self.person && !self.errors.invalid?(:email) && self.person.errors.invalid?(:email)
      errors.add :email, self.person.errors.on(:email)
    end
  end

  # before filter 
  def encrypt_password
    return if password.blank?
    self.salt = Digest::SHA1.hexdigest("--#{Time.now.to_s}--#{login}--") if new_record?
    self.crypted_password = encrypt(password)
  end

  # tells user to validate password and confirmation
  # you can also manually set password required
  # 
  # e.g.
  #
  #   @user.password_required = true
  #   @user.password_required!
  #   @user.valid?  ->  validates password/confirmation
  #
  def password_required?
    return false if self.password_deferred? && self.passive?
    return true if !!@password_required
    return false if self.guest?
    (crypted_password.blank? || !password.blank?)
  end
  
  def make_activation_code_and_send_confirmation_request(save_activation_code=false)
    self.deleted_at = nil
    self.activation_code = Digest::SHA1.hexdigest(Time.now.to_s.split(//).sort_by {rand}.join)
    self.update_attribute(:activation_code, self.activation_code) if save_activation_code
    
    self.send_beta_activated if Utility.pre_launch?
    self.send_confirmation_request
  end
  
  def do_delete
    self.deleted_at = Time.now.utc
  end

  def do_activate
    @activated = true
    self.activated_at = Time.now.utc
    self.deleted_at = self.activation_code = nil
  end

  # after activate state machine callback
  def after_activate
    # after the user has been activted, the person is activated
    # Note: must not be in do_activate
    self.person.activate!
  
    # assign all pending and matching kases with this user's email address
    Kase.created.find_all_by_sender_email(self.email).each do |kase|
      kase.person = self.person and kase.activate!
    end
  end
  
  def do_suspend
    self.update_attribute(:suspended_at, Time.now.utc)
  end
  
  def do_unsuspend
    self.update_attribute(:suspended_at, nil)
  end
  
  def do_screening
    self.send_beta_registered
  end
  
  def save_person_if_necessary
    self.person.save(false) if self.person && self.person.changed?
  end
  
  # used in before save to change person's currency if possible
  def update_currency_if_necessary
    if self.currency_changed? && self.can_change_currency?
      if self.person && self.person.piggy_bank && self.currency != self.person.piggy_bank.currency
        self.person.piggy_bank.update_attribute(:currency, self.currency) 
      end
    end
  end
  
  def destroy_person
    self.person.destroy if self.person && !self.person.new_record?
  end
  
end
