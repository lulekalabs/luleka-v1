module Probono #:nodoc:
  module Acts #:nodoc:
    module Pollable #:nodoc:

      def self.included(mod)
        mod.extend(ClassMethods)
      end

      module ClassMethods
        def acts_as_poller
          class_eval do
            has_many :countings, :foreign_key => :participant_id
            has_many :outcomes, :through => :countings
            has_many :polls, :through => :countings 
          end
        end
      end
    end
  end
end