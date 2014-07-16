# Groups are loose forms of organizations, e.g. neighborhoods, a community, etc.
class Group < Tier
  #--- class methods
  class << self
    
    def kind
      :group
    end
    
  end
  
  #--- instance methods
  
  # returns a representation for class/instance type
  def kind
    @kind || :group
  end
  
end