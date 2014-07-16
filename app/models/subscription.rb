# Subscriptions are recurring services that were purchased for Probono, such as
# a partner subscription, or any other future kinds of subscriptions.
class Subscription < ActiveRecord::Base
  #--- associations
  belongs_to :person
  belongs_to :product

  #--- state machine
  acts_as_state_machine :initial => :created, :column => :status
  state :created
  state :active, :enter => :do_activate
  state :suspended, :enter => :do_suspend

  event :activate do
    transitions :from => :created, :to => :active, :guard => :valid?
  end

  event :renew do
    transitions :from => :active, :to => :active, :guard => :do_renew
  end
  
  event :suspend do
    transitions :from => [:created, :active], :to => :suspended
  end
  
  def validate
    self.errors.add(:length_in_issues, "appears to be invalid".t) if self.length_in_issues.to_i <= 0
  end
  
  #--- instance methods
  
  # returns expiry date of the subscription if activate, otherwise, nil
  # TODO take user time zone into account
  def expires_on
    case self.current_state
      when :active then (self.last_renewal_on.to_time + self.length_in_issues.months).to_date
    end
  end
  
  # returns true if expired, suspended, not activated
  def expired?
    return self.expires_on < Date.today if self.expires_on
    true
  end
  
  protected
  
  def do_activate
    self.activated_at = Time.now.utc
    self.last_renewal_on = Date.today
    if self.product.is_partner_subscription?
      self.person.upgrade!
      self.person.partner_membership_expires_on = nil # clear the cache
    end
  end
  
  def do_suspend
    self.suspended_at = Time.now.utc
  end
  
  def do_renew
    self.last_renewal_on = Date.today
    true
  end
  
end
