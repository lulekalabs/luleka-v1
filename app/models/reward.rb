# Class to offer functionality to manage monetary rewards for kases
class Reward < ActiveRecord::Base

  #--- constants
  MIN_PIGGY_BANK_OFFER_CENTS  = 5
  MIN_CREDIT_CARD_OFFER_CENTS = 200
  MAX_OFFER_CENTS             = 20000
  MIN_EXPIRY_DAYS             = 1
  MAX_EXPIRY_DAYS             = 7
  DEFAULT_EXPIRY_DAYS         = 3
  
  #--- accessors
  attr_protected :status
  attr_accessor :payment_type
  attr_accessor :payment_object
  attr_accessor :expiry_option
  attr_accessor :expiry_days
  
  #--- associations
  belongs_to :kase
  belongs_to :sender, :foreign_key => :sender_id, :class_name => "Person"
  belongs_to :receiver, :foreign_key => :receiver_id, :class_name => "Person"
  has_many :responses,
    :through => :kase,
    :source => :responses,
    :foreign_key => :response_id,
    :class_name => "Response"
  has_many :purchase_orders,
    :class_name => 'PurchaseOrder',
    :order => 'orders.created_at ASC',
    :finder_sql => 'SELECT DISTINCT orders.* FROM orders ' + 
      'INNER JOIN line_items ON line_items.order_id = orders.id ' +
      'INNER JOIN cart_line_items ON cart_line_items.id = line_items.sellable_id ' + 
      '  AND line_items.sellable_type = \'CartLineItem\'' +
      'WHERE cart_line_items.product_id = #{id} AND cart_line_items.product_type = \'Reward\''

  #--- mixins
  money :price, :cents => :cents, :currency => :currency
  
  #--- named_scope
  named_scope :active, :conditions => ["rewards.status IN(?)", ['active']]
  named_scope :paid, :conditions => ["rewards.status IN(?)", ['paid']]
  named_scope :visible, :conditions => ["rewards.status IN(?)", ['active', 'paid']]
  named_scope :closed, :conditions => ["rewards.status IN(?)", ['paid']]
  
  #--- validations
  validates_presence_of :kase
  validates_presence_of :sender

  #--- state machine
  acts_as_state_machine :initial => :created, :column => :status
  state :created
  state :active, :enter => :do_activate, :after => :after_activate
  state :paid, :enter => :do_pay
  state :closed, :enter => :do_close, :after => :after_closed

  event :activate do
    transitions :from => :created, :to => :active, :guard => :can_activate? 
  end

  event :cash do
    transitions :from => :active, :to => :paid, :guard => :can_cash?
    transitions :from => :active, :to => :closed
  end

  event :cancel do
    transitions :from => :active, :to => :closed
  end
  
  #--- callbacks
  before_destroy :cancel!
  before_validation_on_create :build_payment_object_from_payment_type
  before_create :cancel_active_sender_reward
  before_validation :set_expires_at
  after_create :update_kase_rewards_count, :update_kase_expires_at
  
  #--- class methods
  class << self
    
    # find options for "visible" responses, terms of "einsehbar"
    # resembles "visible?" instance method, returns records for states NOT in:
    #
    #   * created
    #   * suspended
    #   * deleted
    #   * closed
    #
    def find_options_for_visible(options={})
      {:conditions => ["rewards.status NOT IN (?)", ["created", "suspended", "deleted", "closed"]],
        :order => "rewards.updated_at DESC"}.merge_finder_options(options)
    end
    
  end

  #--- instance methods
  
  # assigns a payment type and throws exceptio on unsupported 
  # payment_types. Today, we only support :piggy_bank as we 
  # will use the kase owner's piggy_bank instance to authorize
  # the case
  def payment_type=(value)
    @payment_type = value
    unless value == :piggy_bank
