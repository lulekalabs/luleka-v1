# Questions are special cases of general question which needs ansering from
# the community. Questions are special in that:
#
#   * multiple answers
#   * no expiration: questions do not expire
#   * no offer: no money value can be offered for the answer
#   * etc.
#
class Question < Kase
  
  #--- class methods
  class << self

    # overrides from Kase
    def kind
      :question
    end

    # returns true if a $$$ reward can be offered for this kase
    # overridden from kase
    def allows_reward?
      true
    end

    def human_headline
      "We will look for answers".t
    end

  end

  #--- instance method

  # returns true if a $$$ reward can be offered for this kase
  # overridden from kase
  def allows_reward?
    self.person?
  end
  
end
