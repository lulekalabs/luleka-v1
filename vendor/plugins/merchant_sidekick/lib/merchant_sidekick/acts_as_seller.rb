module Merchant #:nodoc:
  module Sidekick #:nodoc:
    module Seller #:nodoc:

      def self.included(mod)
        mod.extend(ClassMethods)
      end

      module ClassMethods
        def acts_as_seller(options={})
          include Merchant::Sidekick::Seller::InstanceMethods
          class_eval do
            has_many :orders, :as => :seller, :dependent => :destroy
            has_many :invoices, :as => :seller, :dependent => :destroy
            has_many :sales_orders, :as => :seller
            has_many :sales_invoices, :as => :seller
          end
        end
      end
      
      module InstanceMethods
        
        def sell_to(buyer, *arguments)
          sell(arguments, :buyer => buyer)
        end
        
        protected
        
        # Sell sellables (line_items) and add them to a sales order
        # The seller will be this person.
        #
        # e.g.
        #
        #   seller.sell(@product, :buyer => @buyer)
        # 
        def sell(*arguments)
          sellables = []
          options = default_sell_options

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
              
          returning self.sales_orders.build do |so|
            so.buyer = options[:buyer]
            so.build_addresses
            
            sellables.each do |sellable|
              if sellable && sellable.respond_to?(:before_add_to_order)
                sellable.send(:before_add_to_order, self)
                sellable.reload unless sellable.new_record?
              end
              li = LineItem.new(:sellable => sellable, :order => so)
              so.line_items.push(li)
              sellable.send(:after_add_to_order, self) if sellable && sellable.respond_to?(:after_add_to_order)
            end
            
          end
        end
        
        # override in model, e.g. :buyer => @person
        def default_sell_options
          {}
        end
        
      end
    end
  end
end
