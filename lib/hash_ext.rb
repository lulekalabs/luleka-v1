module ActiveSupport #:nodoc:
  module CoreExtensions #:nodoc:
    module Hash #:nodoc:
      module RejectKeys

        def reject_keys!(*keys)
          self.reject! {|k,v| keys.to_a.flatten.map(&:to_sym).include?(k.to_sym)}
        end

        def reject_keys(*keys)
          self.reject {|k,v| keys.to_a.flatten.map(&:to_sym).include?(k.to_sym)}
        end

      end

      module FinderOptions
        
        # merges finder options with AND
        def merge_finder_options_with_and(options={})
          result = self.dup
          options.reject! {|k,v| v.blank?}
          result[:select] = [self[:select], options.delete(:select)].compact.join(", ")
          result[:conditions] = ActiveRecord::Base.sanitize_and_merge_conditions_with_and(self[:conditions], options.delete(:conditions))
          result[:order] = ActiveRecord::Base.sanitize_and_merge_order(self[:order], options.delete(:order))
          result[:joins] = ActiveRecord::Base.sanitize_and_merge_joins(self[:joins], options.delete(:joins))
          result.reject {|k,v| v.blank?}.merge(options)
        end
        alias_method :merge_finder_options, :merge_finder_options_with_and

        # merges finder options with OR
        def merge_finder_options_with_or(options={})
          result = self.dup
          options.reject! {|k,v| v.blank?}
          result[:select] = [self[:select], options.delete(:select)].compact.join(", ")
          result[:conditions] = ActiveRecord::Base.sanitize_and_merge_conditions_with_or(self[:conditions], options.delete(:conditions))
          result[:order] = ActiveRecord::Base.sanitize_and_merge_order(self[:order], options.delete(:order))
          result[:joins] = ActiveRecord::Base.sanitize_and_merge_joins(self[:joins], options.delete(:joins))
          result.reject {|k,v| v.blank?}.merge(options)
        end
        
        # merges finder options and changes with AND
        def merge_finder_options_with_and!(options={})
          options.reject! {|k,v| v.blank?}
          self[:select] = [self[:select], options.delete(:select)].compact.join(", ")
          self[:conditions] = ActiveRecord::Base.sanitize_and_merge_conditions_with_and(self[:conditions], options.delete(:conditions))
          self[:order] = ActiveRecord::Base.sanitize_and_merge_order(self[:order], options.delete(:order))
          self[:joins] = ActiveRecord::Base.sanitize_and_merge_joins(self[:joins], options.delete(:joins))
          self.reject! {|k,v| v.blank?}
          self.merge!(options)
        end
        alias_method :merge_finder_options!, :merge_finder_options_with_and!
        
        # merges finder options and changes with OR
        def merge_finder_options_with_or!(options={})
          options.reject! {|k,v| v.blank?}
          self[:select] = [self[:select], options.delete(:select)].compact.join(", ")
          self[:conditions] = ActiveRecord::Base.sanitize_and_merge_conditions_with_or(self[:conditions], options.delete(:conditions))
          self[:order] = ActiveRecord::Base.sanitize_and_merge_order(self[:order], options.delete(:order))
          self[:joins] = ActiveRecord::Base.sanitize_and_merge_joins(self[:joins], options.delete(:joins))
          self.reject! {|k,v| v.blank?}
          self.merge!(options)
        end
        
      end
    end
  end
end

class Hash
  include ActiveSupport::CoreExtensions::Hash::FinderOptions
  include ActiveSupport::CoreExtensions::Hash::RejectKeys
end
