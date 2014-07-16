# acts_as_taggable_types is based on the DHH plugin and extended with
# useful suggestions from the rails wiki, including adding, counting
# and assigning tags. It was further modified to support transient
# tags. This behavior allows the user to assign tags, even if the 
# object has not been saved. Furthermore, you can declare tag fields
# which will act like regular attributes, but will be collected for
# contributing to the tag for this instance.
#
# e.g.
#
#   class Person
#     ...
#     acts_as_taggable
#     acts_as_taggable_types :skills, :pets
#     ...
#   end
#
#   @person.skills  ->  [<t1>, <t2>]
#   @person.skill  ->  "law, computers"
#
# options:
#   :delimiter => ','                      default: ','
#   :filter_class => BadWord || "BadWord"  default: nil
#
# where class BadWord needs to implement a singleton sanitize_tag method,
# which replaces a "bad" tag with a "good" or whatever
#
module ActiveRecord
  module Acts #:nodoc:
    module TaggableTypes #:nodoc:

      def self.included(base)
        base.extend(ClassMethods)  
      end
      
      module ClassMethods

        # simply returns true when the model is taggable
        def taggable?
          false
        end
        
        def acts_as_taggable(*arguments)
          acts_as_taggable_types(*arguments)
        end
        
        def acts_as_taggable_types(*arguments)
          attributes = []
          options = {}

          # distinguish between options and attributes
          arguments.each do |argument|
            case argument.class.name
            when 'Hash'
              options.merge! argument
            else
              attributes << argument
            end
          end
          
          # instance variable
          @acts_as_taggable_tags = []
          
          # define instances methods for each attribute
          tag_types = []
          attributes.compact.each do |attribute|
            tag_type = attribute.to_s.pluralize.underscore
            tag_types << tag_type
            
            # define instance variable per attribute
            self.instance_variable_set("@acts_as_taggable_#{tag_type.singularize}_tags", [])

            # define dynamic class methods 
            self.class_eval <<-RUBY
              def self.taggable?
                true
              end

              def self.caching_#{tag_type.singularize}_list?
                caching_tag_list_on?("#{tag_type}")
              end
              
              def self.#{tag_type.singularize}_counts(options={})
                tag_counts_on("#{tag_type}", options)
              end
        
              # getter to return a string of tags, delimited by :delimiter
              #
              # e.g.
              #
              #    @person.pet  ->  "dog, cat, frog"
              #
              def #{tag_type.singularize}(options={})
                tag_list_on("#{tag_type}", nil, options.merge({:format => :string}))
              end
              
              # getter to return an array of string of tags
              #
              # e.g.
              #
              #    @person.pet_list  ->  ["dog", "cat", "frog"]
              #
              def #{tag_type.singularize}_list(options={})
                tag_list_on("#{tag_type}", nil, options.merge({:format => :list}))
              end

              # getter to return an array of tags for type
              #
              # e.g.
              #
              #    @person.pets  ->  [Tag<name:"dog">, Tag<:name:"cat">, Tag<name:"frog">]
              #
              def #{tag_type.pluralize}
                self.tags_on("#{tag_type}")
              end

              # getter to return an array of taggings
              #
              # e.g.
              #
              #    @person.pet_taggings  ->  [Tagging<name:"dog">, Tagging<:name:"cat">]
              #
              def #{tag_type.singularize}_taggings
                self.taggings_on("#{tag_type}")
              end
              
              # defines a tag type setter to assign tags 
              #
              # e.g.
              #
              #    @person.pets = "dog, cat, frog"
              #    @person.pets = ["dog", "cat", "frog"]
              #    @person.pets = [<Tag:'dog'>, <Tag:'cat'>, <Tag:'frog'>]
              #
              def #{tag_type.singularize}=(list)
                tag_with(list, :attribute => "#{tag_type}")
              end

              # assigns tags for type 
              #
              # e.g.
              #
              #    @person.pet_list = "dog, cat, frog"
              #    @person.pet_list = ["dog", "cat", "frog"]
              #    @person.pet_list = [<Tag:'dog'>, <Tag:'cat'>, <Tag:'frog'>]
              #
              def #{tag_type.singularize}_list=(new_tags)
                set_tag_list_on("#{tag_type}", new_tags)
              end
            
              # returns the count of instances 
              #
              def #{tag_type.singularize}_counts(options = {})
                tag_counts_on("#{tag_type}", options)
              end
              
              # not yet implemented
              def #{tag_type}_from(owner, options={})
                tag_list_on("#{tag_type}", owner, options)
              end
              
              # find related objects tagged with the same tag type as self
              def find_related_#{tag_type}(options = {})
                related_tags_on("#{tag_type}", self.class, options)
              end
              alias_method :find_related_on_#{tag_type}, :find_related_#{tag_type}

              # find related objects of type klass tagged with the same tag type as self
              def find_related_#{tag_type}_for(klass, options = {})
                related_tags_on("#{tag_type}", klass, options)
              end
              
            RUBY
            
          end

          # save options
          write_inheritable_attribute(:acts_as_taggable_options, {
            :taggable_type => ActiveRecord::Base.send(:class_name_of_active_record_descendant, self).to_s,
            :from => options[:from],
            :delimiter => options[:delimiter].nil? ? Tag::delimiter : options[:delimiter],
            :attributes => tag_types,
            :filter_class => options[:filter_class] ? options[:filter_class].to_s : nil,
            :filter_active => options[:filter_active] && options[:filter_class] || !options[:filter_class].nil?
          })
          class_inheritable_reader :acts_as_taggable_options

          # define associations
          has_many :taggings, :as => :taggable, :include => :tag, :dependent => :destroy
          has_many :tags, :through => :taggings

          # callbacks
          after_save :save_tags

          # include and extend
          include ActiveRecord::Acts::TaggableTypes::InstanceMethods
          extend ActiveRecord::Acts::TaggableTypes::SingletonMethods
          alias_method_chain :reload, :tag_list
          after_initialize :update_all_instance_tags_with_language_code

        end
      end
      
      module SingletonMethods
        
        
        # returns the list of tag types for this class
        #
        # e.g.
        #
        #   Person.tag_types  ->  [:pets, :skills, :interests]
        #
        def tag_types
          acts_as_taggable_options[:attributes]
        end
        
        # Returns the tag list delimiter
        def tag_list_delimiter
          acts_as_taggable_options[:delimiter]
        end
        
        # Sets the tag list delimiter
        def tag_list_delimiter=(delimiter)
          acts_as_taggable_options[:delimiter] = delimiter
        end
        
        # Returns the bad word filter class, e.g. BadWord
        def tag_filter_class
          acts_as_taggable_options[:filter_class].constantize if acts_as_taggable_options[:filter_class]
        end
        
        # sets the tag filter class as class or name e.g. "BadWord" or BadWord
        def tag_filter_class=(filter_class)
          acts_as_taggable_options[:filter_class] = filter_class.to_s if filter_class
        end

        # returns true or false if the bad word filter is active
        def filter_tags?
          !!(acts_as_taggable_options[:filter_active] && acts_as_taggable_options[:filter_class])
        end
        alias_method :tag_filter_active?, :filter_tags?
        alias_method :tag_filter_active, :filter_tags?
        
        # assigns true || false, and sets the tag filter to active or deactivates it
        def filter_tags=(active)
          acts_as_taggable_options[:filter_active] = !!active if acts_as_taggable_options[:filter_class]
        end
        alias_method :tag_filter_active=, :filter_tags=
        
        # caching enabled for context
        def caching_tag_list_on?(context)
          column_names.include?("cached_#{context.to_s.singularize}_list")
        end     
        
        # Finds all instances of this class that are tagged with the given tags.
        # Pass either a single tag string, an array of strings or array of tags
        # 
        # e.g.
        #
        #   Taggable.find_tagged_with('sundea')
        #   Taggable.find_tagged_with(['sundea', 'parabol'])
        #   Taggable.find_tagged_with([Tag.find(1), Tag.find(2))
        # 
        def find_tagged_with(*args)
          options = find_options_for_find_tagged_with(*args)
          options.blank? ? [] : find(:all, options)
        end

        # returns the count for a specific tag type
        def tag_counts_on(context, options = {})
          Tag.find(:all, find_options_for_tag_counts(options.merge({:attribute => context.to_s})))
        end           
        alias_method :tag_counts_for, :tag_counts_on
        
        def tag_counts(options={})
          Tag.find(:all, find_options_for_tag_counts(options))
        end
        alias_method :tag_counts, :tag_counts
        
        # returns find options for find_tagged_with
        #
        # options:
        #
        #   :exclude          - find models that are not tagged with the given tags
        #   :match_all        - if true, models that match all of the given tags
        #   :conditions       - a piece of conditions to add to the query
        #   :delimiter        - the separator for parsing tags (:separator is deprecated)
        #   :attribute || :on - context, e.g. 'pets', 'skills'
        #   :extra_conditions - some more conditions,
        #
        def find_options_for_find_tagged_with(tags, options={})
          tags = Tag.parse(tags,
            :delimiter => options.delete(:delimiter) || acts_as_taggable_options[:delimiter]) if tags.is_a?(String)
          tags = tags.map(&:to_s).reject {|t| t.blank?}
          return {} if tags.empty?
          
          context = options.delete(:attribute) || options.delete(:on)
          
          conditions = sanitize_sql(["#{table_name}_tags.name " + 
            "#{"NOT" if options.delete(:exclude)} IN (?)", tags])
          conditions << " AND #{sanitize_sql(options.delete(:conditions))}" if options[:conditions]
          conditions << " AND #{sanitize_sql(options.delete(:extra_conditions))}" if options[:extra_conditions]
          
          joins = "LEFT OUTER JOIN taggings #{table_name}_taggings ON #{table_name}_taggings.taggable_id = #{table_name}.#{primary_key} AND #{table_name}_taggings.taggable_type = '#{base_class.name}' " +
            (context ? "AND #{table_name}_taggings.context = '#{context}' " : "") +
            "LEFT OUTER JOIN tags #{table_name}_tags ON #{table_name}_tags.id = #{table_name}_taggings.tag_id"
          
          group = "#{table_name}_taggings.taggable_id HAVING COUNT(#{table_name}_taggings.taggable_id) = #{tags.size}" if options.delete(:match_all)
          
          { :select => "DISTINCT #{table_name}.*",
            :joins      => joins,
            :conditions => conditions,
            :group      => group
          }.merge(options)
        end
        
        # Calculate the tag counts for all tags.
        # 
        # Options:
        #  :start_at          - Restrict the tags to those created after a certain time
        #  :end_at            - Restrict the tags to those created before a certain time
        #  :conditions        - A piece of SQL conditions to add to the query
        #  :limit             - The maximum number of tags to return
        #  :order             - A piece of SQL to order by. Eg 'tags.count desc' or 'taggings.created_at desc'
        #  :at_least          - Exclude tags with a frequency less than the given value
        #  :at_most           - Exclude tags with a frequency greater than the given value
        #  :attribute || :on  - Scope the find to only include a certain context
        def find_options_for_tag_counts(options = {})
          options.assert_valid_keys :start_at, :end_at, :conditions, :at_least, :at_most, :order, :limit, :on, :attribute
          
          scope = scope(:find)
          start_at = sanitize_sql(["#{Tagging.table_name}.created_at >= ?", options.delete(:start_at)]) if options[:start_at]
          end_at = sanitize_sql(["#{Tagging.table_name}.created_at <= ?", options.delete(:end_at)]) if options[:end_at]

          type_and_context = "#{Tagging.table_name}.taggable_type = #{quote_value(base_class.name)}"
          context = options.delete(:attribute) || options.delete(:on)
          conditions = sanitize_sql(options.delete(:conditions)) if options[:conditions]

          conditions = [
            type_and_context,
            conditions,
            start_at,
            end_at
          ]

          if tags = options[:tags]
            tags = Tag.parse(tags,
              :delimiter => options.delete(:delimiter) || acts_as_taggable_options[:delimiter]
            ).map(&:to_s).reject {|t| t.blank?} if tags.is_a?(String)
            conditions << "#{sanitize_sql(["#{Tag.table_name}.name #{"NOT" if options.delete(:exclude)} IN (?)", tags])}" unless tags.empty?
          end
          
          conditions = conditions.compact.join(' AND ')
          conditions = merge_conditions(conditions, scope[:conditions]) if scope

          joins = ["LEFT OUTER JOIN #{Tagging.table_name} ON #{Tag.table_name}.id = #{Tagging.table_name}.tag_id"]
          joins << sanitize_sql(["AND #{Tagging.table_name}.context = ?", context.to_s]) unless context.blank? || "#{context}" == "tags"
          joins << "LEFT OUTER JOIN #{table_name} ON #{table_name}.#{primary_key} = #{Tagging.table_name}.taggable_id"
          joins << scope[:joins] if scope && scope[:joins]

          at_least  = sanitize_sql(['COUNT(*) >= ?', options.delete(:at_least)]) if options[:at_least]
          at_most   = sanitize_sql(['COUNT(*) <= ?', options.delete(:at_most)]) if options[:at_most]
          having    = [at_least, at_most].compact.join(' AND ')
          group_by  = "#{Tag.table_name}.id, #{Tag.table_name}.name HAVING COUNT(*) > 0"
          group_by << " AND #{having}" unless having.blank?

          { :select     => "#{Tag.table_name}.id, #{Tag.table_name}.name, COUNT(*) AS count", 
            :joins      => joins.join(" "),
            :conditions => conditions,
            :group      => group_by
          }.update(options)
        end    
        
      end

      module InstanceMethods

        # getter of the language code for tags
        def tag_language_code
          @tag_language_code
        end
        
        # setter
        def tag_language_code=(value)
          @tag_language_code = value
        end

        # same as class method
        def tag_types
          self.class.tag_types
        end

        # finder for related tags
        def related_tags_on(context, klass, options={})
          search_conditions = related_search_options(context, klass, options)
          klass.find(:all, search_conditions)
        end
        alias_method :related_tags_for, :related_tags_on
        
        # find objects that are related to this instance's tags
        def find_related_tags(options={})
          search_conditions = related_search_options(nil, self.class, options)
          self.class.find(:all, search_conditions)
        end

        # find objects that are related to this instance's tags
        def find_related_tags_for(klass, options={})
          search_conditions = related_search_options(nil, klass, options)
          klass.find(:all, search_conditions)
        end
        
        # related search options
        def related_search_options(context, klass, options = {})
          tags_to_find = if context
            self.tags_for(context).collect {|t| t.name}
          else
            self.tags.map(&:to_s)
          end

          { :select     => "#{klass.table_name}.*, COUNT(#{Tag.table_name}.id) AS count", 
            :from       => "#{klass.table_name}, #{Tag.table_name}, #{Tagging.table_name}",
            :conditions => ["#{klass.table_name}.id = #{Tagging.table_name}.taggable_id AND " + 
              "#{Tagging.table_name}.taggable_type = '#{klass.to_s}' AND " +
              "#{Tagging.table_name}.tag_id = #{Tag.table_name}.id AND " +
              "#{Tag.table_name}.name IN (?)", tags_to_find],
            :group      => "#{klass.table_name}.id",
            :order      => "count DESC"
          }.update(options)
        end
        
        # returns all tag instances related to this instance's context
        # if you use nil, only non typed tags will be returned
        def tags_on(context, owner=nil)
          options = if owner
            if context.to_s == 'tags'
              {:conditions => ["context IS NULL AND tagger_id = ? AND tagger_type = ?",
                owner.id, owner.class.to_s]}
            else
              {:conditions => ["context = ? AND tagger_id = ? AND tagger_type = ?",
                context.to_s, owner.id, owner.class.to_s]}
            end
          else
            if context.to_s == 'tags'
              {:conditions => "context IS NULL"}
            else
              {:conditions => ["context = ?", context.to_s]}
            end
          end
          self.tags.find(:all, options)
        end

        # returns all taggings related to a context
        def taggings_on(context, owner=nil)
          options = if context.to_s == 'tags'
            {:conditions => "context IS NULL"}
          else
            {:conditions => ["context = ?", context.to_s]}
          end
          self.taggings.find(:all, options)
        end
        
        # returns taggings of this instance's tags that relate to the given tags
        #
        # e.g. 
        #
        #   @post.taggings_tagged_with("blue")
        #   @post.taggings_tagged_with("blue, green", :colors)
        #
        def taggings_tagged_with(tags, context=nil, options={})
          tags = Tag.parse(tags,
            :delimiter => options.delete(:delimiter) || acts_as_taggable_options[:delimiter]) if tags.is_a?(String)
          tags = tags.reject {|t| t.blank?}
          
          joins =  ["LEFT OUTER JOIN #{Tagging.table_name} #{self.class.table_name}_taggings ON #{self.class.table_name}_taggings.tag_id = #{Tag.table_name}.id"]
          joins << "LEFT OUTER JOIN #{self.class.base_class.table_name} #{self.class.table_name}_taggable ON #{self.class.table_name}_taggable.id = #{self.class.table_name}_taggings.taggable_id AND " +
            "#{self.class.table_name}_taggings.taggable_type = '#{self.class.base_class.name}'"
          
          tag_name_conditions = '(' + tags.map {|t| "#{Tagging.table_name}.name LIKE '#{t}'"}.join(" OR ") + ')'
          
          conditions = if context.to_s == 'tags'
            ["#{tag_name_conditions} AND " +
              "#{Tagging.table_name}.context IS NULL"]
          elsif context
            ["#{tag_name_conditions} AND " +
              "#{Tagging.table_name}.context = ?", context.to_s]
          else
            [tag_name_conditions]
          end
          group = "#{Tagging.table_name}.id"
          
          self.taggings.find(:all, {
            :joins => joins.join(' '),
            :conditions => conditions,
            :group => group
          })
        end

        # returns the number of tags for a condition
        def tag_counts(options={})
          Tag.find(:all, self.class.find_options_for_tag_counts(options))
        end
        alias_method :tag_counts, :tag_counts

        # same as class
        def tag_counts_on(context, options={})
          self.class.tag_counts_on(context, {
            :conditions => ["#{Tag.table_name}.name IN (?)", tag_list_on(context)]
          }.reverse_merge!(options))
        end

        # assigns tag for context
        def set_tag_list_on(context, new_list, tagger=nil)
          self.tag_with(new_list, :attribute => context)
        end
        
        # Instead of alias to tag_with, included this function, as tag_with is also
        # taking options hash, which is not necessary in this case
        def tag_list=(list)
          tag_with(list)
        end

        # assigns the given tags
        #
        # e.g.
        #
        #   @person.tag_with('law, order')
        #   @person.tag_with(['law', 'order'])
        #   @person.tag_with('dog, cat', :attribute => :pets)
        #
        def tag_with(list, options={})
          options = { 
            :delimiter => acts_as_taggable_options[:delimiter],
            :filter_class => acts_as_taggable_options[:filter_active] ? acts_as_taggable_options[:filter_class] : nil,
            :language_code => tag_language_code
          }.merge(options).symbolize_keys
          
          if options[:attribute]
            save_tags = instance_tags_on(options[:attribute]) || []
            save_tags += Tag.tokenize(list, options)
            self.set_instance_tags(options[:attribute], save_tags)
          else
            save_tags = instance_tags || []
            save_tags += Tag.tokenize(list, options)
            self.set_instance_tags(nil, save_tags)
          end
        end

        # returns an array of tag string for a context
        def tag_list_on(context, owner=nil, options={})
          options = {:format => :list}.merge(options).symbolize_keys
          self.tag_list(options.merge({:attribute => "#{context}"}))
        end
        
        # Returns a list of tags in different format, list of string, array or tag
        # default format is array of strings
        #
        # e.g. 
        #
        #   @bar.tag_list(:format => :string)  ->  "drink, liquid, Coca Cola"
        #   @bar.tag_list(:format => :list)  ->  ['drink', 'liquid', 'Coca Cola']
        #   @bar.tag_list(:format => :tags)  ->  [Tag<name:"drink">, ...]
        #   @bar.tag_list :attribute => :drinks  ->  "Coca Cola"
        #
        # options:
        #
        #   :attribute => :have_expertise
        #   :format => :string, :list, :tags
        #   :delimiter => ','
        #
        def tag_list(options={})
          defaults = {:delimiter => acts_as_taggable_options[:delimiter], :format => :list}
          options = defaults.merge(options).symbolize_keys
          options.delete(:attribute) if options[:attribute] == 'tags' || options[:attribute].blank?
          
          unless options[:attribute]
            # common tags
            case options[:format].to_sym
            when :string
              Tag.compile((Tagging.collect(self.taggings, options) + Tag.collect(self.all_instance_tags, options)).uniq, options)
            when :list
              (Tagging.collect(self.taggings, options) + Tag.collect(self.all_instance_tags, options)).uniq
            when :tags
              (self.tags + (self.all_instance_tags || [])).uniq
            end
          else
            # with attributes
            case options[:format].to_sym
            when :string
              instance_tags_on(options[:attribute]) ? Tag.compile(instance_tags_on(options[:attribute]), options) : Tagging.compile(self.taggings, options)
            when :list
              instance_tags_on(options[:attribute]) ? Tag.collect(instance_tags_on(options[:attribute]), options) : Tagging.collect(self.taggings, options)
            when :tags
              instance_tags_on(options[:attribute]) ? instance_tags_on(options[:attribute]) : tags_on(options[:attribute])
            end
          end
        end
   
        # Adds tags rather than deleting the existing as in tag_with()
        #
        # e.g.
        #
        #   add_tag_with('law, order', 
        #     :attribute => :have_expertises,
        #     :delimiter => ','
        #     :language_code => 'de'
        #   )
        #
        def add_tag_with(list, options={})
          options = {
            :delimiter => acts_as_taggable_options[:delimiter],
            :filter_class => acts_as_taggable_options[:filter_active] ? acts_as_taggable_options[:filter_class] : nil,
            :language_code => tag_language_code
          }.merge(options).symbolize_keys
          options.delete(:attribute) if options[:attribute] == 'tags'
          
          if self.new_record? || (acts_as_taggable_options[:from] && acts_as_taggable_options[:from].new_record?)
            if options[:attribute]
              if tags = self.instance_variable_get("@acts_as_taggable_#{options[:attribute].to_s.singularize}_tags")
                Tag.tokenize(list, options).each { |tag| tags << tag unless tags.include?( tag ) }
              end
            else
              if tags = self.instance_variable_get( "@acts_as_taggable_tags" )
                Tag.tokenize(list, options).each { |tag| tags << tag unless tags.include?( tag ) }
              end
            end
          else
            Tag.transaction do
              Tag.parse(list, options).each do |name|
                if acts_as_taggable_options[:from]
                  send(acts_as_taggable_options[:from]).tags.find_or_create_by_name(name).on(self, options[:attribute], name)
                else
                  tag = Tag.find_or_create_by_name(name, options)
                  tag.on(self, options[:attribute], name) and self.tags.reload unless self.tags.include? tag
                end
              end
            end
          end
        end
        
        protected
        
        # intercepted reload
        def reload_with_tag_list(*args)
          clear_all_saved_instance_tags
          reload_without_tag_list(*args)
        end
        
        # we need to update all unsaved tags with tag_language_code
        def update_all_instance_tags_with_language_code
          update_all_instance_tags_with({:language_code => self.tag_language_code})
        end
        
        # persists any tags that assigned to this instance
        # when not written to database, yet. This method
        # is called after instance was created.
        def save_tags(options={})
          options = {:delimiter => acts_as_taggable_options[:delimiter],
            :language_code => tag_language_code}.merge(options).symbolize_keys

          self.update_all_instance_tags_with_language_code
            
          # tags acting like a virtual attribute
          self.tag_types.each do |attribute|
            if context_tags = self.instance_tags_on(attribute)
              self.taggings.delete self.taggings_on(attribute)
              context_tags.each {|tag| self.add_tag_from(tag, options.merge(:attribute => attribute))}
            end
          end
          # common tags
          if common_tags = self.instance_tags
            self.taggings.delete self.taggings.reject {|t| t.context}
            common_tags.each {|tag| self.add_tag_from(tag, options)}
          end
          clear_all_instance_tags
        end

        # adds a single tag or removes it from tagging
        def add_tag_from(new_tag, options={})
          tag = Tag.find_or_create(new_tag, options)
          tag.on(self, options[:attribute], tag.name) unless self.taggings.map {|t| t.tag_id if options[:attribute] == t.context}.compact.include?(tag.id)
        end
    
        def instance_tags_on(context=nil)
          if context
            self.instance_variable_get("@acts_as_taggable_#{context.to_s.singularize}_tags")
          end
        end

        def instance_tags
          self.instance_variable_get("@acts_as_taggable_tags")
        end
        
        def set_instance_tags(context, tags)
          if context
            self.instance_variable_set("@acts_as_taggable_#{context.to_s.singularize}_tags", tags)
          else
            self.instance_variable_set("@acts_as_taggable_tags", tags)
          end
        end

        # returns all tags from all instances
        def all_instance_tags
          tags = []
          self.tag_types.each {|tag_type| tags += (self.instance_tags_on(tag_type) || [])}
          tags += (self.instance_tags || [])
          tags.uniq
        end

        # resets all tag instances
        def clear_all_instance_tags
          self.tag_types.each do |tag_type|
            self.instance_variable_set("@acts_as_taggable_#{tag_type.to_s.singularize}_tags", nil)
          end
          self.instance_variable_set("@acts_as_taggable_tags", nil)
        end

        # removes all instance tags that were already saved
        def clear_all_saved_instance_tags
          self.tag_types.each do |tag_type|
            if self.instance_variable_get("@acts_as_taggable_#{tag_type.to_s.singularize}_tags")
              self.instance_variable_set("@acts_as_taggable_#{tag_type.to_s.singularize}_tags", 
                self.instance_variable_get("@acts_as_taggable_#{tag_type.to_s.singularize}_tags").to_a.reject {|t| self.tags_on(tag_type).map(&:name).include?(t.name)})
            end
          end
          if self.instance_variable_get("@acts_as_taggable_tags")
            self.instance_variable_set("@acts_as_taggable_tags", 
              self.instance_variable_get("@acts_as_taggable_tags").to_a.reject {|t| self.tags.map(&:name).include?(t.name)})
          end
        end
        
        # updates all unsaved instance tags with options
        #
        # e.g.
        #
        #   self.update_all_instance_tags_with(:language_code => "de")
        #
        def update_all_instance_tags_with(options={})
          self.tag_types.each do |tag_type|
            if self.instance_variable_get("@acts_as_taggable_#{tag_type.to_s.singularize}_tags")
              self.instance_variable_set("@acts_as_taggable_#{tag_type.to_s.singularize}_tags", 
                self.instance_variable_get("@acts_as_taggable_#{tag_type.to_s.singularize}_tags").to_a.each {|tag| tag.attributes = options})
            end
          end
          if self.instance_variable_get("@acts_as_taggable_tags")
            self.instance_variable_set("@acts_as_taggable_tags", 
              self.instance_variable_get("@acts_as_taggable_tags").to_a.each {|tag| tag.attributes = options})
          end
        end
        
      end
    end
  end
end
