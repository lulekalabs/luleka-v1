# Tag instances hold a tag, e.g. "blue", "dog", "car". Each tag instance is unique
# and case insensitive
class Tag < ActiveRecord::Base

  #--- accessors
  cattr_accessor :delimiter
  @@delimiter = ","

  #--- assocations
  has_many :taggings, :dependent => :destroy

  #--- validations
  validates_presence_of :name

  #--- class methods
  class << self
    
    # parse a string of tags delimited by delimiter and returns an array of strings
    #
    # e.g.
    # 
    #   Tag.parse("cat, dog, frog")  ->  ['cat', 'dog', 'frog']
    #   Tag.parse("cat dog frog", :delimiter => ' ')  ->  ['cat', 'dog', 'frog']
    #
    def parse(list, options={})
      options = {:delimiter => Tag.delimiter}.merge(options).symbolize_keys
      result = []
      delimiter = options.delete(:delimiter)
      filter_class = constantize_filter_class(options.delete(:delimiter))

      if list.is_a?(String)
        # first, pull out the quoted ("a quoted text" and 'a quoted text') tags
        list = list.to_s
        list.gsub!(/\"(.*?)\"\s*/) {result << $1; ""}
        list.gsub!(/\'(.*?)\'\s*/ ) {result << $1; ""}

        # list.gsub!(Regexp.new([';'].reject {|u| u.index(options[:delimiter])}.compact.join), "")
        # then, replace all separator-likes with a space unless it is the designated delimiter
        ['<', '>', '@', '$', ';'].reject {|u| u.index(delimiter.to_s.strip)}.each {|u| list.gsub!(u, '')}

        # then, get whatever's left
        if delimiter.blank?
          result.concat list.split(/\s/)
        else
          result.concat list.split(delimiter)
        end
      elsif list.is_a?(Array)
        result = list.map(&:to_s)
      end

      # strip whitespace, blanks and duplicates
      result = result.compact.map {|t| t.strip}.reject(&:blank?).uniq

      # apply filter, e.g. "sex" => "play", "fuck" => "", etc.
      if filter_class
        result = result.map {|tag| filter_class.sanitize_tag(tag)}.reject(&:blank?)
      end

      result
    end
    
    # parse and URL decoded string
    def parse_param(list_string, options={})
      parse(list_string ? CGI.unescape(list_string) : '', :delimiter => ' ')
    end

    # tokenizes a string of tags delmited by Tag.delimiter (or delimiter option)
    # and returns an array of Tag instances
    #
    # e.g.
    #
    #   Tag.tokenize("dog, cat")  ->  [Tag<name:"dog">, Tag<name:"cat">]
    #   Tag.tokenize(["dog", "cat"])  ->  [Tag<name:"dog">, Tag<name:"cat">]
    #
    def tokenize(list, options={})
      options = {:language_code => I18n.locale_language ? "#{I18n.locale_language}" : nil}.merge(options)
      filter_class = constantize_filter_class(options.delete(:filter_class))
      delimiter = options.delete(:delimiter)
      attribute = options.delete(:attribute)
      
      if list.is_a?(Array)
        list.map do |token|
          token = filter_class ? filter_class.sanitize_tag(token) : token
          Tag.new(options.merge(:name => token)) unless token.blank?
        end.compact
      else
        Tag.parse(list, {:delimiter => delimiter, 
          :filter_class => filter_class}.merge(options)).map {|token| Tag.new(options.merge(:name => token))}
      end
    end

    # compiles an array of tag instances into a delimited string
    # expects an array of Tag instances as tags
    #
    # e.g.
    #
    #   Tag.compile([Tag<name:"dog">, Tag<name:"cat">])  ->  "dog, cat"
    #   Tag.compile(["dog", "cat"])  ->  "dog, cat"
    #
    def compile(tags, options={})
      options = {:delimiter => Tag.delimiter}.merge(options).symbolize_keys
      return Tag.compile_string_array(tags.map(&:to_s), options) if tags
      ""
    end

    # Collect an array of tag instances to an array 
    # of tag string array
    #
    # e.g. 
    #
    #   Tag.collect([Tag<name:"dog">, Tag<name:"cat">]) -> ["dog", "cat"]
    #
    def collect(tags, options={})
      return tags.map(&:name).reject(&:blank?).uniq if tags
      []
    end
    alias_method :map, :collect

    # Find alls tags. Conditions can limit the returned tag instnaces by model and or ids
    #
    # e.g.
    #
    #   @tags = Tag.tags(:order => "name", :model => "Post", :scope => [1,2,3,4])
    #
    # Options:
    #   :order => ""
    #   :limit => 20
    #   :model => "Person" || :person
    #   :scope => 3 || [1,2,3,4]
    #
    # NOTE: rename to count
    #
    def tags(options = {})
      options[:model] = options[:model].to_s.singularize.capitalize if options[:model] && options[:model].is_a?(Symbol)
      options[:scope] = options[:scope].to_a if options[:scope] && !options[:scope].is_a?(Array)
      return [] if options[:scope] && options[:scope].empty?
      query = "SELECT tags.id AS id, tags.name AS name, COUNT(*) AS count" 
      query << " FROM taggings, tags" 
      query << " WHERE tags.id = taggings.tag_id" 
      query << " AND tags.name IS NOT NULL" 
      query << " AND taggings.taggable_type = '#{options[:model]}'" if options[:model]
      query << " AND taggings.taggable_id IN (#{options[:scope].join(',')})" if options[:model] && options[:scope]
      query << " GROUP BY taggings.tag_id" 
      query << " ORDER BY #{options[:order]}" if options[:order] != nil
      query << " LIMIT #{options[:limit]}" if options[:limit] != nil
      tags = Tag.find_by_sql(query)
    end

    # overwrites the rails default as we need options to be assiged
    def find_or_create_by_name(tag_name, options={})
      if tag = Tag.find(:first, :conditions => ["name = ?", tag_name])
        return tag
      else
        Tag.create(options.merge(:name => tag_name))
      end
    end

    # Finds a tag by parameters or creates a new one with these parameters
    def find_or_create_by_attributes(attributes, options={})
      unless tag = Tag.find(:first, :conditions => attributes)
        tag = Tag.create(attributes)
      end
      tag
    end

    # Finds a tag by parameters or creates a new one with these parameters
    def find_or_create(tag, options={})
      new_tag = nil
      if tag && tag.language_code
        unless new_tag = Tag.find_by_name_and_language_code(tag.name, tag.language_code)
          new_tag = Tag.create(tag.content_attributes)
        end
      elsif tag
        unless new_tag = Tag.find_by_name(tag.name)
          new_tag = Tag.create(tag.content_attributes)
        end
      end
      new_tag
    end

    protected
    
    # compiles an array of strings to a delimited string
    #
    # e.g.
    #
    #   ["dog", "cat"]  ->  "dog, cat"
    #
    def compile_string_array(string_array, options={})
      options = {:delimiter => Tag.delimiter}.merge(options).symbolize_keys

      # append space to delimiter
      delimiter = options[:delimiter].include?(' ') ? options[:delimiter] : "#{options[:delimiter]} "

      if string_array
        return string_array.reject(&:blank?).map {|t| t.include?(" ") && ' ' == delimiter ? "'#{t}'" : t }.uniq.join(delimiter)
      end
      ""
    end
    
    # filter class
    def constantize_filter_class(filter_class_name)
      if filter_class_name
        filter_class = filter_class_name.is_a?(Class) ? filter_class_name : filter_class_name.constantize
        return filter_class if filter_class.respond_to?(:sanitize_tag)
      end
    end

  end

  #--- instance methods

  # Overrides default to_param to allow for permalinks
  def to_param
    self.name.parameterize
  end

  def tagged
    @tagged ||= taggings.collect { |tagging| tagging.taggable }
  end
  
  # creates association between taggable instance and tag
  # optionally that assocation CAN have a context, like "skills",
  # and a name, like "Ruby" or "ruby"
  def on(taggable, context=nil, name=nil)
    self.taggings.create({:taggable => taggable, :name => name, :context => context ? context.to_s : nil})
    taggable.taggings.reload
  end
  
  def ==(comparison_object)
    super || name == comparison_object.to_s
  end
  
  # Note: please leave self.name and don't add .to_s
  def to_s
    self.name
  end
  
  # all tags for this instances model
  def tags(options = {})
    options.merge!(:model => self.to_s)
    Tag.tags(options)
  end
  
end