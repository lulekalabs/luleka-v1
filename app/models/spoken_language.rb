# Container to manager the person's spoken languages
class SpokenLanguage < ActiveRecord::Base
  #--- assocations
  has_and_belongs_to_many :people

  #--- verifications
  validates_uniqueness_of :code, :case_sensitive => false

  #--- mixins
  self.keep_translations_in_model = true
  translates :name, :base_as_default => false
  
end
