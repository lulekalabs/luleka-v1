# A Purchase order captures all items of a purchase.
class PurchaseOrder < Order
  #--- assocations
  belongs_to :purchase_invoice, :foreign_key => :invoice_id

  #--- instance methods

  # Authorizes a payment over the order gross amount
  def authorize(payment_object, options={})
    defaults = {:order_id => number}
    options = defaults.merge(options).symbolize_keys
    
    transaction do 
      buyer.send(:before_authorize_payment, self) if buyer && buyer.respond_to?(:before_authorize_payment)
      self.build_addresses
      self.build_invoice unless self.invoice
      authorization_result = self.invoice.authorize(payment_object, options)
      if authorization_result.success?
        process_payment!
      end
      buyer.send(:after_authorize_payment, self) if buyer && buyer.respond_to?(:after_authorize_payment)
      authorization_result
    end
  end

  # Captures the amount of the order that was previously authorized
  # If the capture amount 
  def capture(options={})
    defaults = {:order_id => number}
    options = defaults.merge(options).symbolize_keys
    
    if self.invoice
      buyer.send(:before_capture_payment, self) if buyer && buyer.respond_to?(:before_capture_payment)
      capture_result = self.invoice.capture(options)
      if capture_result.success?
        approve_payment!
      end
      buyer.send(:after_capture_payment, self) if buyer && buyer.respond_to?(:after_capture_payment)
      capture_result
    end
  end
  
  # Pay the order and generate invoice
  def pay(payment_object, options={})
    defaults = { :order_id => number }
    options = defaults.merge(options).symbolize_keys

    # before_payment
    buyer.send( :before_payment, self ) if buyer && buyer.respond_to?( :before_payment )
    
    self.build_addresses
    self.build_invoice unless self.invoice
    
    payment = self.invoice.purchase(payment_object, options)
    if payment.success?
      process_payment!
      approve_payment!
    end
    save!
    # after_payment
    buyer.send( :after_payment, self ) if buyer && buyer.respond_to?( :after_payment )
    payment
  end

  # Voids a previously authorized invoice payment and sets the status to cancel
  # Usage:
  #   void(options = {})
  #
  def void(options={})
    defaults = { :order_id => self[:number] }
    options = defaults.merge(options).symbolize_keys

    if self.invoice
      # before_payment
      buyer.send( :before_void_payment, self ) if buyer && buyer.respond_to?( :before_void_payment )
    
      voided_result = self.invoice.void(options)
      
      if voided_result.success?
        cancel!
      end
      save!
      # after_void_payment
      buyer.send( :after_void_payment, self ) if buyer && buyer.respond_to?( :after_void_payment )
      voided_result
    end
  end

  # refunds a previously paid order
  # Note: :card_number must be supplied
  def refund(options={})
    defaults = { :order_id => number }
    options = defaults.merge(options).symbolize_keys

    if self.invoice && self.invoice.paid?
      # before_payment
      buyer.send( :before_refund_payment, self ) if buyer && buyer.respond_to?( :before_refund_payment )
    
      refunded_result = self.invoice.credit(options)
      if refunded_result.success?
        refund!
      end
      save!
      # after_void_payment
      buyer.send( :after_refund_payment, self ) if buyer && buyer.respond_to?( :after_refund_payment )
      refunded_result
    end
  end
  
  # yes, i am a purchase order!
  def purchase_order?
    true 
  end

  # used in build_invoice to determine which type of invoice
  def to_invoice_class_name
    'PurchaseInvoice'
  end
 
  def invoice
    self.purchase_invoice
  end
  
  def invoice=(an_invoice)
    self.purchase_invoice = an_invoice
  end
  
  def build_invoice #:nodoc:
    new_invoice = self.build_purchase_invoice( 
      :line_items => self.line_items,
      :net_amount => self.net_total,
      :tax_rate => self.tax_rate,
      :tax_amount => self.tax_total,
      :gross_amount => self.gross_total,
      :buyer => self.buyer,
      :seller => self.seller,
      :origin_address => self.origin_address ? self.origin_address.clone : nil,
      :billing_address => self.billing_address ? self.billing_address.clone : nil,
      :shipping_address => self.shipping_address ? self.shipping_address.clone : nil
    )
    
    # set new invoice's line items to invoice we just created
    new_invoice.line_items.each do |li|
      if li.new_record?
        li.invoice = new_invoice
      else
        li.update_attribute(:invoice, new_invoice)
      end
    end
    
    # copy addresses
    new_invoice.build_origin_address(self.origin_address.content_attributes) if self.origin_address
    new_invoice.build_billing_address(self.billing_address.content_attributes) if self.billing_address
    new_invoice.build_shipping_address(self.shipping_address.content_attributes) if self.shipping_address
    
    self.invoice = new_invoice
    
    new_invoice
  end
  
  # Builds billing, shipping and origin addresses
  def build_addresses(options={})
    raise ArgumentError.new("No address declared for buyer (#{buyer.class.name} ##{buyer.id}), use acts_as_addressable :billing") \
      unless buyer.respond_to?(:find_default_address)
    
    # buyer's billing or default address
    unless default_billing_address
      if buyer.respond_to?(:billing_address) && buyer.default_billing_address
        self.build_billing_address(buyer.default_billing_address.content_attributes)
      else
        if buyer_default_address = buyer.find_default_address
          self.build_billing_address(buyer_default_address.content_attributes)
        else
          raise ArgumentError.new(
            "No billing or default address for buyer (#{buyer.class.name} ##{buyer.id}) use acts_as_addressable")
        end
      end
    end

    # buyer's shipping address
    if buyer.respond_to?(:shipping_address)
      self.build_shipping_address(buyer.find_shipping_address_or_clone_from(
        self.billing_address
      ).content_attributes) unless self.default_shipping_address
    end

    # seller's billing or default address
    if seller
      raise ArgumentError.new("No address for seller (#{seller.class.name} ##{seller.id}), use acts_as_addressable") \
        unless seller.respond_to?(:find_default_address)
      
      unless default_origin_address
        if seller.respond_to?(:billing_address) && seller.find_billing_address
          self.build_origin_address(seller.find_billing_address.content_attributes)
        else
          if seller_default_address = seller.find_default_address
            self.build_origin_address(seller_default_address.content_attributes)
          end
        end
      end
    end
  end

end