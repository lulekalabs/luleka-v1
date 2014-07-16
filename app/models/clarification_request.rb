# As subclass of clarification it allows to request a clarification
# for a kase or response
class ClarificationRequest < Clarification
  #--- associations
  belongs_to :clarifiable, :foreign_key => :commentable_id, :foreign_type => :commentable_type, :polymorphic => true,
    :counter_cache => :clarification_requests_count
  
  #--- class methods
  class << self
    
    def kind
      :clarification_request
    end
    
  end
  
  #--- instance methods
  
  # overrides from clarification
  # Yes, this instance is a request
  def request?
    true
  end
  
  def repliable?(a_person=nil)
    if self.clarifiable.is_a?(Kase)
      true
    elsif self.clarifiable.is_a?(Response)
      true
    end
  end
  
end
