# base module for find_by_query used for search in models:
# Kase, Person, Tier
#
module QueryBase
  def self.included(base)
    base.extend ClassMethods
  end
  
  module ClassMethods
    
    # finder for query, takes string or tokenized query
    #
    # e.g.
    #
    #   ["foo", "bar"]
    #   "foo bar"
    # 
    def find_options_for_find_by_query(query, columns, options={})
      tokenized_query = if query.is_a?(Array)
        query
      else
        query ? Tag.parse(query, :delimiter => " ") : []
      end

      finder_options = {:select => [], :joins => [], :conditions => [], :order => []}

      # add taggable options
      if respond_to?(:find_tagged_with)
        tagged_options = find_options_for_find_tagged_with(tokenized_query)
        finder_options[:select] << tagged_options[:select] if tagged_options[:select]
        finder_options[:conditions] << tagged_options[:conditions] if tagged_options[:conditions]
        finder_options[:order] << tagged_options[:order] if tagged_options[:order]
        finder_options[:joins] << tagged_options[:joins] if tagged_options[:joins]
      end

      # add each column with AND
      columns.each do |column|
        localized_facets(column).each do |facet|
          conditions = []
          tokenized_query.each do |token|
            conditions << sanitize_sql(["#{table_name}.#{facet} LIKE ?", "%#{token}%"])
          end
          finder_options[:conditions] << "(#{conditions.compact.join(" OR ")})" unless conditions.compact.blank?
        end
      end
      
      # merger compounds of finder options
      finder_options[:select] = finder_options[:select].reject(&:blank?).join(', ')
      finder_options[:order] = finder_options[:order].reject(&:blank?).join(', ')
      finder_options[:joins] = finder_options[:joins].reject(&:blank?).join(' ')
      finder_options[:conditions] = finder_options[:conditions].reject(&:blank?).join(' OR ')

      # add active conditions and remove blanks
      finder_options = finder_options.merge_finder_options_with_or(find_class_options_for_query_with_or(query, options))
      finder_options = finder_options.merge_finder_options_with_and(find_class_options_for_query_with_and(query, options))
      
      finder_options.reject! {|k,v| v.blank?}
      finder_options
    end
    
    # custom class query find options that will be joined with AND
    # can be overridden in class
    def find_class_options_for_query_with_and(query, options={})
      options
    end

    # custom class query find options that will be joined with OR
    # can be overridden in class
    def find_class_options_for_query_with_or(query, options={})
      options
    end

    # columns that the find_by_query should include in the search
    def find_by_query_columns
      raise "override in model as find_by_query_columns, e.g. return ['name', 'description']"
    end

    # finder options for tagged based search
    def find_options_for_query(query, options={})
      find_options_for_find_by_query(query, find_by_query_columns, options)
    end

    # finder for tagged based search including colums by giving a string or an array of tags
    def find_by_query(selector, query, options={})
      find(selector, find_options_for_query(query, options))
    end

    # dito, returns all results
    def find_all_by_query(query, options={})
      find_by_query(:all, query, options)
    end
    
  end
  
end
