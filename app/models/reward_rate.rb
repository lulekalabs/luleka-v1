# Reward rates is a superclass of bonus rates and reputation rates, which are to be defined per tier.
# The rate instances define source class (i.e. "Response"), beneficiary (i.e. "receiver"), action (i.e. "vote_up")
class RewardRate < ActiveRecord::Base

  #--- associations
  belongs_to :tier
  belongs_to :funding_source, :foreign_key => :funding_source_id, :class_name => "Tier"

  #--- validations
  validates_presence_of :tier
  validates_presence_of :action
  
  #--- class_methods
  
  class << self

    def beneficiary_types
      %w(sender receiver).sort.map(&:to_sym)
    end
    alias_method :destination_types, :beneficiary_types
    
    def action_types
      %w(vote_up vote_down accept_response).sort.map(&:to_sym)
    end
    
    # returns a list classes that have rewards associated
    def source_classes
      [Kase, Response]
    end

    # list of source class names
    def source_class_names
      source_classes.map(&:name)
    end
    
    # returns translated action name, e.g. :vote_up -> "nach oben votiert"
    def human_action_name(action, options={})
      human_attribute_name("action_#{action}".to_sym, options)
    end
    
    def human_beneficiary_name(destination, options={})
      human_attribute_name("beneficiary_#{destination}".to_sym, options={})
    end
    alias_method :human_destination_name, :human_beneficiary_name
    
  end
  
  #--- instance methods
  
  # returns the tier (with a filled piggy_bank account) that was specified as funding source
  # or tier associated to this
  def funding_source_with_fallback
    self.funding_source_without_fallback || self.tier
  end
  alias_method_chain :funding_source, :fallback
  
  # returns action as symbol
  def action
    self[:action].to_sym if self[:action]
  end
  
  # converts action to string before writing to db
  def action=(value)
    self[:action] = value.to_s if value
  end

  # converts action to string before writing to db
  def action=(value)
    self[:action] = value.to_s if value
  end

  # returns :sender or :receiver
  def beneficiary_type
    self[:beneficiary_type].to_sym if self[:beneficiary_type]
  end

  # assigns beneficiary as string
  def beneficiary_type=(value)
    self[:beneficiary_type] = value.to_s if value
  end
  
  # converts the source class name into an underscored version, e.g. BankTransaction -> :bank_transaction
  def source_type
    self.source_class.to_s.underscore
  end
  
  # returns the funding source currency, i.e. EUR
  def default_currency
    self.funding_source.default_currency
  end
  
end