#      raise "Only :piggy_bank is supported as payment type with this method. " +
#        "To use other payment types use @kase.payment_object = PaymentType.build(:visa)"
    end
  end

  # returns payment type based on assigned payment object or payment type
  def payment_type
    @payment_object ? PaymentMethod.payment_type(@payment_object) : @payment_type || :piggy_bank
  end
  
  # For acts_as_sellable, to indicate that the price
  # of this kase may include tax if taxable is true
  def price_is_gross?
    true
  end

  # kase price is gross, so false
  def price_is_net?
    false
  end

  # returns true if tax can be charged for this kase
  def taxable?
    true
  end
  
  def copy_name(options={})
    "Reward for %{type}".t % {:type => self.kase.class.human_name}
  end
  
  def copy_description(options={})
    "Reward for %{type} \"%{title}\"".t % {:type => self.kase.class.human_name,
      :title => self.kase.title}
  end

  def default_currency
    self.sender ? self.sender.default_currency : "USD"
  end

  # returns :on or :in depending on the option selected when the kase gets created
  def expiry_option
    @expiry_option || :in
  end

  # set expiry option 'on' or :on or 'in' or 'in'
  # combined with expiry days this result in a default of "in 3 days"
  def expiry_option=(value)
    @expiry_option = value.to_sym if value
  end

  # overloads built-in expires_at setter and
  # makes sure that expiry_option is set to :on
  def expires_at=(time)
    self.expiry_option = :on
    self[:expires_at] = time
  end

  # set expires_at if expiry is set to 'in' by expiry_days from now
  def set_expires_at
    self[:expires_at] = case self.expiry_option 
      when :in then Time.now.utc + (self.expiry_days || 3).days
      when :on then self[:expires_at]
      else self[:expires_at]
    end
  end

  # intercepts price=, allows to correctly assign string prices, like "2.00" or "$2.00"
  def price_with_string=(value)
    if value.is_a?(String)
      @price_as_string = value
      self.price_without_string = value.to_money(self.default_currency) if value
    else
      self.price_without_string = value
    end
  end
  alias_method_chain :price=, :string

  # returns true if expiry option is set to :in
  def expiry_in?
    :in == self.expiry_option
  end

  # returns true if expiry option is set to :on
  def expiry_on?
    :on == self.expiry_option
  end
  
  # sets the number of days this kase expires
  def expiry_days=(value)
    @expiry_days = value.to_i
  end
  
  # returns the number of days the kase expires in or returns default (e.g. 3)
  def expiry_days
    @expiry_days || DEFAULT_EXPIRY_DAYS
  end

  # Returns true if there is still time left to solve this case or true if this case does not expire
  def has_not_expired?
    self.expires_at ? self.expires_at > Time.now.utc : true
  end
  
  # returns true if this case is past it's expiration date or false if this case does not expire
  def has_expired?
    self.expires_at ? self.expires_at < Time.now.utc : false
  end
  
  # is there still enough time left to solve this case within time_to_solve period?
  def has_time_to_solve?
    self.expires_at ? Time.now.utc + self.time_to_solve < self.expires_at : true
  end
  
  def has_not_enough_time_to_solve?
    self.expires_at ? Time.now.utc + self.time_to_solve > self.expires_at : false
  end
  
  # absolute time need to solve, e.g. 1 hour
  def time_to_solve
    self.kase && self.kase.time_to_solve ? self.kase.time_to_solve : 1.hour
  end
  
  # returns minimum possible reward price offer in sender's currency,
  # which is the maximum of the two following
  #
  #   * minimum offer price depending on payment_object
  #   * highest current active kase reward
  #
  def min_price
    result = case self.payment_type
      when :credit_card then Money.new(MIN_CREDIT_CARD_OFFER_CENTS, self.default_currency)
      else
        Money.new(MIN_PIGGY_BANK_OFFER_CENTS, self.default_currency)
    end
    if self.kase && self.kase.offers_reward?
      result = Money.max(result, self.kase.max_reward_price || result).convert_to(self.default_currency) +
        Money.new(MIN_PIGGY_BANK_OFFER_CENTS, self.default_currency)
    end
    result
  end

  # returns the maximum possible monetary price for a reward offer in sender's currency
  def max_price
    Money.new(MAX_OFFER_CENTS, self.default_currency)
  end
  
  # returns true if there is an active reward from the same sender of this reward
  def active_reward_from_sender?
    !self.kase.rewards.active.find(:all, :conditions => {:sender_id => self.sender.id}).empty?
  end

  protected
  
  # make sure we have a default payment type and payment object
  def after_initialize
    self.payment_type = if @payment_object 
      PaymentMethod.payment_type(@payment_object)
    else
      @payment_type || :piggy_bank
    end
    self.build_payment_object_from_payment_type
    # Important! 
    # reassign price, this time with sender's default currency
    self.price = @price_as_string if @price_as_string 
    
    self.expires_at = self.kase.expires_at if self.kase && self.kase.expires_at
  end

  # set expires_at if expiry is set to 'in' by expiry_days from now
  def set_expires_at
    self[:expires_at] = case self.expiry_option 
      when :in then Time.now.utc + (self.expiry_days || DEFAULT_EXPIRY_DAYS).days
      when :on then self[:expires_at]
      else self[:expires_at]
    end
  end
  
  # builds payment object from payment_type in before callback
  def build_payment_object_from_payment_type
    if self.sender && self.payment_type == :piggy_bank
      self.payment_object = self.sender.piggy_bank
    end
  end
  
  def validate
    max_price_display = self.max_price.format

    if self.payment_object
      # min/max ranges
      min_price_display = self.min_price.format
      cents_range = Range.new(self.min_price.cents, self.max_price.cents)
      
      # check, if sufficient funds available
      if PaymentMethod.piggy_bank?(self.payment_object)
        self.errors.add(:price, "exceeds available #{SERVICE_PIGGYBANK_NAME} balance of %{amount}".t % {
          :amount => self.payment_object.balance.format
        }) if self.price.convert_to(self.sender.default_currency) > self.payment_object.balance
      end
      
      if !cents_range.include?(self.cents)
        errors.add(:price, I18n.t('activerecord.errors.messages.price_range') % {
          :min => min_price_display,
          :max => max_price_display
        })
      end
    else
      if !(1..MAX_OFFER_CENTS).include?(self.cents)
        errors.add(:price, I18n.t('activerecord.errors.messages.price_too_high') % {
          :max => max_price_display
        })
      end
    end

    if self.expiry_in?
      errors.add(:expiry_days, I18n.t('activerecord.errors.messages.days_range') % {
        :min => "#{MIN_EXPIRY_DAYS}",
        :max => "#{MAX_EXPIRY_DAYS}"
      }) if !(MIN_EXPIRY_DAYS..MAX_EXPIRY_DAYS).include?(self.expiry_days)
    end
    
    if self.expires_at.nil? || self.expires_at < (Time.now.utc + MIN_EXPIRY_DAYS.days - 1.hour) ||
      self.expires_at > (Time.now.utc + MAX_EXPIRY_DAYS.days)
      errors.add(:expires_at, I18n.t('activerecord.errors.messages.days_range') % {
        :min => "#{MIN_EXPIRY_DAYS}",
        :max => "#{MAX_EXPIRY_DAYS}"
      })
    end

    # reward kase must be in open state
    if self.kase && !self.kase.open?
      errors.add(:kase, I18n.t('activerecord.errors.messages.reward_kase_state'))
    end

  end
  
  # creates order with this reward as product and authorizes the payment using
  # the given payment object.
  # validates the offer price and adds errors in case the minimum or maximum
  # offer prices are over-/underrun
  # returns payment object (merchant sidekick)
  def purchase_and_authorize(given_payment_object=nil)
    order, payment = nil, nil
    payment_object = given_payment_object || self.payment_object
    
    if self.valid?
      order = self.sender.purchase(self.sender.cart.cart_line_item(self))
      payment = order.authorize(payment_object)
    end
    return order, payment
  end
  
  # authorizes payment for price using the payment object
  def authorize_payment
    if !self.pending_purchase_order && self.payment_object
      order, payment = self.purchase_and_authorize
      if payment && payment.success?
