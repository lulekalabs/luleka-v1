# DepositAccount holds account information about different ways to transfer 
# money outside of Probono. We currently implement Paypal transfers, and in 
# the future we may support direct bank transfers, which will also be 
# handled by a sub class of this.
#
#   <tt>desposit_account.kind    # :paypal for Paypal</tt>
#  
class DepositAccount < ActiveRecord::Base
  
  #--- accessors
  attr_accessor :transfer_amount
  attr_protected :status
  
  #--- associations
  belongs_to :person

  #--- validations
  validates_presence_of :person

  #--- state machine
  acts_as_state_machine :initial => :created, :column => :status
  state :created
  state :pending
  state :active, :enter => Proc.new {|o| o.activated_at = Time.now.utc}
  state :suspended
  
  event :register do
    transitions :from => :created, :to => :pending
  end
  
  event :activate do
    transitions :from => [:created, :pending], :to => :active
  end

  event :suspend do
    transitions :from => [:created, :pending, :active], :to => :suspended
  end
  
  event :unsuspend do
    transitions :from => :suspended, :to => :active, :guard => Proc.new {|u| !u.activated_at.blank?}
    transitions :from => :suspended, :to => :pending, :guard => Proc.new {|u| u.activated_at.blank?}
    transitions :from => :suspended, :to => :created
  end

  #--- class methods
  class << self

    # type casts to the class specified in :type parameter
    #
    # E.g.
    #
    #   d = DepositAccount.new(:type => PaypalDepositAccount)
    #   d.kind == :paypal  # -> true
    #
    def new_with_cast(*a, &b)  
      if (h = a.first).is_a? Hash and (type = h[:type] || h['type']) and 
        (k = type.class == Class ? type : (type.class == Symbol ? klass(type): type.constantize)) != self
        raise "type not descendent of DespositAccount" unless k < self  # klass should be a descendant of us  
        return k.new(*a, &b)  
      end  
      new_without_cast(*a, &b)  
    end  
    alias_method_chain :new, :cast

    # Note: make sure to enhance the list when adding more subclasses
    def klass(a_kind=nil)
      [PaypalDepositAccount].each do |subclass|
        return subclass if subclass.kind == a_kind
      end
      DepositAccount
    end
    
    def kind
      raise 'override in subclass'
    end

  end

  #--- instance methods
  
  def kind
    self.class.kind
  end
  
  # Transaction fee that applies if money is withdrawn from Probono using this deposit_method
  # Transaction fee must be negative!!
  def transaction_fee
    Money.new(DepositMethod.transaction_fee_cents(self.kind), self.person.default_currency).abs * -1
  end
  
  # Minimum transfer amount which can be transferred to this deposit account
  def min_transfer_amount
    Money.new(DepositMethod.min_transfer_amount_cents(self.kind), self.person.default_currency)
  end

  # Maximum transfer amount which can be transferred to this deposit account
  def max_transfer_amount
    Money.new(DepositMethod.max_transfer_amount_cents(self.kind), self.person.default_currency)
  end
  
  # transfer amount minsu transaction fee is what the user receives on the 
  # deposit account (e.g. Paypal)
  def net_transfer_amount
    self.transfer_amount - self.transaction_fee.abs if self.transfer_amount
  end
  
  # same as transfer amount
  def gross_transfer_amount
    self.transfer_amount
  end
  
  # How much is available for a transfer, which currently is the amount available
  # of the person linked to this account
  def available_transfer_amount
    self.person.piggy_bank.available_balance
  end

  # returns the account balance that is required to extract the transfer amount
  def required_account_balance
    self.transfer_amount.abs + self.transaction_fee.abs if self.transfer_amount
  end

  # Returns the maximum available transfer amount
  # Example:
  #   say you want to transfer with Paypal and you have $10 in your Piggy Bank.
  #   given a transfer fee of $0.50 you can transfer a maximum of $9.50.
  #   but if there is a deposit method specific maximum transfer amount defined, 
  #   one can only tranfser that max - transcation fee
  def default_transfer_amount
    if max = self.max_transfer_amount
      ceiling = self.available_transfer_amount > max ? max : self.available_transfer_amount
    else
      ceiling = self.available_transfer_amount
    end
    ceiling - self.transaction_fee.abs
  end

  # tansfer amount setter
  def transfer_amount=(amount)
    @transfer_amount = case amount.class.name
      when /Money/ then Money.new(amount.cents.abs, amount.currency)
      when /NilClass/ then Money.new(0, self.person.default_currency)
      else
        raise 'String value assignment to :transfer_amount requires a person with default currency.' unless self.person
        amount.to_money(self.person.default_currency).abs
    end
  end
  
  # transfer_amount getter
  def transfer_amount
    @transfer_amount
  end

  # validates generic transfer
  def validate
    if self.transfer_amount
      errors.add(:transfer_amount, I18n.t('activerecord.errors.messages.greater_than_zero')) if self.transfer_amount < 0.to_money

      # min amount?
      errors.add(:transfer_amount, I18n.t('activerecord.errors.messages.greater_than_or_equal_to') % {
        :count => self.min_transfer_amount.format
      }) if self.transfer_amount < self.min_transfer_amount

      # max amount?
      if self.max_transfer_amount
        errors.add(:transfer_amount, I18n.t('activerecord.errors.messages.less_than_or_equal_to') % {
          :count => self.max_transfer_amount.format
        }) if self.transfer_amount > self.max_transfer_amount
      end

      if self.transfer_amount > self.available_transfer_amount
        # insuffient funds
        errors.add(:transfer_amount, I18n.t('activerecord.errors.messages.greater_than_balance_of') % {
          :count => self.transfer_amount.format,
          :balance => self.available_transfer_amount.format
        })
      end
    end
  end
  
  # Transfer money to the deposit account
  def transfer(options={})
    raise 'override in subclass'
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
    attr_accessor :test
    
    def initialize(success=false, amount=Money.new(0, 'USD'), action=:none, options={})
      defaults = {:description => nil, :authorization => nil}
      options = defaults.merge(options).symbolize_keys
      @success = success
      @amount = amount
      @action = action
      @fee = options.delete(:fee)
      @description = options.delete(:description)
      @authorization = options.delete(:authorization)
      @params = options
    end
    
    def success?
      @success || false
    end
    
    def message
      @description
    end
    
    def test?
      @test ? @test == true : false
    end
    
  end
  
  class DepositError < Exception
  end

end
