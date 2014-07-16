# A claiming is a way to register a user to support a company as employee. A claiming request needs to
# be accepted and confirmed using the given company email address or phone number. The email address
# may be used to send a confirmation request that is accepted by the recipient if a site url is available
#
# relevant attributes:
#
#   * email
#   * phone
#   * role
#   * message
#
require 'digest/sha2'
class Claiming < Request
  
  #--- associations
  belongs_to :person, :class_name => 'Person', :foreign_key => :sender_id
  belongs_to :organization, :class_name => 'Organization', :foreign_key => :tier_id
  belongs_to :product, :class_name => 'Product', :foreign_key => :topic_id
  has_many :products,
    :through => :children,
    :class_name => 'Product',
    :source => :product
    
  #--- mixins 
  acts_as_tree
  
  #--- validations
  validates_presence_of :sender_id
  validates_presence_of :tier_id
  validates_presence_of :topic_id, :if => Proc.new {|u| !u.root?}
  validates_uniqueness_of :tier_id, :scope => [:parent_id, :sender_id], :if => :root?,
    :message => I18n.t('activerecord.errors.messages.claim_exclusion')
  validates_email_format_of :email, :allow_nil => true
  validates_presence_of :role
  
  #--- state machine
  acts_as_state_machine :initial => :queued, :column => :status
  state :queued
  state :pending, :enter => :do_pending
  state :accepted,  :enter => :do_accept
  state :declined, :enter => :do_decline
  state :deleted, :enter => :do_delete

  event :register do
    transitions :from => :queued, :to => :pending
  end
  
  event :accept do
    transitions :from => :pending, :to => :accepted
  end

  event :decline do
    transitions :from => :pending, :to => :decline
  end
  
  event :delete do
    transitions :from => [:queued, :pending, :accepted, :declined], :to => :deleted
  end
  
  after_save :save_products

  #--- class methods

  class << self
    
    def find_by_activation_code_and_person(activation_code, person)
      find(:first, :conditions => {:activation_code => activation_code, :sender_id => person.id}) if person
    end

    # override from active_record_ext.rb
    def content_column_names
      content_columns.map(&:name) - %w(status accepted_at reminded_at deleted_at sent_at declined_at
        activation_code uuid first_name last_name language updated_at created_at)
    end
    
  end
  
  #--- callbacks
  before_validation :email
  
  #--- instance methods

  # returns true if this is the root node
  def root?
    self.parent.nil?
  end
  
  # assigns products to the root claiming
  def product_ids=(ids)
    self.products = Product.find(:all, :conditions => ["id IN (?)", ids.map(&:to_i)])
  end

  # returns an array of assigned product ids
  def product_ids
    new_record? ? (@products ? @products.map(&:id) : []) : self.root.products.map(&:id)
  end
  
  # intercepts with the products association and returns products from instance
  # variable if new_record?
  def products_with_cache
    if new_record?
      @products || []
    else
      self.products_without_cache
    end
  end
  alias_method_chain :products, :cache
  
  # assign products
  def products=(some_products)
    if new_record?
      @products = some_products
    else
      some_products.each {|p| self.root.children.create({
        :product => p,
        :organization => self.root.organization,
        :person => self.root.person
      }.merge(self.content_attributes)) unless self.root.children.select {|c| c.product}.map(&:product).include?(p)}
    end
  end

  # save products after object has been saved
  def save_products
    self.products = @products if @products
  end

  # validates
  #   * either phone or email must be provided
  #   * email must be within the organziation's worldwide domain
  def validate
    super
    if root? && (self.email.to_s.empty? || errors.invalid?(:email)) && self.phone.to_s.empty?
      errors.add(:base, "Phone number or email address must be provided".t)
    end
    if self.email
      unless self.organization.worldwide.map(&:site_domain).compact.include?(self.email_domain)
        errors.add(:email, "not a valid email address at %{org}".t % {:org => self.organization.root.name})
      end
    end
  end

  # returns the company domain portion of the email address
  # e.g. 'apple.com' from 'steve@apple.com'
  def email_domain
    if !self[:email].blank?
      split_host = URI.parse("#{self[:email]}").path.split('@')
      "#{split_host.last}" if 2 == split_host.size
    else
      self.organization.site_domain if self.organization
    end
  rescue URI::InvalidURIError
    nil
  end

  # returns the email from attributes or assembles it using email_name and organization
  def email
    if self[:email] && !@email_name
      self[:email]
    elsif self.email_name && self.email_domain
      self[:email] = "#{self.email_name}@#{self.email_domain}"
    end
  end

  # assigns the front portion of an email name
  #
  # e.g.
  #
  #   "steve" of steve@apple.com
  #
  def email_name=(name)
    unless name.blank?
      @email_name = name
      self.email = "#{name}@#{self.email_domain}" if self.email_domain
    end
  end
  
  # returns the name of the email front portion if any
  def email_name
    @email_name || if self[:email]
      split_host = URI.parse("#{self[:email]}").path.split('@')
      "#{split_host.first}" if 2 == split_host.size
    end
  rescue URI::InvalidURIError
    nil
  end

  # fake attribute getter for message "message"
  def description
    self[:message]
  end
  
  # fake attribute setter for message "message"
  def description=(message)
    self[:message] = message
  end

  protected
  
  def make_activation_code
    self.deleted_at = nil
    self.activation_code = Digest::SHA1.hexdigest( Time.now.to_s.split(//).sort_by {rand}.join )
  end
  
  def do_delete
    self.deleted_at = Time.now.utc
  end

  def do_accept
    @accepted = true
    self.accepted_at = Time.now.utc
    self.deleted_at = self.activation_code = nil
    
    unless Employment.find_by_person_id_and_tier_id(self.root.sender_id, self.root.tier_id)
      if employment = Employment.create(:employee => self.root.person, :employer => self.root.organization,
          :role => self.root.role)
        if employment.valid? && employment.activate!
          I18n.switch_locale self.root.person.default_language || Utility.current_default_language do
            ClaimingMailer.deliver_confirmation(self) if self.email
          end
        end
      end
    end
  end

  def do_decline
    self.declined_at = Time.now.utc
  end

  # generate activation code and send confirmation request if email provided
  def do_pending 
    make_activation_code
    ClaimingMailer.deliver_confirmation_request(self) if self.email && self.activation_code
  end
  
end
