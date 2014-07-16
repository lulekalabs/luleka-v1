# Inherits from Message
# Manages the status of invitations between people. An invitation
# can be to someone that has not signed up to probono, or to an
# existing user. An invitation to a new user requires at least
# the invitee's first_name, last_name and email. Upon confirmation of 
# the request, the invitee needs to follow the sign up process. 
# If the invitee is an existing user, the confirmation process is
# somewhat straightforward and simply requires accepting or declining
# the request.
class Invitation < Message
  #--- accessors
  attr_accessor :with_voucher
  
  #--- associations
  belongs_to :invitor, :class_name => 'Person', :foreign_key => :sender_id    # former invitor_id
  belongs_to :invitee, :class_name => 'Person', :foreign_key => :receiver_id  # former invitee_id
  belongs_to :voucher

  #--- validations
  validates_presence_of :invitor
  validates_presence_of :email, :if => :has_no_registered_invitee?
  validates_email_format_of :email, :allow_nil => false, :if => :has_no_registered_invitee?
  validates_confirmation_of :email, :if => :has_no_registered_invitee?
  validates_uniqueness_of :email, :message => I18n.t('activerecord.errors.messages.invitation_taken'),
    :scope => :sender_id, :if => :has_no_registered_invitee?

  #--- mixins
  named_scope :pending, :conditions => {:status => 'pending'}
  named_scope :accepted, :conditions => {:status => 'accepted'}
  named_scope :declined, :conditions => {:status => 'declined'}
  named_scope :registered, :conditions => ["receiver_id IS NOT NULL"]
  named_scope :after, lambda {|date_time| {:conditions => ["created_at >= ?", date_time]}}

  #--- state machine
  acts_as_state_machine :initial => :queued, :column => :status
  state :queued
  state :delivered, :enter => :enter_delivered
  state :pending, :enter => :enter_pending
  state :registering
  state :accepted, :enter => :enter_accepted
  state :declined, :enter => :enter_declined

  #--- events
  event :send do
    transitions :from => :queued, :to => :pending, :guard => :has_registered_invitee?
    transitions :from => :queued, :to => :delivered, :guard => :has_no_registered_invitee?
  end
  
  event :remind do
    transitions :from => :pending, :to => :pending, :guard => :has_registered_invitee?
    transitions :from => :delivered, :to => :delivered, :guard => :has_no_registered_invitee?
  end
  
  event :open do
    transitions :from => :delivered, :to => :pending, :guard => :has_registered_invitee?
  end

  event :signup do
    transitions :from => :delivered, :to => :registering
  end

  event :accept do 
    transitions :from => :delivered, :to => :accepted
    transitions :from => :pending, :to => :accepted, :guard => :accept_guard
    transitions :from => :registering, :to => :accepted
  end

  event :decline do 
    transitions :from => :delivered, :to => :declined
    transitions :from => :pending, :to => :declined
  end

  # handles state transition to status "delivered"
  def enter_delivered
    send_invitation_request
    send_invitation_request_confirmation
  end
  
  def enter_pending
    send_invitation_request
    send_invitation_request_confirmation
  end
  
  def enter_accepted
    if has_registered_invitee?
      self.invitee.is_friends_with(self.invitor)
    end
    send_invitation_accepted_confirmation
  end
  
  def enter_declined
    # TODO destroy voucher?
    send_invitation_declined_confirmation
  end
  
  # redeems vouchers if there are any
  def accept_guard
    self.voucher.redeem! if self.with_voucher?
    true
  end
  
  #--- callbacks
  before_create :attach_voucher
  before_validation_on_create :generate_uuid

  #--- notifiers
  
  def send_invitation_request
    if self.has_registered_invitee?
      send_invitation_request_to_existing_user
    else
      send_invitation_request_to_new_user
    end
    # leave these...
    self.update_attribute(:reminded_at, Time.now.utc) if sent_and_not_reminded?
    # ...in order!
    self.update_attribute(:sent_at, Time.now.utc) unless sent?
  end
  
  # mail to invitee for confirming invitation if invitee is an existing user
  def send_invitation_request_to_existing_user
    I18n.switch_locale self.invitee.default_language do
      InvitationMailer.deliver_request_to_existing_user(self)
    end
  end
  
  # mail to invitee for confirming invitation if invitee is an new user
  def send_invitation_request_to_new_user
    I18n.switch_locale self.language || Utility.language_code do
      InvitationMailer.deliver_request_to_new_user(self)
    end
  end
  
  # confirms invitation with mail to invitor
  def send_invitation_request_confirmation
    I18n.switch_locale self.invitor.default_language do
      InvitationMailer.deliver_request_confirmation(self)
    end
  end
  
  def send_invitation_accepted_confirmation
    I18n.switch_locale self.invitor.default_language do
      InvitationMailer.deliver_accepted_confirmation(self)
    end
  end

  def send_invitation_declined_confirmation
    # TODO not sure if we need this?
  end

  #--- class methods
  class << self

    # @person.invitors.pending
    def pending(options={})
      items = find_all_by_status(:delivered, options)
    end

    def registering(options={})
      find_all_by_status(:registering, options)
    end
    
    # returns a translated default invitation text
    # replaces <br/> with \n (LF)
    def default_message(options={})
      I18n.switch_locale options[:language] || Utility.language_code do 
        message = I18n.t('activerecord.errors.messages.invitation_message') % {
          :invitee => options[:invitee_name].blank? ? "Hello".t : "Hello %{invitee_name}".t % {
            :invitee_name => options[:invitee_name]
          },
          :invitor => options[:invitor_name]
        }
        # replace <br/> with LF
        message.gsub!(/<br.?\/>/i, "\n")
        message
      end
    end

    # finds all invitations by status in descending order by which 
    # they were created (latest first)
    def find_all_by_status(status, options={})
      conditions = ["messages.status = '#{status}'"]
      conditions = sanitize_and_merge_conditions(conditions, options.delete(:conditions)) if options[:conditions]
      
      Invitation.find(:all, 
        :select     => "messages.*",
        :conditions => conditions, 
        :limit      => options[:size],
        :offset     => options[:offset],
        :order      => "messages.created_at DESC")
    end

  end
  
  #--- instance methods
  
  # returns a translated default invitation text
  def default_message(options={})
    self.class.default_message({
      :language => self.language,
      :invitee_name => self.to_invitee.casualize_name(true),
      :invitor_name => self.invitor.name
    }.merge(options))
  end
  
  # only if enough vouchers are available and invitor is a partner
  def attach_voucher
    if self.with_voucher? && self.invitor.has_voucher_quota? && self.invitor.partner?
      if self.has_no_registered_invitee? || (self.has_registered_invitee? && !self.invitee.partner?)
        self.create_voucher(
          :consignor => self.invitor,
          :consignee => self.invitee,
          :email => self.to_invitee.email,
          :type => :partner_membership,
          :expires_at => Time.now.utc + 3.months
        )
        self.invitor.decrement_voucher_quota
      end
    end
  end
  
  def validate
    super
    if self.invitor
      # registered invitees
      if self.has_registered_invitee?
        # check me, myself and I?
        self.errors.add_to_base(I18n.t('activerecord.errors.messages.invitation_self_exclusion')) if self.invitor == self.invitee

        # are we friends (contact) already?
        self.errors.add_to_base(I18n.t('activerecord.errors.messages.invitation_exclusion')) if self.invitor.is_friends_with?(self.invitee)
        
        # has invitee already been invited before?
        self.errors.add_to_base("#{self.invitee.name} #{I18n.t('activerecord.errors.messages.invitation_taken')}") if self.is_invitation_of?(self.invitee)
        
        # invitee a partner or ever been one?
        if self.with_voucher? && self.invitor.partner? &&
            (self.invitee.partner? || self.invitee.ever_subscribed_as_partner?)
          self.errors.add(:voucher, I18n.t('activerecord.errors.messages.invitation_partner_exclusion'))
        end
      else
        # unregistered invitees 
        
        # check me, myself and I?
        self.errors.add_to_base(I18n.t('activerecord.errors.messages.invitation_self_exclusion')) if self.invitor.email == self.email
      end
      
      # check if voucher shall be created and if there are any vouchers left?
      if self.with_voucher?
        self.errors.add_to_base(I18n.t('activerecord.errors.messages.invitation_vouchers_taken')) unless self.invitor.has_voucher_quota?
      end
      
      # vouchers an only be attached by partners
      self.errors.add(:voucher, I18n.t('activerecord.errors.messages.invitation_partner_only')) if self.with_voucher? && !self.invitor.partner?
    end
  end

  # figure out 
  def is_invitation_of?(a_new_invitee)
    if self.new_record?
      return true if self.class.find(
        :first,
        :conditions => [
          "sender_id = ? AND receiver_id = ?",
          self.invitor.id, a_new_invitee.id
        ]
      )
    else
      return true if self.class.find(
        :first,
        :conditions => [
          "sender_id = ? AND receiver_id = ? AND id <> ?",
          self.invitor.id, a_new_invitee.id, self.id
        ]
      )
    end
    false
  end

  # returns true if an invitee as person is associated
  def has_registered_invitee?
    return true if self.invitee && self.invitee.active?
    false
  end
  
  # opposite of has_registered_invitee?
  def has_no_registered_invitee?
    !self.has_registered_invitee?
  end
  
  # with voucher setter to prevent "0" or bad values to set to true
  def with_voucher=(flag)
    if flag.is_a?(String)
      @with_voucher = case flag
      when /1/, /true/ then true
      else false
      end
    else
      @with_voucher = flag
    end
  end

  # reads instance variable with_voucher. Returns false by default.
  def with_voucher?
    if self.new_record?
      return true if self.with_voucher
    else
      return !!self.voucher
    end
    false
  end
  
  # Provides the invitee's name to display in the email
  # "Sam Smith (sam@smith.com)"
  def invitee_name
    if self.has_registered_invitee?
      "#{self.invitee.name}"
    else
      self.to_invitee.name_and_email
    end
  end

  # Returns an invitee instance, if a new user has signed up,
  # build a new person from invitation information. This is currently
  # used in notifiers.
  def to_invitee
    if self.has_registered_invitee?
      self.invitee
    else
      Person.new(
        :first_name => self.first_name,
        :last_name => self.last_name,
        :email => self.email
      )
    end
  end

  # send out a reminder to confirm the invitation. a reminder can only be
  # sent once.
  def remind
    if can_remind?
      send_invitation_request if remind!
      return true
    end
    false
  end

  # returns true if a reminder can be sent
  def can_remind?
    (self.next_state_for_event(:remind) ? true : false) && !reminded?
  end

  # returns true if a reminder has been sent once
  def sent?
    self[:sent_at] ? true : false
  end
  
  # returns true if a reminder has been sent once
  def reminded?
    self[:reminded_at] ? true : false
  end
  
  # returns true if the invitation has been sent already but the reminder has not
  def sent_and_not_reminded?
    sent? && !reminded?
  end

  # returns those attributes that relevant for the person
  def invitee_attributes(with_email=false, options={})
    if self.invitee
      {
        :first_name => self.invitee.first_name,
        :last_name => self.invitee.last_name
      }.merge(with_email ? {:email => self.invitee.email} : {}).merge(options)
    else
      {
        :first_name => self.first_name,
        :last_name => self.last_name
      }.merge(with_email ? {:email => self.email} : {}).merge(options)
    end
  end

  protected
  
  # generates a uuid based on the current time
  def generate_uuid
    self[:uuid] ||= Utility.generate_random_uuid
  end

end
