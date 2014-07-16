# This class handles all payments using piggy bank transactions
class PiggyBankPayment < Payment
  #--- accessors
  cattr_accessor :account
  serialize :params

  #--- class methods
  class << self

    def authorize(amount, piggy_bank, options = {})
      PiggyBankPayment::account = piggy_bank
      process('authorization', amount) do |pb|
        pb.authorize(amount, :context => options[:payable])
      end
    end
    
    def capture(amount, authorization, options = {})
      PiggyBankPayment::account = options.delete(:buyer).piggy_bank
      process('capture', amount) do |pb|
        pb.capture(amount, authorization, :context => options[:payable])
      end
    end
    
    def purchase(amount, piggy_bank, options = {})
      PiggyBankPayment::account = piggy_bank
      process('purchase', amount) do |pb|
        pb.purchase(amount, :context => options[:payable])
      end
    end

    def void(amount, authorization, options = {})
      PiggyBankPayment::account = options.delete(:buyer).piggy_bank
      process('void', amount) do |pb|
        pb.void(authorization, :context => options[:payable])
      end
    end

    # requires :card_number option
    def credit(amount, authorization, options = {})
      PiggyBankPayment::account = options.delete(:buyer).piggy_bank
      process('credit', amount) do |pb|
        pb.credit(amount, authorization, :context => options[:payable])
      end
    end
    
    # either transfers from buyer's to seller's piggy bank's, if :buyer => @buyer is given
    # or deposits the amount to seller_piggy_bank
    def transfer(amount, seller_piggy_bank, options={})
      PiggyBankPayment::account = seller_piggy_bank
      process('transfer', amount) do |pb|
        pb.deposit(amount, :context => options[:payable])
      end
    end

    private
    
    def process(action, amount = nil)
      result = PiggyBankPayment.new
      result.amount = amount
      result.action = action
    
      begin
        response = yield account
    
        result.success   = response.success?
        result.reference = response.authorization
        result.message   = response.description
        result.params    = response.params
        result.test      = response.test?
      rescue PiggyBankAccount::BankError => e
        result.success   = false
        result.reference = nil
        result.message   = e.message
        result.params    = {}
        result.test      = PiggyBankAccount.test?
      end
      result
    end
  end
  
  #--- instance methods
  
  # override in subclass
  def payment_type
    :piggy_bank
  end
  
end