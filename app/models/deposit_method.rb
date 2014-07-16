# Encapsulates data for available deposit methods. Today we support:
#
#   * Paypal
#
class DepositMethod < TransactionMethod
  #--- accessors
  attr_accessor :transaction_fee_cents
  attr_accessor :min_transfer_amount_cents
  attr_accessor :max_transfer_amount_cents
  
  #--- constants
  DEFAULT_MIN_TRANSFER_AMOUNT_CENTS = 100
  DEFAULT_MAX_TRANSFER_AMOUNT_CENTS = 10000
  TRANSACTION_METHODS = [{ 
    :type => :paypal,
    :active_merchant_type => nil,
    :help_example => 'john@smith.com',
    :image => '/images/icons/payment-methods/paypal.png',
    :help_image => nil,
    :transaction_fee_cents => 50, 
    :min_transfer_amount_cents => DEFAULT_MIN_TRANSFER_AMOUNT_CENTS, 
    :max_transfer_amount_cents => DEFAULT_MAX_TRANSFER_AMOUNT_CENTS, 
    :caption => "Paypal",
    :klass => PaypalDepositAccount,
    :partial => 'shared/paypal_entry'
  }].freeze
  
  #--- class methods
  class << self
    
    # returns the payment klass of the given type
    def klass(deposit_method_type)
      klass = select_from_hash_array(TRANSACTION_METHODS, :klass, :type => deposit_method_type.to_sym)
      klass ? klass.to_s.constantize : nil
    end
    
    # returns an array of deposit objects, limited by :only or :except options
    def objects(options={})
      select_from_hash_array(TRANSACTION_METHODS, :type, {}, options).map {|t| new(t)}
    end
    
    # returns an array of supported types
    # e.g. [:visa, :mastercard]
    def types(options={})
      select_from_hash_array(TRANSACTION_METHODS, :type, {}, options)
    end
    
    def select_from_deposit_methods(key=nil, where={}, options={})
      select_from_transaction_methods(key, where, options)
    end
    
    # returns the help example
    def partial(method_type)
      select_from_hash_array(TRANSACTION_METHODS, :partial, :type => method_type.to_sym)
    end

    # returns the image
    def caption(method_type)
      select_from_hash_array(TRANSACTION_METHODS, :caption, :type => method_type.to_sym)
    end
    
    # returns the image
    def image(method_type)
      select_from_hash_array(TRANSACTION_METHODS, :image, :type => method_type.to_sym)
    end

    # returns the help example
    def help_example(method_type)
      select_from_hash_array(TRANSACTION_METHODS, :help_example, :type => method_type.to_sym)
    end

    # returns the help example
    def help_image(method_type)
      select_from_hash_array(TRANSACTION_METHODS, :help_image, :type => method_type.to_sym)
    end
    
    # returns the transaction fee in cents, without currency
    def transaction_fee_cents(method_type)
      select_from_hash_array(TRANSACTION_METHODS, :transaction_fee_cents, :type => method_type.to_sym)
    end
    
    def min_transfer_amount_cents(method_type=nil)
      method_type ? select_from_hash_array(
        TRANSACTION_METHODS, :min_transfer_amount_cents, :type => method_type.to_sym
      ) || DEFAULT_MIN_TRANSFER_AMOUNT_CENTS : DEFAULT_MIN_TRANSFER_AMOUNT_CENTS
    end

    def max_transfer_amount_cents(method_type=nil)
      method_type ? select_from_hash_array(
        TRANSACTION_METHODS, :max_transfer_amount_cents, :type => method_type.to_sym
      ) || DEFAULT_MAX_TRANSFER_AMOUNT_CENTS : DEFAULT_MAX_TRANSFER_AMOUNT_CENTS
    end
    
  end
  
  #--- instance methods
  
  def initialize(deposit_method_type)
    super(deposit_method_type, TRANSACTION_METHODS)
    @transaction_fee_cents = select_from_hash_array(
      TRANSACTION_METHODS, :transaction_fee_cents, :type => deposit_method_type.to_sym
    )
    @min_transfer_amount_cents = select_from_hash_array(
      TRANSACTION_METHODS, :min_transfer_amount_cents, :type => deposit_method_type.to_sym
    )
    @max_transfer_amount_cents = select_from_hash_array(
      TRANSACTION_METHODS, :max_transfer_amount_cents, :type => deposit_method_type.to_sym
    )
  end
  
end