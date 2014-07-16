# fixes Rails association proxy bug
# this happened to me when a plugin references a model defined in the main app
#
# http://rails.lighthouseapp.com/projects/8994/tickets/229-raise_on_type_mismatch-expected-user-got-user#ticket-229-1
module ActiveRecord
  module Associations
    class AssociationProxy #:nodoc:
      
      private

      # patch
      def raise_on_type_mismatch(record)
        unless record.is_a?(@reflection.klass) || record.is_a?(eval(@reflection.class_name))
          raise ActiveRecord::AssociationTypeMismatch, "#{@reflection.class_name} (class id=#{@reflection.klass.object_id}) expected, got #{record.class} (class id=#{record.class.object_id})"
        end
      end
      
    end
  end
end