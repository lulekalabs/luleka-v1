module Probono #:nodoc
  module Acts #:nodoc:
    module Biddable #:nodoc:

      def self.included(base)
        base.extend ClassMethods
      end

      module ClassMethods
        def acts_as_biddable(opts={})
          options = options_for_biddable(opts)
          include Probono::Acts::Biddable::InstanceMethods
          extend Probono::Acts::Biddable::SingletonMethods

          has_many :bids, :as => :biddable, :dependent => :destroy
          has_many :bidders, :through => :bids, :foreign_key => :bidder_id
          
          write_inheritable_attribute :increment_cents, options[:increment]
          write_inheritable_attribute :minimum_bid_cents, options[:minimum]
          write_inheritable_attribute :current_bid_attribute, options[:attribute]
          write_inheritable_attribute :current_bid_cents, reflect_on_all_aggregations.find {|i| i=options[:attribute]}.options[:mapping].first.first
          
          
          class_inheritable_reader    :increment_cents
          class_inheritable_reader    :minimum_bid_cents
          class_inheritable_reader    :current_bid_attribute
          class_inheritable_reader    :current_bid_cents
          
          
          class_eval do
          end

        end

      private
        def options_for_biddable(opts={})
          {
            :auction_type  => :proxy_bid, 
            :reverse       => true,
            :increment     => 50,
            :minimum       => 200,
            :attribute     => :current_bid
          }.merge(opts)
        end
      
      end
      
      # This module contains class methods
      module SingletonMethods

        class BiddableError < Exception
        end

      end
      
      # This module contains instance methods
      module InstanceMethods


        # Bid for this biddable according to the auction method defined as type.
        # Calls callback functions before_outbid() and after_outbid() in biddable
        # in order to intersect.
        # Usage:
        #   bid( Money.new(1000, "EUR"), person )
        # Returns:
        #   true, if bidder has the winning bid, and false if not
        def bid(a_bid, a_bidder)
          raise BiddableError("Bidder required") if a_bidder.nil?
          raise BiddableError("Bid is not a Currency") unless Money==a_bid.class

          unless self.currency==a_bid.currency
            Money.bank.add_rate(a_bid.currency, self.currency, ExchangeRate.get_rate(a_bid.currency, self.currency))
          end
          
          if a_bid>Money.new(self.class.minimum_bid_cents, self.currency)
            if 0==bids.size
              # Initial bid
              the_bid = Money.new(1, self.currency) + a_bid - Money.new(1, self.currency)
              bids.create(:bid => the_bid, :current_bid => the_bid, :bidder_id => a_bidder.id)
              update_attribute(self.class.current_bid_attribute, the_bid)
              return true
            else
              if a_bid<current_bid
                if lowest=bids.find(:first, :order => "bid_cents ASC")
                  raise BiddableError("Bidder holds the bid already.".t) if lowest.bidder_id==a_bidder.id
                  if a_bid<lowest.bid
                    # trigger before_outbid
                    lowest.bidder.send( :before_outbid, self ) if lowest.bidder.respond_to? :before_outbid
                    
                    the_bid = Money.new(1, self.currency) + a_bid - Money.new(1, self.currency)
                    new_current_bid = increment_ceiling(lowest.bid, Money.new(self.class.minimum_bid_cents, self.currency))

                    # trigger after_outbid
                    lowest.bidder.send( :after_outbid, self ) if lowest.bidder.respond_to? :after_outbid
                  elsif a_bid>=lowest.bid
                    # -> adjust the current_bid price
                    the_bid = Money.new(1, self.currency) + a_bid - Money.new(1, self.currency)
                    new_current_bid = increment_ceiling(a_bid, lowest.bid)
                  end
                  bids.create(:bid => the_bid, :current_bid => new_current_bid, :bidder_id => a_bidder.id)
                  update_attribute(self.class.current_bid_attribute, new_current_bid)
                  return a_bid<lowest.bid
                end
              end
            end
          end
          false
        end

        # What is the winning bid?
        # Returns the bid object
        def find_winning_bid
          return nil if 0==bids.size
          bids.find(:first, :order => "bid_cents ASC, created_at ASC")
        end

        # Who is the current lowest/highest bidder
        # Returns the bidder (person) if any
        def find_winning_bidder
          if b=find_winning_bid
            return b.bidder
          end
          nil
        end
        
        # Finds the bid of the supplied bidder
        # Needed for cases where you need to determine 
        def find_bid_of_bidder(a_bidder)
          bids.find(:first, :conditions => ["bidder_id=?", a_bidder.id], :order => "bid_cents ASC, created_at ASC")
        end

        # Get the current winning bid amount
        def current_bid
          return nil if 0==bids.size
          Money.new(self.read_attribute(self.class.current_bid_cents), self.currency)
        end
        
      private
      
        # Returns the smallest possible of a_currency - increment and minimum
        def increment_ceiling(a_currency, min_currency)
          increment = Money.new(1, self.currency) + a_currency - min_currency - Money.new(1, self.currency)
          # abs
          if increment.cents<0
            increment *= -1
          end
          if increment>Money.new(self.class.increment_cents, self.currency)
            return Money.new(1, self.currency) + a_currency - Money.new(self.class.increment_cents, self.currency) - Money.new(1, self.currency)
          elsif increment.zero?
            return Money.new(1, self.currency) + min_currency - Money.new(1, self.currency)
          else
            return Money.new(1, self.currency) + a_currency - (increment / 2) - Money.new(1, self.currency)
          end
        end

      end
    end
  end
end
