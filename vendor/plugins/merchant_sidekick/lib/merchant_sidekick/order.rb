# Orders are either:
#
#   * PurchaseOrder: a user buys a purchasable (e.g. product)
#   * SalesOrder: an person sells a purchasable (e.g. product)
#
class Order < ActiveRecord::Base
  #--- associations
  belongs_to :seller, :polymorphic => true
  belongs_to :buyer, :polymorphic => true
  has_many   :line_items, :dependent => :destroy
  has_many   :payments, :as => :payable
  
  # mixins
  money :net_amount,   :cents => :net_cents,   :currency => :currency             # net amount
  money :tax_amount,   :cents => :tax_cents,   :currency => :currency             # tax amount
  money :gross_amount, :cents => :gross_cents, :currency => :currency         # gross amount

  acts_as_addressable :origin, :billing, :shipping, :has_one => true
  acts_as_state_machine :initial => :created, :column => 'status'

  #--- states
  state :created
  state :pending, :enter => :enter_pending
  state :approved, :enter => :enter_approved
  state :shipping, :enter => :enter_shipping
  state :shipped, :enter => :enter_shipped
  state :received, :enter => :enter_received
  state :returning, :enter => :enter_returning
  state :returned, :enter => :enter_returned
  state :refunded, :enter => :enter_refunded
  state :canceled, :enter => :enter_canceled
  
  #--- events
  event :process_payment do
    transitions :from => :created, :to => :pending, :guard => :guard_process_payment_from_created
  end

  event :approve_payment do
    transitions :from => :pending, :to => :approved, :guard => :guard_approve_payment_from_pending
  end

  event :process_shipping do
    transitions :from => :approved, :to => :shipping, :guard => :guard_process_shipping_from_approved
  end

  event :ship do
    transitions :from => :shipping, :to => :shipped, :guard => :guard_ship_from_shipping
  end

  event :confirm_reception do
    transitions :from => :shipped, :to => :received, :guard => :guard_confirm_reception_from_shipped
  end

  event :reject do
    transitions :from => :received, :to => :returning, :guard => :guard_reject_from_received
  end

  event :confirm_return do
    transitions :from => :returning, :to => :returned, :guard => :guard_confirm_return_from_returning
    transitions :from => :shipped, :to => :returned, :guard => :guard_confirm_return_from_shipped
  end

  event :refund do
    transitions :from => :returned, :to => :refunded, :guard => :guard_refund_from_returned
  end

  event :cancel do
    transitions :from => :created, :to => :canceled, :guard => :guard_cancel_from_created
    transitions :from => :pending, :to => :canceled, :guard => :guard_cancel_from_pending
  end
  
  #--- callbacks
  before_save :total, :number

  # state transition callbacks, to be overwritten 
  def enter_pending; end
  def enter_approved; end
  def enter_shipping; end
  def enter_shipped; end
  def enter_received; end
  def enter_returning; end
  def enter_returned; end
  def enter_refunded; end
  def enter_canceled; end

  # event guard callbacks, to be overwritten
  def guard_process_payment_from_created; true; end
  def guard_approve_payment_from_pending; true; end
  def guard_process_shipping_from_approved; true; end
  def guard_ship_from_shipping; true; end
  def guard_confirm_reception_from_shipped; true; end
  def guard_reject_from_received; true; end
  def guard_confirm_return_from_returning; true; end
  def guard_confirm_return_from_shipped; true; end
  def guard_refund_from_returned; true; end
  def guard_cancel_from_created; true; end
  def guard_cancel_from_pending; true; end

  #--- class methods
  
  class << self

    # hex digest 16 char in length
    def generate_unique_id
      Digest::MD5.hexdigest("#{Time.now.utc.to_i}#{rand(2 ** 128)}")[0..6]
    end
    
  end

  #--- instance methods

  def number
    self[:number] ||= Order.generate_unique_id
  end

  # abstract overriden in sublcasses
  # returns the invoice instance
  def invoice
    raise "override in purchase_order or sales_order"
  end

  # abstract to be overriden inside puchase and sales orders
  def build_invoice
    raise "override in purchase_order or sales_order"
  end

  # Builds billing, shipping and origin addresses
  def build_addresses(options={})
    raise "override in purchase_order or sales_order"
  end

  # Net total amount
  def net_total 
    self.net_amount = line_items.inject(0.to_money) {|sum,l| sum + l.net_amount }
  end
  
  # Calculates tax and sets the tax_amount attribute
  # It adds tax_amount across all line_items
  def tax_total
    self.tax_amount = line_items.inject(0.to_money) {|sum,l| sum + l.tax_amount }
    self.tax_rate # calculates average rate, leave for compatibility reasons
    self.tax_amount
  end

  # Since each line_item has it's own tax_rate now, we will calculate
  # the average tax_rate across all line items and store it in the database
  # The attribute tax_rate will not have any relevance in Order/Invoice to 
  # calculate the tax_amount anymore
  def tax_rate
    write_attribute( :tax_rate, Float(line_items.inject(0) {|sum, l| sum + l.tax_rate}) / line_items.size)
  end
  
  # Gross amount including tax
  def gross_total
    self.gross_amount = self.net_total + self.tax_total
  end
  
  # Same as gross_total with tax
  def total
    self.gross_total
  end

  # is the number of line items stored in the order, though not to be 
  # confused by the items_count
  def line_items_count
    self.line_items.size
  end
  
  # total number of items purchased
  def items_count
    counter = 0
    self.line_items.each do |item|
      if item.sellable && item.sellable.respond_to?(:quantity)
        counter += item.sellable.quantity
      else
        counter += 1
      end
    end
    counter
  end

  # updates the order and all contained line_items after an address has changed
  # or an order item was added or removed. The order can only be evaluated if the
  # created state is active. The order is saved if it is an existing order. 
  # Returns true if evaluation happend, false if not.
  def evaluate
    if :created == current_state
      self.line_items.each(&:evaluate)
      self.calculate
      return save(false) unless new_record?
    end
    false
  end

  # adds a line item or sellable to order and updates the order
  def push(an_item_or_sellable)
    if !an_item_or_sellable.is_a?(LineItem) && an_item_or_sellable.respond_to?(:price)
      li = LineItem.new(:sellable => an_item_or_sellable, :order => self)
    elsif an_item_or_sellable.is_a?(LineItem)
      li = an_item_or_sellable
    end
    if li
      self.line_items.push(li)
      self.evaluate
    end
  end

  protected

  # Recalculates the order, adding order lines, tax and gross totals
  def calculate
    self.net_amount = nil
    self.tax_amount = nil
    self.gross_amount = nil
    self.tax_rate = nil
    self.total
  end
  
  # override in subclass
  def to_invoice_class_name
  end

  # override in subclass
  def purchase_order?
    false
  end

  # override in subclass
  def sales_order?
    false
  end
  
end