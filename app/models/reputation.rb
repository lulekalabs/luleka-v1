# Holds information about reputation thresholds and helper methods to allocated reputation points and 
# Piggy Bank account funds
class Reputation < ActiveRecord::Base

  attr_writer :validate_threshold
  attr_accessor :validate_self
  attr_protected :status
  
  #--- assocations
  belongs_to :sender, :foreign_key => :sender_id, :class_name => "Person"
  belongs_to :receiver, :foreign_key => :receiver_id, :class_name => "Person"
  belongs_to :reputable, :polymorphic => true
  belongs_to :tier, :foreign_key => :tier_id

  #--- validations
  validates_presence_of :reputable
  validates_presence_of :receiver 
  validates_presence_of :action
  validates_presence_of :points
  
  #--- named_scope
  named_scope :active, :conditions => ["reputations.status IN (?)", ['active']]
  named_scope :cached, :conditions => ["reputations.status IN (?)", ['cached']]
  named_scope :visible, :conditions => ["reputations.status NOT IN (?)", ['created', 'closed']]

  #--- state machine
  acts_as_state_machine :initial => :created, :column => :status
  state :created
  state :active, :enter => :do_activate, :after => :after_activate
  state :closed, :enter => :do_close, :after => :after_closed

  event :activate do
    transitions :from => :created, :to => :active
  end

  event :cancel do
    transitions :from => :active, :to => :closed
  end

  #--- callbacks
  after_destroy :update_receiver_reputation_points
  
  #--- class methods

  class << self

    # Allocates the appropriate reputation amount to the receiver according to action
    # Sometimes actions like, voting down, do have a cost associated with it, i.e. 
    # deduct one reputation point.
    #
    # Also taken into account is that reputation can be accumulated by tier if the :tier
    # optional parameters is provided with a tier instance.
    #
    # E.g. 
    #
    #   Reputation.handle(Response, :vote_up, voter, :sender => self.person)
    #   Reputation.handle(Response, :vote_up, voter, :sender => self.person, :tier => @tier)
    #
    def handle(reputable, action, receiver, options={})
      result = nil
      options.symbolize_keys!
      sender = options.delete(:sender)
      tier = options.delete(:tier)
      
      # adds receiver's reputation
      if receiver_points = find_reputation_points(reputable, :receiver, action, tier)
        result = Reputation.create(:reputable => reputable, :receiver => receiver, :sender => sender,
          :action => "#{action}", :points => receiver_points, :tier => tier && tier.parent ? tier.parent : tier,
            :validate_self => options[:validate_self].is_a?(FalseClass) ? false : true)
        result.activate! if result.valid?
      end
      # adds sender's reputation if defined
      if sender && result && result.success? &&
          (sender_points = find_reputation_points(reputable, :sender, action, tier))
        result = Reputation.create(:reputable => reputable, :receiver => sender, :sender => receiver,
          :action => "#{action}", :points => sender_points, :tier => tier && tier.parent ? tier.parent : tier,
            :validate_threshold => options[:validate_sender].is_a?(FalseClass) ? false : true)
        result.activate! if result.valid?
      end
      result
    end
    
    # cancels (undos) previously allocated reputation with the given criteria
    def cancel(reputable, action, receiver, options={})
      result = nil
      options.symbolize_keys!
      sender = options.delete(:sender)
      tier = options.delete(:tier)
      # adds receiver's reputation
      if receiver_points = find_reputation_points(reputable, :receiver, action, tier)
        reputation = find_for_cancel(reputable, action, receiver, receiver_points, tier)
        reputation.cancel! if reputation
        result = reputation
      end
      if sender && (sender_points = find_reputation_points(reputable, :sender, action, tier))
        reputation = find_for_cancel(reputable, action, sender, sender_points, tier)
        reputation.cancel! if reputation
        result = reputation
      end
      result
    end
    
    # used to sum up reputation count
    def find_options_for_visible(options={})
      {:conditions => ["reputations.status IN (?)", ['active', 'cashed']]}.merge_finder_options(options)
    end
    
    # finds the reputation instance which is going to be canceled
    def find_for_cancel(reputable, action, receiver, points, tier=nil)
      conditions = unless tier
        ["reputations.status = ? AND reputations.reputable_id = ? AND reputations.reputable_type = ? AND reputations.action = ? AND reputations.receiver_id = ? AND reputations.points = ?", 
          'active', reputable.id, reputable.class.base_class.name, action.to_s, receiver.id, points]
      else
        tier = tier.parent ? tier.parent : tier
        ["reputations.status = ? AND reputations.reputable_id = ? AND reputations.reputable_type = ? AND reputations.action = ? AND reputations.receiver_id = ? AND reputations.points = ? AND reputations.tier_id = ?", 
          'active', reputable.id, reputable.class.base_class.name, action.to_s, receiver.id, points, tier.id]
      end
      result = find(:all, 
        :conditions => conditions,
          :order => "activated_at DESC, created_at DESC",
            :limit => 1)
      result.first unless result.empty?
    end
    
    protected

    # dummy stub to get reputation reward for action from ReputationReward class
    def find_reputation_points(reputable, destination, action, tier=nil)
      ReputationReward.action_points(reputable, destination, action, tier=nil)
    end
    
  end
  
  #--- instance methods
  
  def validate_threshold?
    @validate_threshold.is_a?(FalseClass) ? false : true
  end

  # by default validate self is true, meaning that sender cannot be receiver
  def validate_self?
    @validate_self.is_a?(FalseClass) ? false : true
  end
  
  def success?
    self.valid? && !self.new_record?
  end
  
  def message
    self.errors.on(:action) ? self.errors.full_messages.to_s : self.threshold.message
  end

  # returns a Reputation::Threshold instance and validates based on self action and sender
  def threshold
    @threshold ||= Reputation::Threshold.lookup(self.action, self.sender, :tier => self.tier)
  end
  
  # make sure we convert symbol into string for database
  def action=(value)
    self[:action] = value.to_s if value
  end
  
  # return action value as symbol, e.g. :vote_up
  def action
    self[:action].to_sym if self[:action]
  end
  
  protected
  
  def validate
    # validate self
    if self.validate_self? && self.sender == self.receiver
      self.errors.add(:action, :self_invalid) # :action => Reputation.human_attribute_name(self.action)
    else
      # validate threshold
      if self.sender && self.validate_threshold? && !self.closed? && self.threshold.action_defined?
        self.errors.add(:base, :invalid) unless self.threshold.success?
      end
    end
  end
  
  def do_activate
    self.activated_at = Time.now.utc
  end
  
  def after_activate
    self.update_receiver_reputation_points
  end
  
  def do_close
    self.closed_at = Time.now.utc
  end
  
  def after_closed
    self.update_receiver_reputation_points
  end
  
  # update reputations count in association as we have to sum only "visible" or "cashed" rewards
  def update_receiver_reputation_points
    if self.receiver && self.receiver.class.columns.to_a.map {|a| a.name.to_sym}.include?(:reputation_points)
      self.receiver.clear_reputation_points_cache
      self.receiver.class.transaction do 
        self.receiver.lock!
        self.receiver.update_attribute(:reputation_points, 
          self.receiver.reputations.sum("points", self.class.find_options_for_visible))
      end
    end
  end

  #--- in-class classes
  
  # Table-less model
  class Threshold < ActiveRecord::Base
    attr_accessor :action
    attr_accessor :sender
    attr_accessor :tier
    attr_accessor :validate_sender
    
    validates_presence_of :action
    validates_presence_of :sender
    
    class << self
  
      # Finds a reputation threshold based on action and sender
      # 
      # E.g.
      #
      #   Reputation::Threshold.lookup(:vote_up, @sender)
      #   Reputation::Threshold.lookup(:vote_up, @sender, :tier => @tier)
      #  
      def lookup(action, sender, options={})
        tier = options.delete(:tier)
        result = Reputation::Threshold.new(options.merge({:action => action, :sender => sender, :tier => tier,
          :validate_sender => options[:validate_sender].is_a?(FalseClass) ? false : true}))
        result.valid?
        result
      end
      
      # Finds reputation threshold by one or many actions and returns true if at least one is valid,
      # otherwise false
      #
      # E.g.
      #
      #   Reputation::Threshold.valid?([:moderate, :edit_post], @sender)
      #
      def valid?(actions, sender, options={})
        actions = [actions].flatten
        actions.each do |action|
          result = lookup(action, sender, options)
          return true if result && result.success?
        end
        false
      end

      # stuff below makes sure the model validation works without DB table
      def columns
        @columns ||= [];
      end

      def column(name, sql_type = nil, default = nil, null = true)
        columns << ActiveRecord::ConnectionAdapters::Column.new(name.to_s, default,
        sql_type.to_s, null)
      end

    end
    
    #--- instance methods

    def success?
      self.valid?
    end
    
    def message
      self.errors.on(:base)
    end
    
    # Override the save method to prevent exceptions.
    def save(validate = true)
      validate ? valid? : true
    end

    # is this action defined as a reputation action
    def action_defined?
      # ReputationThreshold.action_defined?(self.action, self.tier)
      !self.action_points.nil?
    end
    
    # returns the threshold points that are defined for certain action either in database or globally
    def action_points
      @threshold_action_points_cache ||= ReputationThreshold.action_points(self.action, self.tier)
    end

    # is a sender assigned?
    def sender?
      !!self.sender
    end
    
    protected 

    def validate_sender?
      @validate_sender.is_a?(FalseClass) ? false : true
    end

    # retrieves a bonus rate if any is associated with the associated tier
    def find_tier_threshold_points
      @tier_threshold_points_cache ||= if tp = self.tier.reputation_thresholds.find(:first, 
          :conditions => ["reward_rates.action = ?", self.action.to_s])
        tp
      elsif self.tier.parent && (ptp = self.tier.parent.reputation_thresholds.find(:first, 
          :conditions => ["reward_rates.action = ?", self.action.to_s]))
        ptp
      end
    end
    
    def validate
      # self.errors.add(:action, :invalid) unless self.action_defined?
      if self.validate_sender? && self.sender? && self.action_defined?
        required_points = self.action_points
        current_points = self.sender.reputation_points(
          self.tier && !self.tier.accept_person_total_reputation_points ? self.tier : nil)
          
        unless current_points >= required_points
          self.errors.add(:base, :invalid, 
            :action => ReputationReward.human_action_name(action).firstcase,
            :required => required_points,
            :current => current_points,
            :points => self.link_to_faq(Reputation.human_attribute_name(:points)),
            :faq => self.link_to_faq("FAQ page".t))
        end
      end
    end
    
    # produces an html href to the faq pages
    def link_to_faq(text, options={})
      html = "<a"
      html += " class=\"#{options[:class]}\"" if options[:class]
      html += " href=\"/faq\""
      html += ">" 
      html += text
      html += "</a>"
      html
    end
    
  end
  
end