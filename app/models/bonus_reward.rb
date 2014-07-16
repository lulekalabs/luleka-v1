# Subclass of reward rate. Defines the monetary reward given for bonuses and triggered by a bonus event. 
# Inside a Tier defines the source class, action and funding source on how to fullfill the bonus.
class BonusReward < RewardRate
  
  #--- validations
  validates_presence_of :source_class
  validates_presence_of :beneficiary_type
  validates_numericality_of :cents, :allow_nil => false, :greater_than => 0, :less_than_or_equal_to => 1000, :unless => :percent?
  validates_numericality_of :percent, :allow_nil => false, :greater_than => 0, :less_than_or_equal_to => 15, :unless => :cents?
  validates_uniqueness_of :action, :scope => [:tier_id, :source_class, :beneficiary_type]
  
  #--- class methods
  
  class << self
    
    # retrieves a bonus rate if any is associated with the associated tier
    def action_bonus_rate(reputable, destination, action, tier=nil)
      if tier
        tier.bonus_rewards.find(:first, 
          :conditions => ["reward_rates.source_class = ? AND reward_rates.beneficiary_type = ? AND reward_rates.action = ?",
            reputable.is_a?(Class) ? reputable.base_class.name : reputable.class.base_class.name, 
            destination.to_s, action.to_s])
      else
        # raise "Bonus rewards associated without a :tier. No default bonus rewards defined."
      end
    end
    
    # returns the rewarded money associated with reputable action
    #
    # E.g.
    #
    #   BonusReward.action.bonus(Response, :receiver, :accept_response, @tier)  ->  Money(50, "USD")  ->  $0.50
    #
    def action_bonus(reputable, destination, action, tier=nil)
      if rate = action_bonus_rate(reputable, destination, action, tier)
        Money.new(rate.cents, rate.default_currency)
      end
    end
    
    # override from RewardRate
    def source_classes
      bo = BonusObserver.send(:new)
      bo.observed_classes
    end
    
  end
  
  #--- instance methods
  
  protected
  
  # true if percent is given
  def percent?
    !!self.percent
  end
  
  def cents?
    !!self.cents
  end
  
end