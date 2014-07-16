# Responses are collections of answers to a kases, like tp problems and questions.
# They can be accepted by the kase owner (or potentially others) to be "credible"
class Response < ActiveRecord::Base
  include InlineAuthenticationBase

  #--- associations
  belongs_to :kase
  belongs_to :person
  belongs_to :severity
  
  has_many :assets, :as => :assetable, :dependent => :destroy
  has_many :comments, :as => :commentable, :dependent => :destroy
  has_many :clarifications, :as => :commentable, :dependent => :destroy,
    :order => 'parent_id ASC, created_at ASC'
  has_many :clarification_requests, :as => :commentable,
    :order => 'parent_id ASC, created_at ASC'
  has_many :clarification_responses, :as => :commentable,
    :order => 'parent_id ASC, created_at ASC'

  #--- has finder
  named_scope :active, :conditions => ["responses.status = ?", 'active']
  named_scope :accepted, :conditions => ["responses.status = ?", 'accepted']
  named_scope :active_or_new_from?, lambda {|person| {
    :conditions => ["responses.status = ? OR (responses.status = ? AND responses.person_id = ?)", 'active', 'created',
      person.id]}}

  #--- mixins
  can_be_flagged :reasons => [:privacy, :inappropriate, :abuse, :crass_commercialism, :spam]
  acts_as_taggable :emotions, :filter_class => 'BadWord'
  acts_as_voteable
  acts_as_rateable :average => false

  #--- validations
  validates_presence_of :kase
  validates_presence_of :person, :unless => :sender_email?
  validates_presence_of :description
  validates_length_of :description, :within => 15..2000

  validates_presence_of :sender_email, :unless => :person?
  validates_email_format_of :sender_email, :unless => :person?
  
  #--- state machine
  acts_as_state_machine :initial => :created, :column => :status
  state :created
  state :active, :enter => :do_activate, :after => :after_activate
  state :accepted, :enter => :do_accepted, :after => :after_accepted
  state :suspended, :enter => :do_suspend, :exit => :do_unsuspend, :after => :after_suspend
  state :deleted, :enter => :do_delete, :after => :after_delete

  event :activate do
    transitions :from => :created, :to => :active, :guard => :can_activate? 
  end

  event :accept do
    transitions :from => :active, :to => :accepted, :guard => :can_accept?
  end

  event :reject do
    transitions :from => :accepted, :to => :active
  end
  
  event :suspend do
    transitions :from => [:created, :active, :accepted], :to => :suspended
  end
  
  event :delete do
    transitions :from => [:created, :active, :accepted, :suspended], :to => :deleted
  end

  event :unsuspend do
    transitions :from => :suspended, :to => :accepted, :guard => Proc.new {|u| !u.activated_at.blank? && !u.accepted_at.blank?}
    transitions :from => :suspended, :to => :active, :guard => Proc.new {|u| !u.activated_at.blank?}
    transitions :from => :suspended, :to => :created
  end

  #--- named scopes
  named_scope :active, :conditions => ["responses.status IN (?)", ["active"]]
  named_scope :accepted, :conditions => ["responses.status IN (?)", ["accepted"]]
  named_scope :visible, :conditions => ["responses.status NOT IN (?)", ["created", "suspended", "deleted"]]

  #--- callbacks
  before_create :create_and_send_activation_code
  after_create :update_associated_count

  #--- class methods
  class << self
    
    # returns all param_ids as array
    #
    # e.g.
    #
    #   [:question_id, :problem_id, :praise_id, :idea_id]
    #
    def subclass_param_ids
      subclasses.map {|k| "#{k.name.underscore}_id"}.map(&:to_sym)
    end
    
    # returns self and subclass param_ids
    def self_and_subclass_param_ids
      subclass_param_ids.insert(0, self_param_id)
    end
    
    # returns the param id
    def self_param_id
      "#{name.underscore}_id".to_sym
    end
    
    def kind
      :response
    end
    
    def find_options_for_popular(options={})
      {
        :conditions => ["responses.status NOT IN (?)", ["deleted", "suspended"]],
        :order => "responses.votes_sum DESC"
      }.merge_finder_options(options)
    end
    
    # find options for "visible" responses, terms of "einsehbar"
    # resembles "visible?" instance method, returns records for states NOT in:
    #
    #   * created
    #   * suspended
    #   * deleted
    #
    def find_options_for_visible(options={})
      {:conditions => ["responses.status NOT IN (?)", ["created", "suspended", "deleted"]],
        :order => "responses.updated_at DESC"}.merge_finder_options(options)
    end
    
    # finds all that have not been published
    def find_all_pending_publication
      find(:all, :conditions => ["responses.status = ? AND responses.published_at < ?", 
        'created', Time.now.utc - 30.days])
    end
    
  end
  
  #--- instance methods

  def kind
    self.class.kind
  end
  
  # returns true if this comment is NOT in either of
  # in terms of "einsehbar"
  #
  #   * created
  #   * suspended
  #   * deleted
  #
  def visible?
    !(self.created? || self.suspended? || self.deleted?)
  end

  # returns true if this response can be accepted in general
  # response is acceptable if all of the below are true: 
  #
  #   * existing record (not new)?
  #   * is the response active (current response state)?
  #   * is the kase active?
  #
  def can_accept?
    !self.new_record? && self.active? && !!self.kase && self.kase.active?
  end

  # returns true if this user can be accepted by a given person
  #
  #   * generally can be accepted 
  #   * either, kase offers one and only one reward
  #   * or, kase does not offer a reward
  #   * but, given accepting person is equal to the kase owner
  #
  def can_be_accepted_by?(acceptor)
    self.can_accept? && self.kase.person == acceptor &&
      (self.kase.offers_reward? ? self.kase.owner_only_offers_reward? : true)
  end

  # returns true if given person can accept this response, when:
  #
  #   * is the response can_accept?
  #   * is a "acceptor" (current user's person) given?
  #   * does the response kase have an associated person?
  #   * does the associated kase have an associated person?
  #   * is the kase owner not the responder
  #   * if the kase offers a reward, is the kase owner and responder different?
  #   * is someone working on this case already (is kase assigned to someone)?
  #
  # obsolete!
  def acceptable_by?(acceptor)
    self.can_accept? &&
      !!acceptor && !!self.person && !!self.kase.person && acceptor == self.kase.person &&
        (self.kase.offers_reward? ? acceptor != self.kase.person : true)
  end
  
  # builds a comment
  #
  # e.g.
  #
  #   c = build_comment(sender, :message => "I don't understand...")
  #   c.activate!
  #
  def build_comment(sender, options={})
    self.comments.build(comment_options(sender, options)) if allows_comment?(sender)
  end
  
  # creates a comment on this kase
  def create_comment(sender, options={})
    comment = nil
    if allows_comment?(sender)
      comment = self.comments.create(comment_options(sender, options))
      comment.activate! if comment.valid?
    end
    comment
  end

  # options for create/build comment
  def comment_options(sender, options={})
    options.merge({:sender => sender, :receiver => self.person, :commentable => self})
  end

  # returns true if
  #
  #   * response is active or accepted
  #   * kase discussion type is open
  #
  def allows_comment?(a_person=nil)
    (self.active? || self.accepted?)
  end

  # ensure we return valid number for comments count
  def comments_count
    self[:comments_count] || 0
  end
  
  # builds a clarification request to this kase's owner from the person you supply
  # the request can then be replied to using the request's instance's build_reply
  # method.
  #
  # e.g.
  #
  #   c = create_clarification(sender, :message => "I don't understand...")
  #   c.activate!
  #
  def build_clarification_request(sender, options={})
    self.clarifications.build(clarification_options(sender, options)) if self.allows_clarification_request?(sender)
  end
  
  # Creates a clarification request
  def create_clarification_request(sender, options={})
    if self.allows_clarification_request?(sender)
      request = self.clarifications.create(clarification_options(sender, options))
      if request.valid?
        request.activate!
        @pending_clarification_request_cache = nil
      end
      request
    end
  end
  
  # builds clarification response
  def build_clarification_response(sender, options={})
    if self.allows_clarification_response?(sender) && request = self.pending_clarification_request
      request.build_reply(options)
    end
  end

  # create clarification response
  def create_clarification_response(sender, options={})
    if response = self.build_clarification_response(sender, options)
      if response.save
        @pending_clarification_request_cache = nil
        response.activate!
      end
    end
    response
  end
  
  # options for create/build clarification
  def clarification_options(sender, options={})
    options.merge({:type => :clarification_request, :sender => sender, :receiver => self.person, 
      :clarifiable => self})
  end

  # returns true if
  #
  #   * not commentable
  #   * person to test is same as kase owner (not the same as response owner)
  #   * open and no pending clarification requests
  #
  def allows_clarification_request?(a_person=nil)
    self.allows_comment?(a_person) && self.person != a_person &&
    self.kase.open? && !self.pending_clarification_requests?
  end
  
  # Returns true if a request exists, the person is the case owner, etc.
  def allows_clarification_response?(a_person)
    self.active? && a_person == self.person && self.pending_clarification_requests?
  end
  
  # returns the latest pending clarification request
  def pending_clarification_request
    @pending_clarification_request_cache || @pending_clarification_request_cache = if self.pending_clarification_requests?
      self.clarification_requests.active.find(:all, :order => "id DESC, created_at DESC", :limit => 1).first
    else
      nil
    end
  end
  
  # Checks if there is a pending clarification request
  def pending_clarification_requests?
    self.clarification_requests_count > self.clarification_responses_count
  end
  
  # returns true if the kase is has been just created (:new state) and
  # not more than 15 minutes have passed
  def editable?(attribute=nil)
    return true
    if new_record?
      true
    else
      (self.created? || self.active?) && self.kase.active?
    end
  end
  
  # returns kase owner instance
  def receiver
    self.kase.person if self.kase
  end

  # used to determine user id for flaggable
  def user_id
    self.person.user.id if self.person
  end
  
  # returns the record's language code ('en', 'de', etc.) or if empty
  # the person's default language preference or if no person
  # current language
  def language_code
    self[:language_code] || (self.person ? self.person.default_language : Utility.language_code)
  end
  
  # validates only allows response portion and returns true if response is allowed,
  # the rest of the response may still be invalid!
  def allowed?
    errors_count = self.errors.count
    self.validate_allows_response
    errors_count == self.errors.count
  end
  
  # returns true if a sender email is not nil or blank
  def sender_email?
    !self.sender_email.blank?
  end
  
  # returns true if a person object is assigned
  def person?
    !!self.person
  end

  # can the response be published aka activated
  def can_activate?
    self.person && self.email_match?
  end

  # does sender's email and person's email match
  def email_match?
    (!self.sender_email && !!self.person) || (self.sender_email && self.person && self.sender_email == self.person.email)
  end
  
  # update all associated counter caches
  def update_associated_count
    self.update_kase_responses_count
    self.update_person_responses_count
  end
  
  # override from acts_as_voteable to update the person's received votes cache
  def update_voter_cache(voter, sweep_cache=false)
    voter.update_received_votes_cache if voter
  end
  
  def repute_vote_up(voter)
    Reputation.handle(self, :vote_up, self.person, :sender => voter, :tier => self.kase.tier)
  end

  def cancel_repute_vote_up(voter)
    Reputation.cancel(self, :vote_up, self.person, :sender => voter, :tier => self.kase.tier)
  end

  def repute_vote_down(voter)
    Reputation.handle(self, :vote_down, self.person, :sender => voter, :validate_sender => false, :tier => self.kase.tier)
  end

  def cancel_repute_vote_down(voter)
    Reputation.cancel(self, :vote_down, self.person, :sender => voter, :tier => self.kase.tier)
  end

  def repute_accept
    Reputation.handle(self, :accept_response, self.person, :tier => self.kase.tier)
  end

  def cancel_repute_accept
    Reputation.cancel(self, :accept_response, self.person, :tier => self.kase.tier)
  end
  
  # helper for anonymous attribute
  def anonymous?
    !!self[:anonymous]
  end
  
  protected

  # validates if thise response is allowed in terms of kase status and offer audience type
  def validate_allows_response
    if self.kase
      # self.errors.add(:kase, "is %{status}".t % {:status => self.kase.current_state_t}) unless self.kase.active?
      # self.errors.add(:kase, "is not open".t) unless self.kase.open?
    
      if self.person 
        if self.kase.offers_reward?

          # only disallow rewarded self answers
          self.errors.add(:base, "You cannot respond to your own rewarded %{type}".t % {:type => self.kase.class.human_name}) unless self.person != self.kase.person

        end
      end
    end
  end
  
  def validate
    self.validate_allows_response
    
    # activation email does not match person's email
    self.errors.add(:sender_email, I18n.t('activerecord.errors.messages.match_activation') % {
      :sender_email => self.sender_email,
      :registration_email => self.person.email
    }) if self.sender_email && self.person && self.sender_email != self.person.email
  end

  # creates delivery for role
  def send_new_post_to(role)
    ResponseMailer.deliver_new_post(self, role)
  end

  # send all notifications called by callback
  def send_notifications
    send_new_post_to(:person) if self.person.notify_on_response_posted
    send_new_post_to(:receiver) if self.receiver && self.receiver.notify_on_response_received
  end

  def do_activate
    # keep this, so it only sends once
    self.send_notifications unless self.activated_at

    self.published_at    = Time.now.utc unless self.activated_at
    self.activated_at    = Time.now.utc
    self.deleted_at      = nil
    self.accepted_at     = nil
    self.activation_code = nil
    self.sender_email    = nil
  end
  
  def after_activate
    self.update_associated_count
  end

  def do_suspend
    self.update_attribute(:suspended_at, Time.now.utc)
    self.update_associated_count
  end

  def after_suspend
    self.update_associated_count
  end
  
  def do_unsuspend
    self.update_attribute(:suspended_at, nil)
  end

  def do_delete
    self.deleted_at = Time.now.utc
  end
  
  def after_delete
    self.update_associated_count
  end

  def do_accepted
    self.accepted_at ||= Time.now.utc
    self.kase.solve!
  end
  
  # after response is accepted, we want to make sure that rewards are cashed
  # the reward cash! method takes care that reward receiver is the accepted reward
  def after_accepted
    # repute points
    self.repute_accept
    
    # cash rewards
    if self.kase && self.kase.offers_reward?
      self.kase.rewards.active.each do |reward|
        reward.cash!
      end
    end
  end

  # update responses count in association as we have to count only "visible" responses
  def update_kase_responses_count
    if self.kase && self.kase.class.columns.to_a.map {|a| a.name.to_sym}.include?(:responses_count)
      self.kase.class.transaction do 
        self.kase.lock!
        self.kase.update_attribute(:responses_count, 
          self.kase.responses.count(self.class.find_options_for_visible))
      end
    end
  end

  # update responses_count in person association. we only count "visible" responses
  def update_person_responses_count
    if self.person
      ua = {}
      ua.merge!(:responses_count => self.person.responses_count(true)) if self.person.class.responses_count_column?
      unless ua.empty?
        self.person.class.transaction do 
          self.person.lock!
          self.person.update_attributes(ua)
        end
      end
    end
  end

  def create_and_send_activation_code
    unless self.person
      self.activation_code = Digest::SHA1.hexdigest(Time.now.to_s.split(//).sort_by {rand}.join)
      ResponseMailer.deliver_activation(self)
    end
  end

end
