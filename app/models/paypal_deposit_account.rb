# Paypal deposits are all outbound transfers from a piggy bank account to
# a paypal account.
#
#   <tt>desposit_account.paypal? # true if Paypal</tt>
#
class PaypalDepositAccount < DepositAccount

  #--- constants
  PAYPAL_ACCOUNT_REGEXP = /[\w-]+(?:\.[\w-]+)*@(?:[\w-]+\.)+[a-zA-Z]{2,7}$/

  MESSAGE_PAYPAL_SUBJECT = "Luleka transfer from %{name}"
  MESSAGE_PAYPAL_DESCRIPTION = "%{net_amount} was transferred from %{name} at Luleka to Paypal account %{account} on %{date}." +
    ' ' + "The total transfer amount was %{gross_amount} and a transaction fee of %{fee} was charged."
  MESSAGE_USER_PIGGY_BANK_DESCRIPTION = MESSAGE_PAYPAL_DESCRIPTION
  MESSAGE_PROBONO_PIGGY_BANK_DESCRIPTION = "Paypal transfer by %{name} using Paypal account %{account}"

  
  #--- accessors
  cattr_accessor :gateway
  
  #--- validations
  validates_presence_of :paypal_account
  validates_format_of :paypal_account, :with => PAYPAL_ACCOUNT_REGEXP

  #--- class methods
  class << self
    
    def content_column_names
      content_columns.map(&:name) - %w(kind updated_at created_at activated_at logo iban bic active status)
    end
    
    # returns active merchant gateway, based on:
    #
    # * an active merchant gateway was assigned to gateway class accessor
    #
    # * a gateway implementation identifier, like :authorize_net_gateway was passed 
    #   into the gateway class accessor
    #
    # override or define this as needed in environment like:
    #
    #   PaypalDepositAccount.gateway = :authorize_net_gateway
    #
    def gateway
      if @@gateway
        return @@gateway if @@gateway.is_a? ActiveMerchant::Billing::Gateway
        @@gateway = @@gateway.to_s.classify.constantize.gateway
      else
        Gateway.default_gateway
      end
    end

    # returns class of kind/type specified
    def klass(a_kind=:paypal)
      case a_kind
      when :paypal, 'paypal' then PaypalDepositAccount
      else
        DepositAccount
      end
    end
    
    def paypal?
      true
    end
    
    def kind
      :paypal
    end

    # Minimum transfer amount which can be transferred to this deposit account
    def min_transfer_amount_cents
      DepositMethod.min_transfer_amount_cents(:paypal)
    end

    # Maximum transfer amount which can be transferred to this deposit account
    def max_transfer_amount_cents
      DepositMethod.max_transfer_amount_cents(:paypal)
    end
    
  end

  #--- instance methods
  
  def paypal?
    self.class.paypal?
  end

  def kind
    self.class.kind
  end
  
  # overrides from superclass
  # returns only relevant attributes with content
  #
  # e.g.
  #
  #   :paypal_account => "bla@blup.com"
  #   :transfer_amount => "bla@blup.com"
  #
  def content_attributes
    super.merge({:transfer_amount => self.transfer_amount})
  end

  # Paypal specific transfer method
  def transfer(options={})
    self.transfer_amount = Money.new(0, self.person ? self.person.default_currency : 'USD') unless self.transfer_amount
    
    return Response.new(false, transfer_amount, :transfer, 
      :description => self.errors.full_messages.to_sentence) unless self.valid?

    result = Response.new
    PiggyBankAccount.transaction do
      self.person.piggy_bank.lock!
      begin
        I18n.switch_locale(self.person.default_locale) do
          # transfer net transfer amount to paypal
          response = PaypalDepositAccount::gateway.transfer(
            self.net_transfer_amount,     # money amount of type Money
            self.paypal_account,      # paypal account (email)
            :subject => MESSAGE_PAYPAL_SUBJECT.t % {
              :name => self.person.name
            },
            :description => MESSAGE_PAYPAL_DESCRIPTION.t % {
              :account => self.paypal_account,
              :name => self.person.name,
              :gross_amount => self.gross_transfer_amount.format,
              :net_amount => self.net_transfer_amount.format,
              :fee => self.transaction_fee.abs.format,
              :date => Date.today.to_s(:short)
            }
          )
          
          if response.success?
            # withdraw gross transfer amount from user's piggy bank
            result = self.person.piggy_bank.withdraw(
              self.gross_transfer_amount,
              options.merge(
                :fee => false,
                :description => MESSAGE_USER_PIGGY_BANK_DESCRIPTION.t % {
                  :account => self.paypal_account,
                  :name => self.person.name,
                  :gross_amount => self.gross_transfer_amount.format,
                  :net_amount => self.net_transfer_amount.format,
                  :fee => self.transaction_fee.abs.format,
                  :date => Date.today.to_s(:short)
                }
              )
            )

            # ...and deposit the transaction fee to Probono's piggy bank
            if result.success?
              result.fee = self.transaction_fee
              probono_result = Organization.probono.piggy_bank.deposit(
                self.transaction_fee.abs,
                options.merge(
                  :description => MESSAGE_PROBONO_PIGGY_BANK_DESCRIPTION.t % {
                    :account => self.paypal_account,
                    :name => self.person.name,
                    :gross_amount => self.transfer_amount.format,
                    :net_amount => (self.transfer_amount - self.transaction_fee.abs).format,
                    :fee => self.transaction_fee.abs.format,
                    :date => Date.today.to_s(:short)
                  }
                )
              )
            end
          else
            result = Response.new(response.success?, self.transfer_amount, :transfer)
            result.authorization = response.authorization
            result.description = response.message
            result.params = response.params
            result.test = response.test?
          end
        end
      rescue ActiveMerchant::ActiveMerchantError => e
        result = Response.new(false, self.transfer_amount, :transfer)
        result.authorization = nil
        result.description = e.message
        result.params = {}
        result.test = PaypalDepositAccount::gateway.test?
      end
    end
    result
  end

end