# As a subclass of clarification is allows a reply to a clarification response
# on a clarification request for a kase or response (answer).
class ClarificationResponse < Clarification

  #--- associations
  belongs_to :clarifiable, :foreign_key => :commentable_id, :foreign_type => :commentable_type, :polymorphic => true,
    :counter_cache => :clarification_responses_count
  
  #--- class methods
  class << self
    
    def kind
      :clarification_response
    end
    
  end

  #--- instance methods
  
  def repliable?
    false
  end

  # override from clarification
  def response?
    true
  end
  
end
