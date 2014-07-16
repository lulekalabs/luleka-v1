# There are currently 5 severity levels defined. They are used to describe
# the case severity.
# 
#   * :trivial (1)
#   * :minor (25)
#   * :normal (50)
#   * :major (75)
#   * :critical (100)
#   
class Severity < ActiveRecord::Base
  #--- assoctiations
  has_many :kases
  
  #--- mixins
  self.keep_translations_in_model = true
  translates :name, :feeling, :base_as_default => true
  
  #--- class variables
  @@trivial = nil
  @@minor = nil
  @@normal = nil
  @@major = nil
  @@critical = nil
  
  #--- class methods
  class << self
    
    def median_id
      normal ? normal.id : nil
    end
    
    def trivial
      @@trivial || @@trivial = find_by_kind('trivial')
    end
    
    def minor
      @@minor || @@minor = find_by_kind('minor')
    end
    
    def normal
      @@normal || @@normal = find_by_kind('normal')
    end
    
    def major
      @@major || @@major = find_by_kind('major')
    end
    
    def critical
      @@critical || @@critical = find_by_kind('critical')
    end
    
    def find_by_kind(a_kind)
      find(:first, :conditions => {:kind => a_kind.to_s})
    end
    
  end
  
  #--- instant methods
  
  def kind
    self[:kind].to_sym
  end

  def kind=(a_kind)
    self[:kind] = a_kind.to_s if a_kind
  end
  
end
