# Subclass of reward rate will define tier specific threshold to allow actions based on reputation points acquired
class ReputationThreshold < RewardRate
  
  #--- validations
  validates_numericality_of :points, :allow_nil => false, :greater_than_or_equal_to => 0, :less_than_or_equal_to => 20000
  validates_uniqueness_of :action, :scope => :tier_id

  #--- class_methods
  
  class << self

    def action_types
      %w(vote_up vote_down flag_offensive offer_reward leave_comment retag_kase newtag_kase edit_post moderate).sort.map(&:to_sym)
    end
    
    # is this action defined as a default reputation action
    def action_defined?(action, tier=nil)
      if tier && !tier.accept_default_reputation_threshold
        if rate = tier.find_reputation_threshold_action_points(action)
          return !!rate.points
        end
      end
      respond_to?(action.to_sym)
    end

    # is this action defined as a default reputation action
    def action_points(action, tier=nil)
      if tier 
        if rate = tier.find_reputation_threshold_action_points(action)
          return rate.points
        end
        return if !tier.accept_default_reputation_threshold
      end
      send(action.to_sym) if action_defined?(action)
    end
    
    #--- default reputation threshold 
    
    # reputation points necessary to vote up content
    def vote_up
      15
    end

    # reputation points necessary to vote down content
    def vote_down
      100
    end
    
    def flag_offensive
      15
    end
    
    def offer_reward
      50
    end
    
    def leave_comment
      50
    end
    
    def retag_kase
      500
    end 
    
    def newtag_kase
      700
    end 

    def edit_post
      2000
    end
    
    def moderate
      10000
    end
    
  end
  
end