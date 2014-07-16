# extends acts_as_taggable_type tag class
class Tag < ActiveRecord::Base

  #--- associations

  has_friendly_id :name, 
    :use_slug => true,
    :cache_column => :permalink,
    :approximate_ascii => true

  #--- instance methods

  protected

  def after_initialize
    self[:language_code] = I18n.locale_language.to_s unless self[:language_code]
  end
  
  # make sure we normalize correctly
  def normalize_friendly_id(slug_string)
    return super if self.language_code ? self.language_code == "en" : I18n.locale_language == :en
    options = friendly_id_config.babosa_options
    language = Utility.english_language_name(self.language_code || I18n.locale_language) || :english
    slug_string.normalize! options.merge(:transliterations => "#{language}".underscore.to_sym)
  end
  
end
