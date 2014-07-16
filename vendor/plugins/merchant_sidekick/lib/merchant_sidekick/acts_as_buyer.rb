module Merchant #:nodoc:
  module Sidekick #:nodoc:
    module Buyer #:nodoc:

      def self.included(mod)
        mod.extend(ClassMethods)
      end

      module ClassMethods
        def acts_as_buyer
          include Merchant::Sidekick::Buyer::InstanceMethods
          class_eval do
            has_many :orders, :as => :buyer, :dependent => :destroy
            has_many :invoices, :as => :buyer, :dependent => :destroy
            has_many :purchase_orders, :as => :buyer
            has_many :purchase_invoices, :as => :buyer
          end
        end
      end
      
      module InstanceMethods
        
        # like purchase but forces the seller parameter, instead of 
        # taking it as a :seller option
        def purchase_from(seller, *arguments)
          purchase(arguments, :seller => seller)
        end
        
        # purchase creates a purchase order based on
        # the given sellables, e.g. product, or basically
        # anything that has a price attribute.
        #
        # e.g.
        #
        #   buyer.purchase(product, :seller => seller)
        #
        def purchase(*arguments)
          sellables = []
          options = default_purchase_options

          # distinguish between options and attributes
          arguments = arguments.flatten
          arguments.each do |argument|
            case argument.class.name
            when 'Hash'
              options.merge! argument
            else
              sellables << argument
            end
          end
          raise ArgumentError.new("No sellable (e.g. product) model provided") if sellables.empty?
          raise ArgumentError.new("Sellable models must have a :price") unless sellables.all? {|sellable| sellable.respond_to? :price}
              
          returning self.purchase_orders.build do |po|
            po.seller = options[:seller]
            po.build_addresses
            sellables.each do |sellable|
              if sellable && sellable.respond_to?(:before_add_to_order)
                sellable.send(:before_add_to_order, self)
                sellable.reload unless sellable.new_record?
              end
              li = LineItem.new(:sellable => sellable, :order => po)
              po.line_items.push(li)
              sellable.send(:after_add_to_order, self) if sellable && sellable.respond_to?(:after_add_to_order)
            end
          end
        end
        
        protected
        
        # override in model, e.g. :seller => @person
        def default_purchase_options
          {}
        end
        
      end
    end
  end
end