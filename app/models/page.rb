# Base class model for all Web pages and static content
class Page < ActiveRecord::Base

  #--- validations
  validates_uniqueness_of :permalink
  validates_presence_of :permalink
  validates_presence_of :title

  #--- mixins
  self.keep_translations_in_model = true
  translates :title, :permalink, :content, :base_as_default => true

  #--- class methods
  
  class << self
    
    def finder_name
      :find_by_permalink
    end
    
    def finder_options
      {}
    end
    
    def find_by_permalink(permalink, options={})
      unless result = find(:first, find_options_for_find_by_permalink(permalink, options))
        raise ActiveRecord::RecordNotFound, "Couldn't find #{name} with ID=#{permalink}"
      end
      result
    end 
    
    def find_options_for_find_by_permalink(permalink, options={})
      {:conditions => ["pages.permalink = ? OR pages.#{Page.translated_attribute_name(:permalink)} = ?", permalink, permalink]}.merge_finder_options(options)
    end
    
  end

  #--- instance methods

  # returns html from content, 
  # straight from content or textilizes or markdown
  def html
    if self.textile
      RedCloth.new(self.content).to_html if self[:content]
    elsif self.markdown
      BlueCloth.new(self.content).to_html if self[:content]
    else
      self.content
    end
  end

  # by default returns "page" as dom id, otherwise, 
  def dom_id
    self[:dom_id] || "page"
  end

end
