module ActionView
  module Helpers
    module RecordIdentificationHelper

      #--- these were added in probono to RecordIdentifierHelpers
      def singular_class_name(*args, &block)
        ActionController::RecordIdentifier.singular_class_name(*args, &block)
      end
      
      def plural_class_name(*args, &block)
        ActionController::RecordIdentifier.plural_class_name(*args, &block)
      end
      
    end
  end
end

ActionView::Base.class_eval do
  include ActionView::Helpers::RecordIdentificationHelper
end
