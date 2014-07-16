# Enhances the order from merchant_sidekick with callback from the state 
# machine. This will enable us to add notifiers and other stuff to intefere
# with orders.
require 'digest/sha2'
class Order < ActiveRecord::Base

  #--- validations

  #--- callbacks

  #--- state transition callbacks
  def enter_pending
#    OrderMailer.deliver_confirmation(self) if self.invoice.authorized?
  end
  
  def enter_approved
  end
  
  def enter_shipping
  end
  
  def enter_shipped
#    OrderMailer.deliver_shipped(self)
  end
  
  def enter_received
  end
  
  def enter_returning
  end
  
  def enter_returned
  end
  
  def enter_refunded
  end
  
  def enter_canceled
#    OrderMailer.deliver_canceled(self)
  end

  #--- class methods
  class << self

    # removes all extra formatting from a number, used in finder
    def strip_number_formatting(number)
      number.gsub('-', '') if number
    end
  end

  #--- instance methods
  
  # formats the order number in 6 groups, e.g.
  # a4-1793f7-6125f9-032a10-415705-b20a66 
  def number_with_formatting
    number_without_formatting
  end
  alias_method_chain :number, :formatting
  
  def short_number
    "#{self.is_a?(PurchaseOrder) ? 'PO' : (self.is_a?(SalesOrder) ? 'SO' : 'OR') }-#{number_without_formatting}"
  end

  # returns string representation of current_state
  def current_state_s
    self.current_state.to_s.humanize.downcase
  end
  
  # translated current state
  def current_state_t
    self.current_state_s.t
  end
  
  def to_param
    "#{self.number}"
  end
  
end

class PurchaseOrder

  # updates an existing purchase order with origin address from person or address
  def update_origin_address_from(seller_or_address)
    if seller_or_address.is_a?(Person) and seller = seller_or_address
      raise "No address declared in seller #{seller.class.name} ##{seller.id}, use acts_as_addressable" \
        unless seller.respond_to?(:find_default_address)
      
      options = (seller.respond_to?(:billing_address) && seller.billing_address ? seller.billing_address : seller.find_default_address).content_attributes
      options.merge!({
        :company_name => self.seller && self.seller.is_a?(Organization) ? self.seller.name : nil,
        :first_name => self.seller && self.seller.respond_to?(:first_name) ? self.seller.first_name : nil,
        :last_name => self.seller && self.seller.respond_to?(:last_name) ? self.seller.last_name : nil
      }.reject {|k,v| v.nil?})
      
      if self.origin_address
        self.origin_address.attributes = options
      else
        self.build_origin_address(options)
      end
      self.origin_address.save
    elsif seller_or_address.is_a?(Address) and address = seller_or_address
      if self.origin_address
        self.origin_address.attributes = address.content_attributes
      else
        self.build_origin_address(address.content_attributes)
      end
      self.origin_address.save
    end
  end
  
  def build_addresses_with_billing_name(options={})
    self.build_addresses_without_billing_name(options)

    self.billing_address.attributes = {
      :company_name => self.buyer && self.buyer.is_a?(Organization) ? self.buyer.name : nil,
      :first_name => self.buyer && self.buyer.respond_to?(:first_name) ? self.buyer.first_name : nil,
      :last_name => self.buyer && self.buyer.respond_to?(:last_name) ? self.buyer.last_name : nil
    }.reject {|k,v| v.nil?} if self.billing_address

    self.origin_address.attributes = {
      :company_name => self.seller && self.seller.is_a?(Organization) ? self.seller.name : nil,
      :first_name => self.seller && self.seller.respond_to?(:first_name) ? self.seller.first_name : nil,
      :last_name => self.seller && self.seller.respond_to?(:last_name) ? self.seller.last_name : nil
    }.reject {|k,v| v.nil?} if self.origin_address
    
  end
  alias_method_chain :build_addresses, :billing_name
  
end

class SalesOrder
  
  def build_addresses_with_billing_name(options={})
    self.build_addresses_without_billing_name(options)

    self.billing_address.attributes = {
      :company_name => self.buyer && self.buyer.is_a?(Organization) ? self.buyer.name : nil,
      :first_name => self.buyer && self.buyer.respond_to?(:first_name) ? self.buyer.first_name : nil,
      :last_name => self.buyer && self.buyer.respond_to?(:last_name) ? self.buyer.last_name : nil
    }.reject {|k,v| v.nil?} if self.billing_address
    
    self.origin_address.attributes = {
      :company_name => self.seller && self.seller.is_a?(Organization) ? self.seller.name : nil,
      :first_name => self.seller && self.seller.respond_to?(:first_name) ? self.seller.first_name : nil,
      :last_name => self.seller && self.seller.respond_to?(:last_name) ? self.seller.last_name : nil
    }.reject {|k,v| v.nil?} if self.origin_address
    
  end
  alias_method_chain :build_addresses, :billing_name
  
end