#        self.payment_object = nil # remove payment object so we can re-validate
        self.purchase_orders.reload
        return payment.success?
      end
    end
    false
  end
  
  # sets reward receiver, which is the accepted response's person or nil
  def accepted_receiver
    self.receiver ||= if accepted_response = self.responses.accepted.first
      accepted_response.person
    end
  end

  # in order to capture and sell the kase we must do the following steps:
  #
  #   * capture the authorized payment for this reward
  #   * "sell" this reward to partner who's response was accepted (accepted partner)
  #   * make the accepted partner's "purchase" a Luleka Service Fee (SF)
  #   * "sell" SF to accepted partner and transfer amount to Luleka Piggy Bank
  #
  def capture_and_cash
    if self.active? && self.pending_purchase_order && self.accepted_receiver

      # start transaction
      ActiveRecord::Base.transaction do
        capture = self.pending_purchase_order.capture
        if capture.success?
        
          sales_order = self.accepted_receiver.sell_to(self.sender, self.accepted_receiver.cart.cart_line_item(self))
          cash = sales_order.cash(self.accepted_receiver.piggy_bank)
        
          if cash.success?
            self.pending_purchase_order.update_origin_address_from(self.accepted_receiver)
            
            service_fee_product = Product.service_fee(:country_code => self.accepted_receiver.default_country)
            
            if service_fee_product
              reward_item = self.accepted_receiver.cart.add(self)
              service_fee_item = self.accepted_receiver.cart.add(service_fee_product, 1, :dependent => reward_item)
              
              purchase_order = self.accepted_receiver.purchase(service_fee_item,
                :seller => Organization.probono)
              charge = purchase_order.pay(self.accepted_receiver.piggy_bank)
          
              if charge.success?
                probono = Organization.probono

                if probono

                  probono_sales_order = probono.sell_to(self.accepted_receiver, service_fee_item)
                  probono_cash = probono_sales_order.cash(probono.piggy_bank)

                  if probono_cash.success?
                    # congrats, we are done!
                    return true
                  else
                    logger.error "Error cashing service fee sales order {#{probono_sales_order.id}} " +
                      "for reward {#{self.id}} kase {#{self.kase.id}}\"#{self.kase.title}\""
                    raise ActiveRecord::Rollback
                  end
                  
                else
                  logger.error "Error probono organization not found for reward {#{self.id}} kase {#{self.kase.id}} \"#{self.kase.title}\""
                  raise ActiveRecord::Rollback
                end

              else
                logger.error "Error when charging service fee to partner on order " + 
                  "##{purchase_order.number} for kase {#{self.kase.id}} \"#{self.kase.title}\""
                raise ActiveRecord::Rollback
              end
            else
              logger.error "Error could not find service fee for accepted_receiver {#{self.accepted_receiver.id}}, " + 
                "country code \"#{self.accepted_receiver.default_country}\" for kase {#{self.kase.id}} \"#{self.kase.title}\""
              raise ActiveRecord::Rollback
            end
          
          else
            logger.error "Error when cashing sales order {#{sales_order.id}} #{sales_order.number} for kase {#{self.kase.id}}\"#{self.kase.title}\""
            raise ActiveRecord::Rollback
          end
          
        else
          logger.error "Error when capturing pending order {#{self.pending_purchase_order.id}} #{self.pending_purchase_order.number} for kase {#{self.kase.id}} \"#{self.kase.title}\""
          raise ActiveRecord::Rollback
        end
      end
    end
    false
  end
  
  # returns the authorizable purchase order that can be captured when solve!
  def pending_purchase_order
    @pending_purchase_order_cache || @pending_purchase_order_cache = if self.purchase_orders
      self.purchase_orders.select(&:pending?).last unless self.purchase_orders.empty?
    end
  end
  
  # voids all pending purchase orders
  def void_pending_purchase_orders
    self.purchase_orders.select(&:pending?).each {|o| o.void}
  end

  # can reward be activated by placing a payment authorization?
  def can_activate?
    self.authorize_payment
  end

  # used by state guard, effectively pais an caches authorized reward
  def can_cash?
    self.capture_and_cash
  end

  def do_activate
    self.activated_at = Time.now.utc
    self.kase.sweep_max_reward_price_cache if self.kase
    self.send_activated
  end

  def after_activate
    self.update_kase_rewards_count
    self.update_kase_price
  end

  # called on paid state transition
  def do_pay
    self.paid_at = Time.now.utc
    self.send_paid
  end

  # called on closed state transition
  def do_close
    self.void_pending_purchase_orders
    self.closed_at = Time.now.utc
    self.kase.sweep_max_reward_price_cache if self.kase
    self.send_canceled
  end
  
  def after_closed
    self.update_kase_rewards_count
    self.update_kase_price
  end

  def send_activated
    # to sender putting money down for reward
    I18n.switch_locale self.sender.default_locale do 
      RewardMailer.deliver_activated(self, self.sender)
    end
    # to kase owner, unless same as reward owner
    I18n.switch_locale self.kase.person.default_locale do 
      RewardMailer.deliver_activated(self, self.kase.person) unless self.sender == self.kase.person
    end
  end
  
  def send_canceled
    # to sender putting money down for reward
    I18n.switch_locale self.sender.default_locale do 
      RewardMailer.deliver_canceled(self, self.sender)
    end
    # to kase owner, unless same as reward owner
    I18n.switch_locale self.kase.person.default_locale do 
      RewardMailer.deliver_canceled(self, self.kase.person) unless self.sender == self.kase.person
    end
  end

  def send_paid
    # to sender putting money down for reward
    I18n.switch_locale self.sender.default_locale do 
      RewardMailer.deliver_paid(self, self.sender) 
    end  
    # to person receiving reward -> receiver == accepted partner
    I18n.switch_locale self.accepted_receiver.default_locale do 
      RewardMailer.deliver_paid(self, self.accepted_receiver) 
    end
    # to kase owner, unless same as reward owner
    I18n.switch_locale self.kase.person.default_locale do 
      RewardMailer.deliver_paid(self, self.kase.person) unless self.sender == self.kase.person
    end
  end

  # update rewards count in association as we have to count only "visible" rewards
  def update_kase_rewards_count
    if self.kase && self.kase.class.columns.to_a.map {|a| a.name.to_sym}.include?(:rewards_count)
      self.kase.class.transaction do 
        self.kase.lock!
        self.kase.update_attribute(:rewards_count, 
          self.kase.rewards.count(self.class.find_options_for_visible))
      end
    end
  end

  def update_kase_price
    if self.kase && self.kase.class.columns.to_a.map {|a| a.name.to_sym}.include?(:price_cents)
      self.kase.class.transaction do 
        self.kase.lock!
        sum = Money.new(0, self.kase.default_currency)
        self.kase.rewards.visible.each do |reward|
          sum += reward.price.convert_to(self.kase.default_currency)
        end
        self.kase.update_attribute(:price, sum)
      end
    end
  end
  
  # set expires_at for kase if not already 
  def update_kase_expires_at
    if self.kase && self.kase.expires_at.nil? && self.expires_at && !self.has_expired?
      self.kase.class.transaction do 
        self.kase.lock!
        self.kase.update_attribute(:expires_at, self.expires_at) if self.kase.expires_at.nil?
      end
    end
  end
  
  # used in before_create to cancel all previous awards for this sender
  def cancel_active_sender_reward
    self.kase.rewards.active.find(:all, :conditions => {:sender_id => self.sender.id}).each do |reward|
      reward.cancel!
    end
  end
  
end
