# Extends the invoice from merchant_sidekick plugin
require 'digest/sha2'
class Invoice < ActiveRecord::Base

  #--- class methods
  class << self

    # removes all extra formatting from a number, used in finder
    def strip_number_formatting(number)
      number.gsub('-', '') if number
    end
    
  end

  #--- instance methods
  
  # intercepts seller, so in case there is no seller specified and 
  # this is a purchase invoice, the seller is us
  def seller_with_cache
    if self.purchase_invoice? && !self.seller_without_cache
      @seller_cache || @seller_cache = Organization.probono
    else
      self.seller_without_cache
    end
  end
  alias_method_chain :seller, :cache
  
  # same for origin address, if there is no origin address and
  # this is a purchase invoice, it is our address we are returning
  def origin_address_with_cache
    if self.purchase_invoice? && !self.origin_address_without_cache
      @origin_address_cache || @origin_address_cache = Organization.probono ? Organization.probono.address : nil
    else
      self.origin_address_without_cache
    end
  end
  alias_method_chain :origin_address, :cache
  
  # formats the order number in 6 groups, 
  #
  # e.g.
  #
  #   a4-1793f7-6125f9-032a10-415705-b20a66 
  #
  def number_with_formatting
    number_without_formatting
  end
  alias_method_chain :number, :formatting
  
  # short number with identifier
  #
  # e.g.
  #
  #   PI-23ab32
  #
  def short_number
    "#{self.is_a?(PurchaseInvoice) ? 'PI' : (self.is_a?(SalesInvoice) ? 'SI' : 'IN') }-#{number_without_formatting}"
  end
 
  # overrides human readable payment type
  # e.g. credit card, piggy bank
  def payment_type_s
    self.payment_type.to_s.titleize
  end
 
  # translated human readable payment type, e.g. 'kreditkarte'
  def payment_type_t
    self.payment_type_s.t
  end
  alias_method :payment_method_t, :payment_type_t
  
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