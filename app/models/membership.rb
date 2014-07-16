# Membership is the link between a person and a tier. Each membership provides certain
# rights for a tier instance, e.g. admin, moderator, etc.
# Membership is the superclass of Employment, which is used for Organization (Tier)
class Membership < ActiveRecord::Base
  #--- assocations
  belongs_to :member, :class_name => 'Person', :foreign_key => :person_id
  belongs_to :tier, :class_name => 'Tier', :foreign_key => :tier_id

  #--- state machine
  acts_as_state_machine :initial => :passive, :column => :status
  state :passive
  state :active, :enter => :do_activate, :after => :after_activate
  state :suspended, :enter => :do_suspended, :after => :after_suspended
  state :moderator
  state :admin

  event :activate do
    transitions :from => :passive, :to => :active
  end
  
  event :suspend do 
    transitions :from => [:active, :moderator, :admin], :to => :suspended
  end

  event :moderator do 
    transitions :from => [:active, :admin], :to => :moderator
  end
  
  event :admin do
    transitions :from => [:active, :moderator], :to => :admin
  end
  
  event :downgrade do
    transitions :from => [:moderator, :admin], :to => :active
  end

  #--- class methods
  class << self

    def kind
      :membership
    end
    
    def member_s
      "member"
    end
    
    def member_t
      member_s.t
    end

    def members_s
      member_s.pluralize
    end
    
    def members_t
      members_s.t
    end

    def find_options_for_active_state(options={})
      {:conditions => ["memberships.status IN (?)", ['active', 'moderator', 'admin']]}
    end
    
  end

  #--- instance methods

  def kind
    self.class.kind
  end

  # update members count cache for tiers
  def update_tier_members_count
    if self.tier && self.tier.class.columns.to_a.map {|a| a.name.to_sym}.include?(:members_count)
      self.tier.class.transaction do 
        self.tier.lock!
        self.tier.update_attribute(:members_count,
          self.tier.members.count("people.id", self.class.find_options_for_active_state({:distinct => true})))
      end
    end
  end

  protected
  
  def do_activate
    self.activated_at = Time.now.utc
  end
  
  def after_activate
    self.update_tier_members_count
  end
  
  def do_suspended
  end

  def after_suspended
    self.update_tier_members_count
  end
  
end
