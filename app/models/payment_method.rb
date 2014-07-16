# Encapsulates data for available payment methods and acts as a 
# factory to instantiate a payment method of type:
#
#   * Credit Cards (:visa, :mastercard, etc.)
#   * Piggy Bank
#
class PaymentMethod < TransactionMethod
  
  #--- constants
  TRANSACTION_METHODS = [{
    :type => :piggy_bank,
    :active_merchant_type => nil,
    :help_example => nil,
    :image => '/images/icons/payment-methods/piggy_bank.png',
    :help_image => nil,
    :caption => "#{SERVICE_PIGGYBANK_NAME}",
    :klass => PiggyBankAccount,
    :partial => 'shared/piggy_bank_payment'
  }, {
    :type => :mastercard,
    :active_merchant_type => 'master', 
    :help_example => '1234 5678 9012 3456',
    :image => '/images/icons/payment-methods/mastercard.png',
    :help_image => '/images/icons/payment-methods/cvv_mastercard.png',
    :caption => "MasterCard",
    :klass => ActiveMerchant::Billing::CreditCard,
    :partial => 'shared/credit_card_entry'
  }, {
    :type => :visa,
    :active_merchant_type => 'visa',
    :help_example => '1234 5678 9012 3456',
    :image => '/images/icons/payment-methods/visa.png',
    :help_image => '/images/icons/payment-methods/cvv_visa.png',
    :caption => "Visa",
    :klass => ActiveMerchant::Billing::CreditCard,
    :partial => 'shared/credit_card_entry'
  }, {
    :type => :amex,
    :active_merchant_type => 'american_express',
    :help_example => '1234 567890 12345',
    :image => '/images/icons/payment-methods/amex.png',
    :help_image => '/images/icons/payment-methods/cvv_amex.png',
    :caption => "American Express",
    :klass => ActiveMerchant::Billing::CreditCard,
    :partial => 'shared/credit_card_entry'
  }, {
    :type => :discover,
    :active_merchant_type => 'discover',
    :help_example => '1234 5678 9012 3456',
    :image => '/images/icons/payment-methods/discover.png',
    :help_image => '/images/icons/payment-methods/cvv_discover.png',
    :caption => "Discover",
    :klass => ActiveMerchant::Billing::CreditCard,
    :partial => 'shared/credit_card_entry' 
  }].push(RAILS_ENV != 'production' ? {
    :type => :bogus,
    :active_merchant_type => 'bogus',
    :help_example => '1234 5678 9012 3456',
    :image => '/images/icons/payment-methods/bogus.png',
    :help_image => '/images/icons/payment-methods/cvv_bogus.png',
    :caption => "Bogus Test",
    :klass => ActiveMerchant::Billing::CreditCard,
    :partial => 'shared/credit_card_entry' 
  } : nil).compact.freeze
  
  #--- class methods
  class << self
    
    def build_with_piggy_bank(type_or_instance, attributes={})
      case type_or_instance.class.to_s
      when /Symbol/, /String/
        if type_or_instance.to_sym == :piggy_bank
          return User.current_user.person.piggy_bank if User.current_user && User.current_user.person
        end
      end
      build_without_piggy_bank(type_or_instance, attributes)
    end
    alias_method_chain :build, :piggy_bank
    
    
    def all(key=nil, where={}, options={})
      select_from_hash_array(TRANSACTION_METHODS, key, where, options)
    end
    
    # returns an array of payment objects, limited by :only or :except options
    def objects(options={})
      select_from_hash_array(TRANSACTION_METHODS, :type, {}, options).map {|t| new(t)}
    end
    
    # returns an array of supported types
    # e.g. [:visa, :mastercard]
    def types(options={})
      select_from_hash_array(TRANSACTION_METHODS, :type, {}, options)
    end

    # returns the payment klass of the given type
    def klass(payment_method_type)
      klass = select_from_hash_array(TRANSACTION_METHODS, :klass, :type => payment_method_type.to_sym)
      klass ? klass.to_s.constantize : nil
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

    # returns the help example
    def partial(method_type)
      select_from_hash_array(TRANSACTION_METHODS, :partial, :type => method_type.to_sym)
    end

    # returns the image
    def caption(method_type)
      select_from_hash_array(TRANSACTION_METHODS, :caption, :type => method_type.to_sym)
    end

    # returns an array of supported active merchant types
    # e.g. [:visa, :mastercard]
    def active_merchant_types(options={})
      select_from_hash_array(TRANSACTION_METHODS, :active_merchant_type, {}, options).compact
    end

    # returns the PaymentMethod internal type based on an active_merchant or 
    # payment method type input
    def normalize_type(a_type)
      return nil if a_type.nil?
      return nil unless a_type.is_a?(String) || a_type.is_a?(Symbol)
      unless nt = select_from_hash_array(TRANSACTION_METHODS, :type, :active_merchant_type => a_type.to_s)
        nt = select_from_hash_array(TRANSACTION_METHODS, :type, :type => a_type.to_sym)
      end
      nt
    end
    
    # returns true if payment object or type is a credit card
    def credit_card?(type_or_object)
      if type_or_object.is_a?(String) || type_or_object.is_a?(Symbol)
        [:visa, :mastercard, :amex, :discover].include?(normalize_type(type_or_object))
      else
        type_or_object.is_a?(ActiveMerchant::Billing::CreditCard)
      end
    end

    # returns true if the given payment object or type is a piggy bank
    def piggy_bank?(type_or_object)
      if type_or_object.is_a?(String) || type_or_object.is_a?(Symbol)
        :piggy_bank == normalize_type(type_or_object)
      else
        type_or_object.is_a?(PiggyBankAccount)
      end
    end
    
    def payment_type(type_or_object)
      return :credit_card if credit_card?(type_or_object)
      return :piggy_bank if piggy_bank?(type_or_object)
    end

    protected 

    def select_from_payment_methods(key=nil, where={}, options={})
      select_from_transaction_methods(key, where, options)
    end
  end
  
  def initialize(payment_method_type)
    super(payment_method_type, TRANSACTION_METHODS)
  end
  
end