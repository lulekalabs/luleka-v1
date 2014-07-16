# tagging is the link class between a taggable and a tag
class Tagging < ActiveRecord::Base

  #--- assocations
  belongs_to :tag, :counter_cache => true
  belongs_to :taggable, :polymorphic => true

  #--- class methods

  class << self

    # returns a delimited string of tag names taken from tagging or
    # if not present from tagging's tag. the advantage is that each
    # type can have its own case sensitive representation of the tag
    #
    # e.g.
    # 
    #   "Cat, dog, FROG"
    #   "cat, DoG, Frog"
    #
    def compile(taggings, options={})
      options = {:delimiter => Tag.delimiter}.merge(options).symbolize_keys
      delimiter = options[:delimiter].include?(' ') ? delimiter : "#{options[:delimiter]} "
      collect(taggings, options).join(delimiter)
    end
    
    # returns an array of strings of tag names
    #
    # e.g.
    # 
    #   ["Cat", "dog"]
    #
    def collect(taggings, options={})
      if options[:attribute]
        taggings.reject {|t| t.context != options[:attribute].to_s.pluralize}.map {|t| !t.tag.name.blank? && t.name ? t.name : t.tag.name}.reject(&:blank?)
      else
        taggings.map {|t| !t.tag.name.blank? && t.name ? t.name : t.tag.name}.reject(&:blank?)
      end
    end
    alias_method :map, :collect

  end

end