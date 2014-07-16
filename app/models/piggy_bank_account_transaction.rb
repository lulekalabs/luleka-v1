# Class to hold each of the piggy bank transaction, like authorization, capture,
# purchase, etc.
require 'digest/sha2'
class PiggyBankAccountTransaction < ActiveRecord::Base

  #--- assocations
  belongs_to :account,
    :class_name => 'PiggyBankAccount',
    :foreign_key => :piggy_bank_account_id
  belongs_to :context, :polymorphic => true
  
  #--- mixins
  money :amount, :cents => :cents, :currency => :currency

  #--- has finder
  named_scope :authorized, :conditions => {:action => 'authorize'}
  named_scope :pending, :conditions => "voided_at IS NULL AND captured_at IS NULL"
  named_scope :expired, :conditions => ["expires_at IS NOT NULL AND expires_at < ?", Time.now.utc]
  named_scope :after, lambda {|time| {
    :conditions => ["created_at > ?", time]
  }}

  #--- class methods
  class << self

    # removes all extra formatting from a number, used in finder
    def strip_number_formatting(number)
      number.gsub('-', '') if number
    end
    
  end

  #--- callbacks
  after_create :account_for_transaction_fee
  before_save :number
  
  #--- instance methods
  
  def number
    self[:number] ||= Utility.generate_random_hex
  end
  
  # formats the order number in 6 groups, e.g.
  # a4-1793f7-6125f9-032a10-415705-b20a66 
  def number_with_formatting
    if /^(.*)(.{6})(.{6})(.{6})(.{6})(.{6})/i.match(number_without_formatting)
      "#{$1}-#{$2}-#{$3}-#{$4}-#{$5}-#{$6}"
    else
      number_without_formatting
    end
  end
  alias_method_chain :number, :formatting

  # retruns a human readable 
  # TA-6a33cc
  # TA6a33cc
  # TA#6a33cc
  def short_number
    if /^(.*)(.{6})(.{6})(.{6})(.{6})(.{6})/i.match(number_without_formatting)
      "TA-#{$6}"
    else
      number
    end
  end
  
  def after_initialize
    if new_record? && authorization?
      encrypt_authorization
      self[:expires_at] ||= Time.now.utc + PiggyBankAccount::AUTHORIZATION_EXPIRY_PERIOD.days
    end
  end
  
  # action getter symbolizes
  def action
    self[:action].to_sym if self[:action]
  end
  
  # string version of action
  def action_s
    self.action.to_s.humanize.downcase
  end

  # translated version of action
  def action_t
    self.action.t
  end
  
  # action setter stringifies
  def action=(an_action)
    self[:action] = an_action.to_s if an_action
  end
  
  def authorization?
    self.action == :authorize
  end
  
  # marks the transaction as captured and clears the cache in bank account
  def capture!
    self.account.send(:clear_balance_cache)  # using send, because it is private
    update_attributes(:captured_at => Time.now.utc)
  end

  # marks the transaction as voided and clears the cache in bank account
  def void!
    self.account.send(:clear_balance_cache)  # using send, because it is private
    update_attributes(:voided_at => Time.now.utc)
  end
  
  # returns true if the transcation is voided?
  def voided?
    !!self[:voided_at]
  end

  # returns true if the transcation is captured?
  def captured?
    !!self[:captured_at]
  end
  
  # returns true if this transaction is a transaction fee
  def transaction_fee?
    self.action == :fee
  end

  # returns the original db field description
  def description
    self[:description]
  end
    
  private
  
  def encrypt_authorization
    self.authorization = Digest::SHA1.hexdigest("--#{Time.now.utc.to_s}--") if new_record?
  end

  def account_for_transaction_fee
    if self.transaction_fee?
      if probono = Organization.probono
        if account = probono.piggy_bank
          account.deposit(self.amount.abs)
        end
      end
    end
  end
  
end
