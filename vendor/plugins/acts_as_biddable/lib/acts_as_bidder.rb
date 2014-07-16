module Probono #:nodoc:
  module Acts #:nodoc:
    module Bidder #:nodoc:

      def self.included(mod)
        mod.extend(ClassMethods)
      end

      module ClassMethods
        def acts_as_bidder(opts={})
          options = options_for_bidder(opts)
          include Probono::Acts::Bidder::InstanceMethods
          extend Probono::Acts::Bidder::SingletonMethods

          has_many :bids, :foreign_key => :bidder_id
        end
        
        def options_for_bidder(opts={})
          {
             :biddables => {}
          }.merge(opts)
        end
      end
      
      # This module contains class methods
      module SingletonMethods
      end
      
      # This module contains instance methods
      module InstanceMethods
        
        # Call the bid method of biddable
        def bid(a_bid, a_biddable)
          return false if a_biddable.nil?
          begin
            a_biddable.bid(a_bid, self)
          rescue NoMethodError
            return false
          end
        end
        
        # Am I the winning bidder?
        def winning_bidder?(a_biddable)
          if winner=a_biddable.find_winning_bidder
            return true if winner.id==self.id
          end
          false
        end
        
      end
      
    end
  end
end