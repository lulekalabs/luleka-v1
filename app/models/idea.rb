# Ideas are a special form of a case. They are special in that there is:
#
#   * no solution or answers
#   * vote for an idea ('good' or 'bad' idea)
#   * comments only 
#
class Idea < Kase
  #--- class method
  class << self

    # overrides from Kase
    def kind
      :idea
    end

    def human_headline
      "We will see if others have the same idea".t
    end
  end

  #--- instance method
end
