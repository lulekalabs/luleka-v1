# A collection of extensions and monkey patches for ActiveRecord
# patch ActiveRecord
module ActiveRecord
  module CoreExtensions
    module Base
      module ClassMethods

        # returns the method name of the finder to retrieve an instance
        #
        # e.g.
        #
        #   Kase.send(Kase.instance_finder_name, @id, Kase.instance_finder_options)
        #
        def finder_name
          :find
        end

        # default options to pass on to the finder for lazy loading
        #
        # e.g.
        #
        #   :include => :votes
        #
        def finder_options
          {}
        end

        # finder retrieves an instance by id or permalink
        #
        # e.g.
        #
        #   Kase.finder params[:id]       # where id is "this is a case", so use find_by_permalink
        #   Response.finder params[:id]   # where id is "1" the record id, so use find_by_id, or find
        #
        def finder(id, options={})
          send(finder_name, id, finder_options.merge_finder_options(options))
        end

        # sanitizes SQL and safely merges multiple conditions with AND
        #
        # e.g.
        #
        #   User.sanitize_and_merge_conditions "id = 1", [':state = ?', state]
        #   ->  "id = 1 AND state = 'new'"
        #
        def sanitize_and_merge_conditions(*conditions)
          conditions = conditions.reject(&:blank?).map {|condition| sanitize_sql_for_assignment(condition)}.reject(&:blank?)
          conditions.empty? ? nil : conditions.join(" AND ")
        end
        alias_method :sanitize_and_merge_conditions_with_and, :sanitize_and_merge_conditions

        # sanitizes SQL and safely merges multiple conditions with OR
        def sanitize_and_merge_conditions_with_or(*conditions)
          conditions = conditions.reject(&:blank?).map {|condition| sanitize_sql_for_assignment(condition)}.reject(&:blank?)
          conditions.empty? ? nil : conditions.join(" OR ")
        end

        # merges order (ORDER BY) statements
        def sanitize_and_merge_order(*orders)
          orders = orders.reject(&:blank?).map do |order|
            order.strip!
            order = order.last == ',' ? order.chop : order
          end
          orders = orders.reject(&:blank?)
          orders.empty? ? nil : orders.join(", ")
        end

        # sanitizes SQL and safely merges multiple joins
        def sanitize_and_merge_joins(*joins)
          joins = joins.reject(&:blank?).map {|join| sanitize_sql_for_assignment(join)}.reject(&:blank?)
          joins.empty? ? nil : joins.join(" ")
        end

        # strip attributes on validate
        # 
        # e.g.
        #
        #   class Foo < ActiveRecord::Base 
        #     ...
        #     auto_strip :name, :description
        #     ...
        #   end
        def auto_strip(*attributes)
          attributes.each do |attribute|
            before_validation do |record|
              record.send("#{attribute}=", record.send("#{attribute}_before_type_cast").to_s.strip) if record.send(attribute)
            end
          end
        end
        
        # same as content_columns just returning content relevant columns
        def content_column_names
          content_columns.map(&:name) - %w(created_at updated_at state status)
        end

        #--- resource translation helpers
        
        # returns resourse name mainly used for routes.rb
        # e.g. Person.resource_name -> :person
        def resource_name
          name.underscore.to_sym
        end

        # e.g. Person.resources_name -> :people
        def resources_name
          name.underscore.pluralize.to_sym
        end

        # e.g. Person.human_resource_name -> "mensch"
        def human_resource_name
          human_name.downcase
        end

        # used in routes.rb, when routes are parsed in :"en-US" locale we get english resource names 
        # e.g. Person.human_resource_name -> "menschen"
        def human_resources_name
          human_name == human_name(:count => 2) ? human_name.pluralize.downcase : human_name(:count => 2).downcase
        end
        
      end

      module InstanceMethods

        # return only attributes with relevant content
        def content_attributes
          self.attributes.reject {|k,v| !self.content_column_names.include?(k.to_s)}.symbolize_keys
        end
        
        # returns content column name strings 
        def content_column_names
          self.class.content_column_names
        end
        
        # same as class method 
        def sanitize_and_merge_conditions(*conditions)
          self.class.sanitize_and_merge_conditions(*conditions)
        end
        alias_method :sanitize_and_merge_conditions_with_and, :sanitize_and_merge_conditions

        # same as class method 
        def sanitize_and_merge_conditions_with_or(*conditions)
          self.class.sanitize_and_merge_conditions_with_or(*conditions)
        end

        # same as class method method
        def sanitize_and_merge_order(*orders)
          self.class.sanitize_and_merge_order(*orders)
        end

        # same as class method method
        def sanitize_and_merge_joins(*joins)
          self.class.sanitize_and_merge_joins(*joins)
        end

      end
    end
  end
end
ActiveRecord::Base.send(:include, ActiveRecord::CoreExtensions::Base::InstanceMethods)
ActiveRecord::Base.send(:extend, ActiveRecord::CoreExtensions::Base::ClassMethods)

# following patch is not going into CoreExtension models, because the patch would 
# not be applied
ActiveRecord::Base.class_eval do 
  class << self
    protected
    
    # overrides active_record/base in 2.3.4, 
    # order merge now supported
    def with_scope(method_scoping = {}, action = :merge, &block)
      method_scoping = method_scoping.method_scoping if method_scoping.respond_to?(:method_scoping)

      # Dup first and second level of hash (method and params).
      method_scoping = method_scoping.inject({}) do |hash, (method, params)|
        hash[method] = (params == true) ? params : params.dup
        hash
      end

      method_scoping.assert_valid_keys([ :find, :create ])

      if f = method_scoping[:find]
        f.assert_valid_keys(VALID_FIND_OPTIONS)
        set_readonly_option! f
      end

      # Merge scopings
      if [:merge, :reverse_merge].include?(action) && current_scoped_methods
        method_scoping = current_scoped_methods.inject(method_scoping) do |hash, (method, params)|
          case hash[method]
            when Hash
              if method == :find
                (hash[method].keys + params.keys).uniq.each do |key|
                  merge = hash[method][key] && params[key] # merge if both scopes have the same key
                  if key == :conditions && merge
                    if params[key].is_a?(Hash) && hash[method][key].is_a?(Hash)
                      hash[method][key] = merge_conditions(hash[method][key].deep_merge(params[key]))
                    else
                      hash[method][key] = merge_conditions(params[key], hash[method][key])
                    end
                  elsif key == :include && merge
                    hash[method][key] = merge_includes(hash[method][key], params[key]).uniq
                  elsif key == :joins && merge
                    hash[method][key] = merge_joins(params[key], hash[method][key])
                  # begin patch  
                  elsif key == :order && merge
                    hash[method][key] = [params[key], hash[method][key]].reverse.join(' , ')                        
                  # end patch  
                  else
                    hash[method][key] = hash[method][key] || params[key]
                  end
                end
              else
                if action == :reverse_merge
                  hash[method] = hash[method].merge(params)
                else
                  hash[method] = params.merge(hash[method])
                end
              end
            else
              hash[method] = params
          end
          hash
        end
      end

      self.scoped_methods << method_scoping
      begin
        yield
      ensure
        self.scoped_methods.pop
      end
    end
    
  end
end