# Invoices are invoices are invoices that are invoices :-)
class Invoice < ActiveRecord::Base
  include ActionView::Helpers::TextHelper

  #--- accessors
  attr_accessor :authorization

  #--- associations
  belongs_to :seller, :polymorphic => true  # originator
  belongs_to :buyer, :polymorphic => true  # buyer or seller
  has_many   :line_items
  has_many   :orders
  has_many   :payments, :as => :payable, :dependent => :destroy
  
  #--- mixins
  money :net_amount,   :cents => :net_cents,   :currency => :currency         # net amount
  money :tax_amount,   :cents => :tax_cents,   :currency => :currency         # tax amount
  money :gross_amount, :cents => :gross_cents, :currency => :currency         # gross amount

  acts_as_addressable :origin, :billing, :shipping, :has_one => true
  acts_as_state_machine :initial => :pending, :column => 'status'

  #--- states
  state :pending, :enter => :enter_pending
  state :authorized, :enter => :enter_authorized
  state :paid, :enter => :enter_paid
  state :voided, :enter => :enter_voided
  state :refunded, :enter => :enter_refunded
  state :payment_declined, :enter => :enter_payment_declined

  #--- events
  event :payment_paid do
    transitions :from => :pending, :to => :paid, :guard => :guard_payment_paid_from_pending
  end
  
  event :payment_authorized do
    transitions :from => :pending, :to => :authorized, :guard => :guard_payment_authorized_from_pending
    transitions :from => :payment_declined, :to => :authorized, :guard => :guard_payment_authorized_from_payment_declined
  end

  event :payment_captured do
    transitions :from => :authorized, :to => :paid, :guard => :guard_payment_captured_from_authorized
  end

  event :payment_voided do
    transitions :from => :authorized, :to => :voided, :guard => :guard_payment_voided_from_authorized
  end

  event :payment_refunded do
    transitions :from => :paid, :to => :refunded, :guard => :guard_payment_refunded_from_paid
  end

  event :transaction_declined do
    transitions :from => :pending, :to => :payment_declined, :guard => :guard_transaction_declined_from_pending
    transitions :from => :payment_declined, :to => :payment_declined, :guard => :guard_transaction_declined_from_payment_declined
    transitions :from => :authorized, :to => :authorized, :guard => :guard_transaction_declined_from_authorized
  end
  
  #--- callbacks
  before_save :number
  
  # state transition callbacks
  def enter_pending; end
  def enter_authorized; end
  def enter_paid; end
  def enter_voided; end
  def enter_refunded; end
  def enter_payment_declined; end
  
  # event guard callbacks
  def guard_transaction_declined_from_authorized; true; end
  def guard_transaction_declined_from_payment_declined; true; end
  def guard_transaction_declined_from_pending; true; end
  def guard_payment_refunded_from_paid; true; end
  def guard_payment_voided_from_authorized; true; end
  def guard_payment_captured_from_authorized; true; end
  def guard_payment_authorized_from_payment_declined; true; end
  def guard_payment_authorized_from_pending; true; end
  def guard_payment_paid_from_pending; true; end
  
  #--- instance methods

  def number
    self[:number] ||= Order.generate_unique_id
  end

  # returns a hash of additional merchant data passed to authorize
  # you want to pass in the following additional options
  #
  #   :ip => ip address of the buyer
  #   
  def payment_options(options={})
    {}.merge(options)
  end
  
  # Reader to be order compatible
  def gross_total
    send(:gross_amount) if respond_to?(:gross_amount)
  end
  
  # Same as gross_total with tax
  def total
    self.gross_total
  end
  
  # Reader to be order compatible
  def net_total
    send(:net_amount) if respond_to?(:net_amount)
  end

  # Reader to be order compatible
  def tax_total
    send(:tax_amount) if respond_to?(:tax_amount)
  end

  # From payments, returns :credit_card, etc.
  def payment_type
    payments.first.payment_type if payments
  end
  alias_method :payment_method, :payment_type

  # Human readable payment type
  def payment_type_display
    self.payment_type.to_s.titleize
  end
  alias_method :payment_method_display, :payment_type_display

  protected

  # override in subclass
  def purchase_invoice?
    false
  end

  # marks sales invoice, override in subclass
  def sales_invoice?
    false
  end

  def push_payment(a_payment)
    a_payment.payable = self
    self.payments.push(a_payment)
  end
  
end
