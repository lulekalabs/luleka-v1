# Super class of PaymentMethod and DepositMethod factories
class TransactionMethod
  #--- constants
  TRANSACTION_METHODS = []
  
  #--- accessors
  attr_accessor :type
  attr_accessor :active_merchant_type
  attr_accessor :help_example
  attr_accessor :image
  attr_accessor :help_image
  attr_accessor :caption
  attr_accessor :klass
  attr_accessor :partial

  #--- class methods
  class << self

    def build(type_or_instance, attributes={})
      case type_or_instance.class.to_s
      when /Symbol/, /String/
        factory = new(type_or_instance.to_sym)
        klass = factory.klass
        klass.new((attributes || {}).merge(:type => factory.active_merchant_type || factory.type))
      else
        type_or_instance.attributes = attributes || {}
        type_or_instance
      end
    end

    # accessor for reading elements from hash array
    # E.g. select_transaction :caption, :type => :visa
    def select_from_transaction_methods(key=nil, where={}, options={})
      select_from_hash_array(TRANSACTION_METHODS, key, where, options)
    end

    # Simply query mechanism for any information in a hash array. Similar to 
    # a select query, it lets you retrieve information if you know
    # what you are looking for. Returns an array of results, or nil.
    #
    # e.g.
    #
    #    "Deutschland": probono_select_hash_array COUNTRIES, :name, :code => 'DE', :all => true
    #    return all names: probono_select_hash_array COUNTRIES :name 
    #
    # options:
    #
    #   :first => true : first occurance only (default)
    #   :all => true   : all occurances
    #
    def select_from_hash_array(hash_array, key=nil, where={}, options={})
      return nil if hash_array.nil?
      return nil if hash_array.empty?
      defaults = { :first => true }
      options = defaults.merge(options).symbolize_keys
      raise "Hash array type mismatch" unless hash_array.is_a?( Array )
      raise "No hash array given" unless hash_array.first.is_a?( Hash )
      if options[:all] == true
        options[:first] == false
      elsif where.empty?
        options[:all] = true
      end
      if where.empty?
        result = hash_array
      else
        result = hash_array.find {|i| i[where.to_a.first[0].to_sym].to_s == where.to_a.first[1].to_s}
      end
      unless result.nil?
        if key.nil?
          return result
        else
          result = if options[:all]
            result.collect { |i| i[key.to_sym] }
          else options[:first]
            result.is_a?(Hash) ? result[key.to_sym] : result.first
          end
          result = if options[:except]
            if result.is_a?(Hash)
              options[:except].to_a.include?(result[key.to_sym]) ? nil : result[key.to_sym]
            else
              result.reject {|r| [options[:except]].flatten.include?(r)}
            end
          elsif options[:only]
            if result.is_a?(Hash)
              options[:except].to_a.include?(result[key.to_sym]) ? result[key.to_sym] : nil
            else
              result.select {|r| [options[:only]].flatten.include?(r)}
            end
          else
            result
          end
          return result
        end
      end
      nil
    end

  end
  
  # e.g. PaymentMethod.new :visa
  def initialize(transaction_method, transaction_methods=TRANSACTION_METHODS)
    @type = select_from_hash_array(transaction_methods, :type, :type => transaction_method.to_sym)
    @active_merchant_type = select_from_hash_array(transaction_methods, :active_merchant_type, :type => transaction_method.to_sym)
    @help_example = select_from_hash_array(transaction_methods, :help_example, :type => transaction_method.to_sym)
    @image = select_from_hash_array(transaction_methods, :image, :type => transaction_method.to_sym)
    @help_image = select_from_hash_array(transaction_methods, :help_image, :type => transaction_method.to_sym)
    @caption = select_from_hash_array(transaction_methods, :caption, :type => transaction_method.to_sym)
    @klass = select_from_hash_array(transaction_methods, :klass, :type => transaction_method.to_sym)
    @partial = select_from_hash_array(transaction_methods, :partial, :type => transaction_method.to_sym)
  end
  
  alias_method :kind, :type
  alias_method :type_s, :caption
  
  protected
  
  def select_from_transaction_methods(key=nil, where={}, options={})
    self.class.select_from_transaction_methods(key, where, options)
  end
  
  private
  
  def select_from_hash_array(hash_array, key=nil, where={}, options={})
    self.class.select_from_hash_array(hash_array, key, where, options)
  end
  
end