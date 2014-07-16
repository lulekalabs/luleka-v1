# Praise is a special form of a case. Users indicate that they show affection for 
# the product, location, company in context.
#
# Praises are special in that:
#
#   * no solution or answers
#   * comments only 
#
class Praise < Kase
  
  #--- class method
  class << self

    # overrides from Kase
    def kind
      :praise
    end

    def human_headline
      "What makes you happy?".t
    end
    
  end

  #--- instance method

end
