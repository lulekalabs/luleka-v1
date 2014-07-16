# Provides a model for string representation so academic titles,
# such as Dr., Prof., Prof. Dr. etc.
class AcademicTitle < ActiveRecord::Base
  
  #--- associations
  has_many :people
  has_many :addresses
  
  #--- mixins
  self.keep_translations_in_model = true
  translates :name, :base_as_default => true
  
  #--- class methods
  class << self
    
    def dr
      @@academic_title_dr ||= find_by_name('Dr.')
    end
    
    def prof
      @@academic_title_prof ||= find_by_name('Prof.')
    end
    
    def prof_dr
      @@academic_title_prof_dr ||= find_by_name('Prof. Dr.')
    end
    
  end
  
  #--- instance methods
  
  def english_name
    self[:name]
  end
  
  # returns the translated string
  def to_s
    self.name
  end
  
end
