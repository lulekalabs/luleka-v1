# Subclass of reward rate. Defines the reputation points given based on a bonus event and action 
class ReputationReward < RewardRate
  
  #--- validations
  validates_presence_of :source_class
  validates_presence_of :beneficiary_type
  validates_numericality_of :points, :allow_nil => false, :greater_than => -100, :less_than_or_equal_to => 100
  validates_uniqueness_of :action, :scope => [:tier_id, :source_class, :beneficiary_type]
  
  #--- class methods
  
  class << self

    # gets reputation points that are given to sender or receiver, 
    # depending on the reputable class, e.g. Response,
    # the destination e.g. :sender or :receiver and the action, e.g. :vote_up
    #
    # e.g. 
    #
    #    ReputationReward.action_points(Response, :receiver, :vote_up, @tier)  ->  5
    #
    #    ReputationReward.action_points(Response, :sender, :vote_up)  ->  10
    #
    def action_points(reputable, destination, action, tier=nil)
      if tier
        rate = tier.reputation_rewards.find(:first, 
          :conditions => ["reward_rates.source_class = ? AND reward_rates.beneficiary_type = ? AND reward_rates.action = ?",
            reputable.is_a?(Class) ? reputable.base_class.name : reputable.class.base_class.name, 
              destination.to_s, action.to_s])
        # check for rate and decend recursively if need be
        if rate.nil? && tier.parent
          action_points(reputable, destination, action, tier.parent)
        elsif rate.nil? && tier.accept_default_reputation_points
          action_points(reputable, destination, action)
        else
          rate ? rate.points : nil
        end
      else
        klass = determine_class(reputable, destination)
        klass && klass.respond_to?(action) ? klass.send(action) : nil
      end
    end

    protected 
    
    # retrieves the dito klass name
    def determine_class(reputable, destination)
      "ReputationReward::#{reputable.is_a?(Class) ? reputable.base_class.name : reputable.class.base_class.name}::#{destination.to_s.classify}".constantize
    end
    
  end

  #--- default reputation rewards
  
  # e.g. ReputationReward::Response::Sender.vote_down -> -1
  class Response
    class Sender
      def self.vote_down
        -1
      end
    end

    class Receiver
      # defines how many points a receiver gets when the answer is voted up
      def self.vote_up
        5
      end

      def self.vote_down
        -2
      end

      def self.accept_response
        10
      end
    end
  end

  # e.g. ReputationReward::Kase::Sender.vote_down -> -1
  class Kase
    class Sender
      def self.vote_down
        -1
      end
    end

    class Receiver
      def self.vote_up
        5
      end

      def self.vote_down
        -2
      end
    end
  end
  
end