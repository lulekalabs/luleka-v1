# Holds the labels for the different tier categories, e.g. Company, Government, etc.
class TierCategory < ActiveRecord::Base
  
  #--- mixins
  self.keep_translations_in_model = true
  translates :name, :base_as_default => true

  #--- class methods
  
  class << self
    
    def company
      @@tier_sub_type_company ||= find_by_kind('company')
    end
    
    def government
      @@tier_sub_type_government ||= find_by_kind('government')
    end

    def professional_group
      @@tier_sub_type_professional_group ||= find_by_kind('professional_group')
    end
    
  end
  
end
