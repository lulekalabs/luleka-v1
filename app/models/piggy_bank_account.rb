# This class implements the piggy bank concept of person's or other object's
# available money, which is available in the probono account.
class PiggyBankAccount < ActiveRecord::Base

  #--- accessors
  cattr_accessor :mode
  @@mode = :none
  
  #--- constants
  COOLING_PERIOD_IN_DAYS           = 45
  AUTHORIZATION_EXPIRY_PERIOD      = 30
  WITHDRAWAL_FEE_IN_CENTS          = 50
  MIN_AMOUNT_TO_TRANSFER_IN_CENTS  = 1
  MAX_AMOUNT_TO_TRANSFER_IN_CENTS  = 1000
  TRANSFER_MESSAGE = "Transfer of %{amount} (%{original}) from %{from_type} \"%{from_name}\" to %{to_type} \"%{to_name}\""
  
  #--- associations
  belongs_to :owner, :polymorphic => true
  has_many :transactions, 
    :dependent => :destroy,
    :class_name => 'PiggyBankAccountTransaction'

  #--- mixins
  money :balance, :cents => :cents, :currency => :currency

  after_validation :clear_balance_cache
  before_destroy :close_account
  
  #--- class methods
  class << self 
    
    def void_pending_expired_authorizations(options={})
      PiggyBankAccountTransaction.authorized.pending.expired.each do |t|
        t.account.void(t.authorization)
      end
    end

    # Transfer funds from this to to another account
    # Optionally, provide a :context if you want to 
    # capture and transfer
    def transfer(from, to, amount, options={})
      if from.is_a? PiggyBankAccount
        return from.transfer(to, amount, options)
      end
      false
    end

    # Makes sure that the fee is negative
    def normalize_fee(a_fee)
      Money.new(a_fee.cents <= 0 ? a_fee.cents : -a_fee.cents, a_fee.currency)
    end

    # used in PaymentMethod or DepositMethod
    def kind
      :piggy_bank
    end

    # defines the mode for the bank. can be set to :test
    #
    # E.g.
    #
    #   PiggyBankAccount.mode = :test
    #
    def mode=(a_mode)
      @@mode = a_mode.to_sym
    end
    
    # mode getter
    def mode
      @@mode.to_sym if @@mode
    end

    # returns true if the bank account is in test mode?
    def test?
      @@mode == :test
    end
    
  end

  #--- instance methods

  def initialize(args={})
    super(args)
    self.balance = Money.new(0, self.currency)
  end

  # same as class method
  def test?
    self.class.test?
  end

  # Transaction fee
  # Example: applies to all withdrawals
  # Note: fee must be negative to be correctly deducted
  def transaction_fee
    Money.new(-WITHDRAWAL_FEE_IN_CENTS, self.currency)
  end
  alias_method :fee, :transaction_fee
  
  # returns the given fee amount normalized
  def normalize_fee(fee_amount)
    self.class.normalize_fee(fee_amount)
  end
  
  # used in PaymentMethod or DepositMethod
  def kind
    self.class.kind
  end
  alias_method :type, :kind

  # Securely transfers money from one to another account.
  #
  # options:
  #   :limits => false || [100, 10000]
  #
  # E.g.
  #
  #   pb.transfer(fr, Money.new(1000))  # -> transfers $10 to fr's account
  #
  def transfer(to, amount, options={})
    options = {:limits => [
      PiggyBankAccount::MIN_AMOUNT_TO_TRANSFER_IN_CENTS,
      PiggyBankAccount::MAX_AMOUNT_TO_TRANSFER_IN_CENTS
    ]}.symbolize_keys.merge(options)

    amount = amount.abs
    min_amount = if options[:limits].is_a?(Array) && options[:limits].first.is_a?(Money)
      Money.new(1, amount.currency) + options[:limits].first - Money.new(1, amount.currency)
    else
      Money.new((options[:limits] || [0, 0]).first || 0, amount.currency)
    end
    max_amount = if options[:limits].is_a?(Array) && options[:limits].last.is_a?(Money)
      Money.new(1, amount.currency) + options[:limits].last - Money.new(1, amount.currency)
    else
      Money.new((options[:limits] || [0, 0]).last || 0, amount.currency)
    end

    return Response.new(false, amount, :transfer, :description => I18n.t('activerecord.errors.messages.transfer_greater_or_equal_to') % {
      :count => min_amount.format
    }) if options[:limits] && amount < min_amount
    return Response.new(false, amount, :transfer, :description => I18n.t('activerecord.errors.messages.transfer_less_or_equal_to') % {
      :count => max_amount.format
    }) if options[:limits] && amount > max_amount
    return Response.new(false, amount, :transfer, :description => I18n.t('activerecord.errors.messages.transfer_destination_invalid')) unless to.is_a?(PiggyBankAccount)
    return Response.new(false, amount, :transfer, :description => I18n.t('activerecord.errors.messages.transfer_self_exclusion')) if to == self
    
    options.delete(:limits)
    result = nil
    transaction do
      I18n.switch_locale(self.owners_locale) do
        result = self.withdraw(amount, options.merge(
          :fee => false,
          :description => TRANSFER_MESSAGE.t % {
            :from_type => self.owner.class.human_name, :from_name => self.owners_name,
              :to_type => to.owner.class.human_name, :to_name => to.owners_name,
                :amount => amount.convert_to(self.currency).format, :original => amount.format}))
      end
      if result.success?
        I18n.switch_locale(to.owners_locale) do
          result = to.deposit(amount, options.merge(:description => TRANSFER_MESSAGE.t % {
            :from_type => self.owner.class.human_name, :from_name => self.owners_name,
              :to_type => to.owner.class.human_name, :to_name => to.owners_name, 
                :amount => amount.convert_to(to.currency).format, :original => amount.format}))
        end
      end
    end
    if result.success?
      Response.new(true, amount, :transfer, :description => result.message)
    else
      result
    end
  end

  # Deposits amount made for services within the app. The amount that is deposited
  # is not available for transfer or authorazation within the cooling period (45 days).
  #
  # E.g.
  #
  #   pb.deposit(Money.new(50))  # -> adds $0.50 cents to the account
  #
  def deposit(amount, options={})
    adjust_and_save(amount.abs, :deposit, options)
  end

  # Deposits a given amount, which is available instantly for consumation or transfer.
  #
  # E.g.
  #
  #   pb.direct_deposit(Money.new(50))  # -> adds $0.50 cents to the account
  #
  def direct_deposit(amount, options={})
    adjust_and_save(amount.abs, :direct_deposit, options)
  end
  
  # Withdraw funds from bank account
  # Used for transfers to the outside world, e.g. using PaypalDepositAccount
  #
  #   amount  (net amount)
  #
  # option:
  #   :fee => false (default) | true
  #
  #     * if true the default transaction fee $0.50 plus the amount
  #       are withdrawn 
  #     * if :fee is a FixNum or money object this fee and amount
  #       are widthdrawn
  #     * if false no additional fee is withdrawn
  #
  #       e.g.
  #
  #         :fee => 100 equals $1.00 
  #         :fee => Money.new(100, 'USD')
  #
  # Note: when fee is provided the amount represents a net amount,
  #       where amount + fee is withdrawn from the account.
  #
  def withdraw(amount, options={})
    options = {:fee => false}.merge(options).symbolize_keys
    adjust_and_save(amount.abs * -1, :withdraw, options)
  end
  
  # Purchase products on Probono
  # Example: buy a membership subscription
  def purchase(amount, options={})
    adjust_and_save(amount.abs * -1, :purchase, options)
  end
  
  # Authorizes a future payment if balance is available (available_balance)
  # The available balance is adjusted until the authorization expires,
  # the authorized payment is voided or captured. 
  #
  # Returns a result object which contains the authorization identifier.
  #
  # E.g.
  #
  #   result = authorize Money.new(1000, 'USD'), :expires_at => Time.now.utc + 1.day
  #   result.authorization # -> '3h2j32...'
  #
  def authorize(amount, options={})
    adjust_and_save(amount.abs * -1, :authorize, options)
  end

  # Captures a previously authorized purchase in full or part,
  # if the authorization has not been expired. Requires the authorization
  # number that was provided on result when authorized.
  #
  # E.g.
  #
  #   result = authorize Money.new(500)
  #   ...
  #   capture Money.new(500), result.authorization
  #   capture Money.new(360), result.authorization
  #
  def capture(amount, authorization, options={})
    adjust_and_save(amount.abs * -1, :capture, {:authorization => authorization}.merge(options))
  end

  # Voids a previously authorized payment and affects the available
  # account balance.
  #
  # E.g.
  #
  #   result = authorize Money.new(500)
  #   ...
  #   void result.authorization
  #
  def void(authorization, options={})
    adjust_and_save(nil, :void, {:authorization => authorization}.merge(options))
  end

  # voids all bank account authorizations that have been expired and are still pending
  def void_pending_expired_authorizations
    self.transactions.authorized.pending.expired.each do |t|
      t.account.void(t.authorization)
    end
  end

  # voids all bank account authorizations that are authorized pending
  def void_pending_authorizations
    self.transactions.authorized.pending.each do |t|
      t.account.void(t.authorization)
    end
  end

  # Credits an already captured authorization in full or part.
  #
  # E.g.
  #
  #   result = pb.authorize Money.new(500)
  #   ...
  #   result = pb.capture result.authorization
  #   ...
  #   pb.credit Money.new(300), result.authorization
  #
  def credit(amount, authorization, options={})
    adjust_and_save(amount.abs, :credit, {:authorization => authorization}.merge(options))
  end

  # Reads balance and if an authorization exists, 
  # adjusts balance by this amount
  # Parameters:
  #   ending_at: calculated balance ending_at Time
  def balance(ending_at=nil)
    return @balance if !!@balance && !ending_at
    if ending_at
      balance_cents = self.transactions.sum(:cents,
        :conditions => ["created_at < ? AND action NOT IN (?)", ending_at, ['authorize', 'void']]
      )
      @balance = nil
      Money.new(balance_cents || 0, self.currency)
    else
      @balance = Money.new(self.cents, self.currency)
    end
  end

  # Provides the total amount of funds in the account that is available to be 
  # transferred to an external bank or to another bank account, e.g. as a donation.
  def available_balance(ending_at=nil)
    return @available_cache if !!@available_cache && !ending_at
    if ending_at
      ending_at = ending_at > Time.now.utc ? Time.now.utc : ending_at  # normalize time
      diff = COOLING_PERIOD_IN_DAYS.days - (Time.now.utc - ending_at)
      diff = diff < 0 ? 0 : diff
      time = ending_at - diff
    else
      time = Time.now.utc - COOLING_PERIOD_IN_DAYS.days
    end
    
    query = "(created_at > ? AND action = 'deposit') OR (action = 'authorize' AND voided_at IS NULL AND captured_at IS NULL)"
    overhanging_cents = self.transactions.sum('abs(cents)', :conditions => [query, time])
    if overhanging_cents
      overhanging_amount = Money.new(overhanging_cents.to_i, self.currency)
      available_amount = self.balance - overhanging_amount
      available_amount = available_amount > Money.new(0, self.currency) ? available_amount : Money.new(0, self.currency)
    else
      available_amount = self.balance(ending_at)
    end
    @available_cache = ending_at ? nil : available_amount
    available_amount
  end
  alias_method :available, :available_balance
  
  # transient attribute, is used for validation. otherwise, balance
  # is recalculated each time balance getter is called
  def available_balance=(available_amount)
    @available_cache = available_amount
  end
  alias_method :available=, :available_balance=
  
  # returns the account's default currency
  def default_currency
    self[:currency] || 'USD'
  end
  
  # no transactions have been made
  def virgin?
    self.transactions.empty?
  end
  
  protected
  
  # returns the account owner's locale
  def owners_locale
    default = :"en-US"
    if self.owner.is_a?(Person)
      self.owner.default_locale || default
    elsif self.owner.is_a?(Tier)
      self.owner.default_locale || default
    else
      default
    end
  end

  # returns the owner's name or 'disclosed' if not, e.g. Person owner returns username name
  def owners_name
    if self.owner.is_a?(Person) && self.owner.user
      self.owner.user.login
    elsif self.owner.respond_to?(:name)
       self.owner.name
    else
      "disclosed".t
    end
  end

  private
  
  def adjust_and_save(amount, action, options={})
    defaults = {:created_at => Time.now.utc}
    options = defaults.merge(options).symbolize_keys
    result = nil
    
    transaction do
      lock!
      case action
      when :withdraw
        if fee_amount = options.delete(:fee)
          fee_amount = case fee_amount.class.name
            when /TrueClass/ then self.transaction_fee
            when /Money/ then self.normalize_fee(fee_amount)
            when /Fixnum/ then self.normalize_fee(Money.new(fee_amount, self.currency))
            else
              Money.new(0, self.currency)
          end
          self.transactions.build(
            :amount => fee_amount,
            :action => 'fee',
            :description => "%{bank} withdrawal fee".t % {:bank => self.class.human_name},
            :created_at => options[:created_at]
          ) unless fee_amount.zero?
        else
          fee_amount = Money.new(0, self.currency)
        end
        add(amount + fee_amount, action)
      when :capture
        if authorization = find_authorization(options[:authorization])
          if amount.abs > authorization.amount.abs 
            return Response.new(false, amount.abs, action, :description => "amount cannot exceed authorized amount")
          elsif amount.abs <= authorization.amount.abs 
            authorization.capture!
            add(amount, action)
          end
          self.decrement(:authorizations_count)
        else
          return Response.new(false, amount.abs, action, :description => "authorization not found or authorization expired")
        end
      when :authorize
        add(amount, action)
        self.increment(:authorizations_count)
      when :void
        if authorization = find_authorization(options[:authorization], false)
          authorization.void!
          amount = authorization.amount * -1
          add(amount, action)
          self.decrement(:authorizations_count)
        else
          return Response.new(false, nil, action, :description => "authorization not found")
        end
      when :credit
        if authorization = find_captured_authorization(options[:authorization])
          return Response.new(false, amount, action,
            :description => "amount exceeds authorized/captured amount") if amount > authorization.amount.abs
          add(amount, action)
        else
          return Response.new(false, amount, action, :description => "authorization not found, captured, expired or voided")
        end
      else
        # :direct_deposit, :deposit, :purchase
        add(amount, action)
      end

      # add transaction
      add_exchange_rate_if_necessary(amount.currency)
      transaction = self.transactions.build(options.merge({
        :amount => Money.new(1, self.currency) + amount - Money.new(1, self.currency),
        :action => action,
      }))
    
      # add authorization to result
      options.merge!(:authorization => transaction.authorization) if transaction.authorization?
    
      # add fee to result
      options.merge!(:fee => fee_amount) if fee_amount

      # validate for sufficient funds, etc.
      if self.valid?
        result = Response.new(self.save, amount.abs, action, options)
      else
        lock! # reloads the record and keeps it locked
        options.delete(:authorization)
        
        if self.errors.on(:balance)
          result = Response.new(false, amount.abs, action,
            options.merge({:description => "balance #{self.errors.on(:balance)}"}))
        end
        if self.errors.on(:available)
          result = Response.new(false, amount.abs, action,
            options.merge({:description => "available balance #{self.errors.on(:available)}"}))
        end
      end
    end
    result
  end

  # adds amount to balance based on the transaction
  # if the account currency and the amount currency do not match,
  # we look up an exchange rate and add it to the money bank.
  #
  # NOTE: Money conversion using Money::VariableExchangeBank does
  #       round in favor of the customer
  #
  def add(amount, action)
    add_exchange_rate_if_necessary(amount.currency)
    
    # adjust balance
    unless [:authorize, :void].include?(action)
      if self.balance.zero?
        self.balance = Money.new(1, self.currency) + amount - Money.new(1, self.currency)
      else
        self.balance += amount
      end
    end

    # adjust available
    if [:authorize].include?(action)
      if self.available.zero?
        self.available = Money.new(1, self.currency) + amount - Money.new(1, self.currency)
      else
        self.available += amount
      end
    end
  end
  
  # custom validations
  def validate
    errors.add(:balance, I18n.t('activerecord.errors.messages.insufficient_funds')) if self.balance < Money.new(0, self.currency)
    errors.add(:available, I18n.t('activerecord.errors.messages.insufficient_funds')) if self.available < Money.new(0, self.currency)
  end

  # Find first not expired, not voided authorization for sellable
  def find_authorization(authorization_number, with_expiry=true)
    if with_expiry
      self.transactions.find(:first, :conditions => [
        "authorization = ? AND expires_at >= ? AND action = ? AND voided_at IS NULL AND captured_at IS NULL",
        authorization_number, Time.now.utc, 'authorize']
      )
    else
      self.transactions.find(:first, :conditions => [
        "authorization = ? AND action = ? AND voided_at IS NULL AND captured_at IS NULL",
        authorization_number, 'authorize']
      )
    end
  end

  # finds authorization transaction that has been captured
  def find_captured_authorization(authorization_number)
    self.transactions.find(:first, :conditions => [
      "authorization = ? AND action = ?", authorization_number, 'capture'
    ])
  end

  # adds exchange rate of amount_currency if the account currency does not match
  def add_exchange_rate_if_necessary(amount_currency)
    # get exchange rate in case currencies don't match
    Money.bank.add_rate(amount_currency, self.currency,
      ExchangeRate.get(amount_currency, self.currency)
    ) if self.currency != amount_currency && !Money.bank.get_rate(amount_currency, self.currency)
  end

  # cleares the cache for balance and available balance
  def clear_balance_cache
    @balance = nil
    @available_cache = nil
  end

  # when the account is destroyed, we will have to
  # gracefully close the account by
  #
  #   * voiding all pending athorizations
  #   * moving funds to probono's account
  #
  # this method is called in before_destroy
  #
  def close_account
    self.void_pending_authorizations
    if probono = Organization.probono
      if probono.piggy_bank && probono.piggy_bank.reload && probono.piggy_bank != self
        result = self.transfer(probono.piggy_bank, self.available_balance, :limits => false) if probono.piggy_bank
        raise BankError, "remaining funds could not be transferred" if !result || !result.success?
      end
    end
  end

  #--- nested classes
  
  # class to return the transaction results
  class Response
    attr_accessor :success
    attr_accessor :amount
    attr_accessor :fee
    attr_accessor :action
    attr_accessor :authorization
    attr_accessor :description
    attr_accessor :params
    
    def initialize(success=false, amount=Money.new(0, 'USD'), action=:none, options={})
      defaults = {:description => nil, :authorization => nil}
      options = defaults.merge(options).symbolize_keys
      @success = success
      @amount = amount
      @action = action
      @fee = options.delete(:fee)
      @authorization = options.delete(:authorization)
      @description = options.delete(:description)
      @params = options
    end
    
    def success?
      @success || false
    end
    
    def message
      @description
    end
    
    def test?
      PiggyBankAccount.test?
    end
    
  end
  
  class BankError < Exception
  end
  
end
