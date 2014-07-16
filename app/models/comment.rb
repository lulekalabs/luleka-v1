# Class takes care of commenting instances, e.g. kases and responses
# comments are hierarchical
# comments can be rated
class Comment < ActiveRecord::Base

  #--- accessors
  attr_protected :status

  #--- associations
  belongs_to :person, :foreign_key => :sender_id
  belongs_to :sender, :class_name => 'Person', :foreign_key => :sender_id
  belongs_to :receiver, :class_name => 'Person', :foreign_key => :receiver_id
  belongs_to :commentable, :polymorphic => true
  belongs_to :kase, :class_name => 'Kase', :foreign_key => :commentable_id
  belongs_to :response, :class_name => 'Response', :foreign_key => :commentable_id
  has_many :comments, :foreign_key => :parent_id, :dependent => :destroy

  #--- has finder
  named_scope :active, :conditions => {:status => 'active'}
  named_scope :active_or_new_from?, lambda {|person| {
    :conditions => ["comments.status = ? OR (comments.status = ? AND comments.sender_id = ?)", 'active', 'created', person.id]}
  }
  
  #--- mixins
  acts_as_tree :order => 'created_at', :dependent => :destroy
  acts_as_rateable
  can_be_flagged :reasons => [:privacy, :inappropriate, :abuse, :crass_commercialism, :spam]
  
  #--- validations
  validates_presence_of :message
  validates_length_of :message, :within => 5..1000
  validates_presence_of :commentable
  validates_presence_of :sender, :unless => :sender_email?
  validates_presence_of :sender_email, :unless => :sender?
  validates_email_format_of :sender_email, :unless => :sender?

  #--- state machine
  acts_as_state_machine :initial => :created, :column => :status
  state :created
  state :active,  :enter => :do_activate, :after => :after_activate
  state :suspended, :enter => :do_suspend, :exit => :do_unsuspend, :after => :after_activate
  state :deleted, :enter => :do_delete, :after => :after_activate

  event :activate do
    transitions :from => :created, :to => :active, :guard => :can_activate? 
  end
  
  event :suspend do
    transitions :from => [:created, :active], :to => :suspended
  end
  
  event :delete do
    transitions :from => [:created, :active, :suspended], :to => :deleted
  end

  event :unsuspend do
    transitions :from => :suspended, :to => :active, :guard => Proc.new {|u| !u.activated_at.blank?}
    transitions :from => :suspended, :to => :created
  end

  #--- callbacks
  before_create :make_and_send_activation_code
  after_create :update_commentable_comments_count

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
      name.underscore.to_sym
    end
    
    # finds all that have not been published
    def find_all_pending_publication
      find(:all, :conditions => ["comments.status = ? AND comments.published_at < ?", 
        'created', Time.now.utc - 30.days])
    end
    
    # find options for "visible" comments, terms of "einsehbar"
    # resembles "visible?" instance method, returns records for states NOT in:
    #
    #   * created
    #   * suspended
    #   * deleted
    #
    def find_options_for_visible(options={})
      {:conditions => ["comments.status NOT IN (?)", ["created", "suspended", "deleted"]],
        :order => "comments.updated_at DESC"}.merge_finder_options(options)
    end
    
  end
  
  #--- instance methods

  def build_reply(options={})
    self.comments.build(reply_options(options))
  end

  def create_reply(options={})
    if self.repliable?
      reply = self.comments.create(reply_options(options))
      reply.activate! if reply.valid?
      reply
    end
  end

  # returns true if comment can be replied to
  def repliable?(a_person=nil)
    false
  end

  # returns the kase instance
  def kase
    if self.commentable.is_a?(Kase)
      self.commentable
    elsif self.commentable.is_a?(Response)
      self.commentable.kase
    elsif self.comment && self.comment.is_a?(Comment)
      # recursive decent until kase found
      self.comment.kase
    end
  end

  # used to determine user id for flaggable
  def user_id
    self.person.user.id if self.person
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
  
  # returns true if the comment has just been created (:created state) or is
  # not more than 15 minutes "old"
  def editable?
    if new_record?
      true
    else
      (self.created? || self.active?)
    end
  end
  
  # returns the record's language code ('en', 'de', etc.) or if empty
  # the person's default language preference or if no person
  # current language
  def language_code
    self[:language_code] || (self.person ? self.person.default_language : Utility.language_code)
  end
  
  # returns true if a sender email is not nil or blank
  def sender_email?
    !self.sender_email.blank?
  end
  
  # returns true if a person object is assigned
  def sender?
    !!self.sender
  end

  # can the response be published aka activated
  def can_activate?
    self.sender && self.email_match?
  end
  
  # does sender's email and person's email match
  def email_match?
    (!self.sender_email && self.sender?) || (self.sender_email && self.sender && self.sender_email == self.sender.email)
  end
  
  # helper for anonymous attribute
  def anonymous?
    !!self[:anonymous]
  end
  
  protected
  
  def validate
    # activation email does not match person's email
    self.errors.add(:sender_email, I18n.t('activerecord.errors.messages.match_activation') % {
      :sender_email => self.sender_email,
      :registration_email => self.sender.email
    }) if self.sender_email && self.sender && self.sender_email != self.sender.email
  end
  
  # options for create/build_reply
  def reply_options(options={})
    options.merge({:commentable => self.commentable, :sender => self.receiver, :receiver => self.sender})
  end

  # helper for mailer
  def send_new_post_to(role)
    if role && self.respond_to?(role) && recipient = self.send(role)
      I18n.switch_locale recipient.default_language do
        CommentMailer.deliver_new_post(self, role)
      end
    end
  end

  # send all notifications called by callback
  def send_notifications
    send_new_post_to(:sender) if self.sender.notify_on_comment_posted
    send_new_post_to(:receiver) if self.receiver && self.receiver.notify_on_comment_received
  end

  def do_activate
    self.send_notifications unless self.activated_at
    
    self.published_at    = Time.now.utc unless self.activated_at
    self.activated_at    = Time.now.utc
    self.deleted_at      = nil
    self.activation_code = nil
    self.sender_email    = nil
  end
  
  def after_activate
    self.update_commentable_comments_count
  end

  def do_suspend
    self.update_attribute(:suspended_at, Time.now.utc)
  end
  
  def after_suspend
    self.update_commentable_comments_count
  end

  def do_unsuspend
    self.update_attribute(:suspended_at, nil)
  end

  def do_delete
    self.deleted_at = Time.now.utc
  end
  
  def after_delete
    self.update_commentable_comments_count
  end
  
  # add comment count in association as :counter_cache for :polymorphic does not work
  def update_commentable_comments_count
    if self.commentable && self.commentable.class.columns.to_a.map {|a| a.name.to_sym}.include?(:comments_count)
      self.commentable.class.transaction do 
        self.commentable.lock!
        self.commentable.update_attribute(:comments_count,
          self.commentable.comments.count(self.class.find_options_for_visible))
      end
    end
  end
  
  def make_and_send_activation_code
    unless self.sender
      self.activation_code = Digest::SHA1.hexdigest(Time.now.to_s.split(//).sort_by {rand}.join)
      CommentMailer.deliver_activation(self)
    end
  end

  class Commentable < ActiveRecord::Base
    # dummy class for scaffold
  end
  
end
