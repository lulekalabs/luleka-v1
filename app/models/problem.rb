# Problems are cases that need a (re)solution from the community. Problems can be
# general issues, bugs, problems whatever. Probono used 'Issues' for describing
# problems, so most of the business logic written applies to this class.
#
# Problems are specific to cases such as:
#
#   * expiration: an expiration to solve the problem is given, 1-7 days
#   * offer: you can offer a reward to have the problem solved
#   * there is only one 'correct' solution
#   * etc.
# 
class Problem < Kase

  #--- class methods
  class << self

    # overrides from Kase
    def kind
      :problem
    end

    # returns true if a $$$ reward can be offered for this kase
    # overridden from kase
    def allows_reward?
      true
    end

    def human_headline
      "We will look for solutions".t
    end
    
  end

  #--- instance methods

  def allows_reward?
    self.person?
  end
  
end
