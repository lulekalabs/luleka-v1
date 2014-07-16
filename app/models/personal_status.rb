# Person status is a collection of employment status, like
#   self employed, freelancer, entrepreneur, headhunter, etc.
class PersonalStatus < ActiveRecord::Base
  #--- associations
  has_many :people

  #--- mixins
  self.keep_translations_in_model = true
  translates :name, :base_as_default => true

  #--- instance methods

  def english_name
    self[:name]
  end

  # intercept globalized name to return any localized column content as default
  #
  # e.g. 
  #
  # on locale "en-US" with self[:name_es] == "Argentina" and self[:name] = nil, we return
  #  "Argentina"
  #
  def name_with_any_as_default
    name_without_any_as_default || self.class.localized_facets_without_base(:name).map {|m| send(m)}.compact.first
  end
  alias_method_chain :name, :any_as_default

end
