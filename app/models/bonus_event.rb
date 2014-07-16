# This class records all events that can potentially generate a bonus in form of money.
# The events are later on picked up by a process which runs every month to account for the bonus.
class BonusEvent < ActiveRecord::Base
  
  attr_protected :status
  
  #--- associations
  belongs_to :source, :polymorphic => true
  belongs_to :receiver, :polymorphic => true
  belongs_to :sender, :polymorphic => true
  belongs_to :tier
  
  #--- validations
  validates_presence_of :tier
  validates_presence_of :source
  validates_presence_of :receiver
  validates_presence_of :action

  #--- state machine
  acts_as_state_machine :initial => :created, :column => :status
  state :created
  state :cashed, :enter => :do_cash
  state :closed, :enter => :do_close

  event :cash do
    transitions :from => :created, :to => :cashed, :guard => :can_cash?
    transitions :from => :created, :to => :closed
  end

  event :cancel do
    transitions :from => [:created, :cashed], :to => :closed
  end
  
  #--- class methods
  
  class << self
    
    # finds all reputations that are active, still not cashed and are monetary incentive is given by the tier
    # TODO: add SQL to check if the tier piggy bank account actually has a balance
    def find_all_cashables(options={})
      conditions = "bonus_events.status IN ('created') AND reward_rates.action = bonus_events.action"
      find(:all, {:include => {:tier => :bonus_rewards}, :conditions => conditions}.merge_finder_options(options))
    end
      
  end
  
  #--- instance methods 
  
  # transfers money from the tier or funding source piggy bank to the receiver's 
  def can_cash?
    if self.tier && self.tier.piggy_bank
      if rate = find_bonus_rate
        # transfer cents
        if rate.cents.to_i > 0 && rate.funding_source.piggy_bank &&
            cashed_events_limit_not_reached?(rate.max_events_per_month)
          result = rate.funding_source.piggy_bank.transfer(self.receiver.piggy_bank, 
            Money.new(rate.cents, rate.default_currency))
          if result.success?
            self.description = result.message 
            return true
          end
        end
      end
    end
    false
  end
  
  # time stamp the cash event 
  def do_cash
    self.cashed_at = Time.now.utc
  end

  # time stamp the close event
  def do_close
    self.closed_at = Time.now.utc
  end
  
  # retrieves a bonus rate if any is associated with the associated tier
  def find_bonus_rate(beneficiary_type = :receiver)
    BonusReward.action_bonus_rate(self.source.class, beneficiary_type, self.action, self.tier)
  end

  # returns true if this bonus event can still be "cached" (in money terms) due to a max events threshold per month
  def cashed_events_limit_not_reached?(max)
    max ? self.cashed_events_count < max : true
  end
  
  # count similar bonus events within a time frame of e.g. one month
  def cashed_events_count(since = Time.now.utc - 1.month)
    self.class.count(:conditions => ["bonus_events.receiver_type = ? AND bonus_events.receiver_id = ? AND bonus_events.tier_id = ? AND bonus_events.action = ? AND bonus_events.created_at > ? AND bonus_events.status IN (?)",
      self.receiver.class.base_class.name, self.receiver.id,
        self.tier.id, self.action.to_s, since, ['cashed']])
  end
  
  protected 
  
  # returns action as symbol
  def action
    self[:action].to_sym if self[:action]
  end
  
  # converts action to string before writing to db
  def action=(value)
    self[:action] = value.to_s if value
  end
  
end
