ENV["RAILS_ENV"] = "test"

require File.expand_path(File.dirname(__FILE__) + "/../config/environment")
require 'mocha'
require 'test_help'
require File.expand_path(File.dirname(__FILE__) + "/authenticated_test_helper")

Utility.require_sti_dependencies

class ActiveSupport::TestCase
  include AuthenticatedTestHelper
  
  # Transactional fixtures accelerate your tests by wrapping each test method
  # in a transaction that's rolled back on completion.  This ensures that the
  # test database remains unchanged so your fixtures don't have to be reloaded
  # between every test method.  Fewer database queries means faster tests.
  #
  # Read Mike Clark's excellent walkthrough at
  #   http://clarkware.com/cgi/blosxom/2005/10/24#Rails10FastTesting
  #
  # Every Active Record database supports transactions except MyISAM tables
  # in MySQL.  Turn off transactional fixtures in this case; however, if you
  # don't care one way or the other, switching from MyISAM to InnoDB tables
  # is recommended.
  #
  # The only drawback to using transactional fixtures is when you actually 
  # need to test transactions.  Since your test is bracketed by a transaction,
  # any transactions started in your code will be automatically rolled back.
  self.use_transactional_fixtures = true

  # Instantiated fixtures are slow, but give you @david where otherwise you
  # would need people(:david).  If you don't want to migrate your existing
  # test cases which use the @david style and don't mind the speed hit (each
  # instantiated fixtures translates to a database query per test method),
  # then set this back to true.
  self.use_instantiated_fixtures  = false

  # Setup all fixtures in test/fixtures/*.(yml|csv) for all tests in alphabetical order.
  #
  # Note: You'll currently still have to declare fixtures explicitly in integration tests
  # -- they do not yet inherit this setting
#  fixtures :all

  # Add more helper methods to be used by all tests here...
  def self.all_fixtures
    fixtures :kases, :severities, 
      :people, :users, :addresses, :taggings, :tags, :topics, :product_prices, :products_product_prices,
      :product_lines, :subscriptions, :tiers, :tier_categories, :kontexts, :piggy_bank_accounts, :exchange_rates, :vouchers,
      :tax_rates, :spoken_languages, :people_spoken_languages, :responses, :personal_statuses, :pages, :messages,
      :friendships, :deposit_accounts, :comments, :bad_words, :admin_users, :academic_titles, :rewards, :reputations,
      :reward_rates, :admin_roles, :admin_roles_admin_users, :"/locales", :translations
  end
  
end


#--- shared session
# from http://www.ruby-forum.com/topic/54022
module ActionController

  class TestRequest
    # add in setup function if subdomain needed
    # @request.with_subdomain('primalgrasp')
    def with_subdomain(subdomain=nil)
      the_host_name = "luleka.local"
      the_host_name = "#{subdomain}.#{the_host_name}" if subdomain
      self.host = the_host_name
      self.env['SERVER_NAME'] = the_host_name
      self.env['HTTP_HOST'] = the_host_name
    end
    
  end
end

#--- shared helpers

# used in assert_routings, etc.
# hash_for_path(:new_user) returns the hash_for_new_user_path 
# minus some un-needed attributes
def hash_for_path(path, options={})
  result = send("hash_for_#{path}_path".to_sym).merge(options)
  result.delete(:only_path)
  result.delete(:use_route)
  result
end

def current_voucher=(voucher)
  unless voucher.is_a?(Voucher)
    voucher = vouchers(voucher)
  end
  @request.session[:voucher_id] = voucher.id
end

def assign_current_voucher(voucher)
  self.current_voucher = voucher
end

def current_voucher
  if voucher_id = @request.session[:voucher_id]
    Voucher.find_by_id(voucher_id)
  end
end

def assert_voucher(kind)
  assert current_voucher, 'session should contain voucher'
  assert_equal kind, current_voucher, "session should contain a #{kind}"
end

def current_locale=(locale)
  @request.session[:locale] = locale
end

def assign_current_locale(locale)
  self.current_locale = locale
end

def current_locale
  @request.session[:locale]
end

def assert_locale(kind)
  assert_equal kind, current_locale, "session should contain #{kind}"
end


def current_invitation=(invitation)
  unless invitation.is_a?(Invitation)
    invitation = invitations(invitation)
  end
  @request.session[:invitation_id] = invitation.id
end

def assign_current_invitation(invitation)
  self.current_invitation = invitation
end

def current_invitation
  if invitation_id = @request.session[:invitation_id]
    Invitation.find_by_id(invitation_id)
  end
end

# assign cart object or delete if nil is assigned
def current_cart=(new_cart)
  @request.session[:cart] = new_cart ? new_cart.to_yaml : nil
  @current_cart = new_cart || false
end

def assign_current_cart(new_cart)
  self.current_cart = new_cart
end

# returns a current cart instance if stored in the session
def current_cart
  @current_cart ||= load_cart_from_session unless @current_cart == false
end

# handles the cart loading from session 
def load_cart_from_session
  #--- leave due to YAML bug
  CartLineItem
  Product
  #--- end leave due to YAML bug
  persisted_cart = YAML.load(@request.session[:cart].to_s)
  # rebuild cart as persisted cart line items cannot be saved
  persisted_cart.line_items.each_with_index do |line_item, index|
    persisted_cart.line_items[index] = line_item.clone
  end if persisted_cart
  persisted_cart
end

def current_order=(order)
  unless order.is_a?(Order)
    order = orders(order)
  end
  @request.session[:order_id] = order.id
end

def assign_current_order(order)
  self.current_order = order
end

def current_order
  if order_id = @request.session[:order_id]
    Order.find_by_id(order_id)
  end
end

#--- organization

def valid_organization_attributes(options={})
  {
    :name => 'Trojan Power',
    :site_name => 'trojan',
    :site_url => 'http://www.trojan.com',
    :country_code => 'US',
    :language_code => 'en',
    :tax_code => '23-4527454',
    :category => tier_categories(:company),
    :created_by => people(:homer)
  }.merge(options)
end

def invalid_organization_attributes(options={})
  {}.merge(options)
end

def create_organization(options={})
  org = Organization.create(valid_organization_attributes(options))
  org.register!
  org
end

def create_company(options={})
  co = Company.create(valid_organization_attributes(options))
  co.register!
  co
end

def create_organizations(count, options={}, &block)
  count.times do |index|
    org = create_organization({:name => "Organization #{index + 1}", :site_name => "org#{index + 1}"}.merge(options))
    yield(org)
  end
end

def create_companies(count, options={})
  count.times do |index|
    org = create_company({:name => "Company #{index + 1}", :site_name => "org#{index + 1}"}.merge(options))
    yield(org)
  end
end

def build_organization(options={})
  Organization.new(valid_organization_attributes(options))
end

#--- product

def valid_product_attributes(options={})
  {
    :name => 'Wonderful',
    :language_code => 'de',
    :organization => tiers(:powerplant),
    :site_url => 'http://www.powerplant.gov'
  }.merge(options)
end

def invalid_product_attributes(options={})
  {}.merge(options)
end

def build_product(options={})
  Product.new valid_product_attributes(options)
end

def create_product(options={})
  pr = Product.create valid_product_attributes(options)
  pr.register!
  pr
end

#--- kase

def build_kase(options={})
  Kase.new(valid_kase_attributes(options))
end

def create_kase(options={})
  Kase.create(valid_kase_attributes(options))
end

def build_problem(options={})
  Problem.new(valid_kase_attributes({:title => "A new problem"}.merge(options)))
end

def create_problem(options={})
  Problem.create(valid_kase_attributes({:title => "A new problem"}.merge(options)))
end

def create_problems(count, options={})
  count.times do |index|
    (p = create_problem({:title => "Kase #{index}"}.merge(options))).activate!
  end
end

def build_question(options={})
  Question.new(valid_kase_attributes({:title => "A new question"}.merge(options)))
end

def create_question(options={})
  Question.create(valid_kase_attributes({:title => "A new question"}.merge(options)))
end

def build_praise(options={})
  Praise.new(valid_kase_attributes({:title => "A new praise"}.merge(options)))
end

def create_praise(options={})
  Praise.create(valid_kase_attributes({:title => "A new praise"}.merge(options)))
end

def build_idea(options={})
  Idea.new(valid_kase_attributes({:title => "A new idea"}.merge(options)))
end

def create_idea(options={})
  Idea.create(valid_kase_attributes({:title => "A new idea"}.merge(options)))
end

def valid_kase_attributes(options={})
  {
    :person => people(:homer),
    :severity => Severity.normal,
    :title => 'A new kase',
    :description => 'We have a new case'
  }.merge(options)
end

#--- tier

def valid_tier_attributes(options={})
  {
    :name => 'Trojan Power',
    :site_name => 'trojan',
    :site_url => 'http://www.trojan.com',
    :country_code => 'US',
    :type => 'Organization',
    :category => tier_categories(:company),
    :created_by => people(:homer),
    :owner_email => people(:homer).email
  }.merge(options)
end

def create_tier(options={})
  Tier.create(valid_tier_attributes(options))
end

def build_tier(options={})
  Tier.new(valid_tier_attributes(options))
end

#--- topic

def valid_topic_attributes(options={})
  {
    :name => 'Wonderful',
    :language_code => 'de',
    :tier => tiers(:powerplant),
    :site_url => 'http://www.powerplant.gov'
  }.merge(options)
end

def create_topic(options={})
  Topic.create(valid_topic_attributes(options))
end

def build_topic(options={})
  Topic.new(valid_topic_attributes(options))
end

#--- address

def valid_address_attributes(options={})
  {
    :first_name => "George",
    :last_name => "Bush",
    :gender => 'm',
    :street => "100 Washington St.",
    :postal_code => "95065",
    :city => "Santa Cruz",
    :province_code => "CA",
    :province => "California",
    :company_name => "Exxon",
    :phone => "+1 831 123-4567",
    :mobile => "+1 831 223-4567",
    :fax => "+1 831 323-4567",
    :country_code => "US",
    :country => "United States of America"
  }.merge(Address.middle_name? ? { :middle_name => "W." } : {}).merge(options)
end

def create_address(options={})
  Address.create(valid_address_attributes(options))
end

def build_address(options={})
  Address.new(valid_address_attributes(options))
end

#--- user

def create_user(options = {})
  record = User.create(valid_user_attributes(options))
  record.register! if record.valid?
  record
end

def build_user(options = {})
  record = User.new(valid_user_attributes(options))
  record
end

def valid_user_attributes(options={})
  {
    :login => 'quire', :email => 'quire@example.com', :password => 'quire', :password_confirmation => 'quire',
    :gender => 'm',
    :first_name => "Charly",
    :last_name => "Quire",
    :time_zone => 'Berlin',
    :language => 'en',
    :currency => 'USD'
#    :verification_code => 'want2test',
#    :verification_code_session => 'want2test'
  }.merge(options)
end

#--- user

def create_admin_user(options = {})
  record = AdminUser.create(valid_admin_user_attributes(options))
  record.register! if record.valid?
  record
end

def valid_admin_user_attributes(options={})
  {
    :login => 'quire', :email => 'quire@example.com', :password => 'quire', :password_confirmation => 'quire',
  }.merge(options)
end

#--- person

def build_person(options={})
  Person.new(valid_person_attributes(options))
end

def create_person(options={})
  Person.create(valid_person_attributes(options))
end

def valid_person_attributes(options={})
  {:first_name => "Hale", :last_name => "Berry", :email => "hale@berry.tt", :gender => "f"}.merge(options)
end

#--- claiming

def valid_claiming_attributes(options={})
  {
    :person => people(:homer),
    :organization => tiers(:luleka_us),
    :message => "Man, I am an employee.",
    :email => 'homer@luleka.net',
    :role => 'Product Manager'
  }.merge(options)
end

def create_claiming(options={})
  cl = Claiming.create(valid_claiming_attributes(options))
  cl.register!
  cl
end

def build_claiming(options={})
  Claiming.new(valid_claiming_attributes(options))
end

#--- location

def valid_location_attributes(options={})
  {
    :first_name => 'Robert',
    :last_name => 'Smith',
    :gender => 'm',
    :street => '100 Rousseau St.',
    :city => 'San Francisco',
    :postal_code => '94112',
    :province_code => 'CA',
    :country_code => 'US'
  }.merge(options)
end

def build_location(options={})
  Location.new valid_location_attributes(options)
end

def create_location(options={})
  Location.create valid_location_attributes(options)
end

def valid_geo_location
  geoloc = GeoKit::GeoLoc.new(
    :street_address => '100 Rousseau St',
    :city => 'San Francisco',
    :zip => '94112',
    :country_code => 'US',
    :state => 'CA',
    :lat => 37.720592,
    :lng => -122.443287
  )
  geoloc.success = true
  geoloc
end

#--- credit card

def build_credit_card(options={})
  ActiveMerchant::Billing::CreditCard.new(valid_credit_card_attributes(options))
end

def valid_credit_card_attributes(attrs = {})
  {
    :type                => "bogus",
    :number              => "1", # "4381258770269608", # Use a generated
    :verification_value  => "000",
    :month               => 1,
    :year                => Time.now.year + 1,
    :first_name          => 'Fred',
    :last_name           => 'Brooks'
  }.merge(attrs)
end

def invalid_credit_card_attributes(attrs = {})
  {
    :first_name => "first",
    :last_name => "last",
    :month => "8",
    :year => Time.now.year + 1,
    :number => "2",
    :type => "bogus"
  }.merge(attrs)
end

#--- voucher

def build_voucher(options={})
  Voucher.new(valid_voucher_attributes(options))
end

def create_voucher(options={})
  Voucher.create(valid_voucher_attributes(options))
end

def valid_voucher_attributes(options={})
  {
    :consignor => people(:homer),
    :consignee => people(:barney),
    :email => people(:homer).email,
    :type => :partner_membership,
    :expires_at => Time.now.utc + 3.months
  }.merge(options)
end

#--- rewards

def build_reward(options={})
  Reward.new(valid_reward_attributes(options))
end

def create_reward(options={})
  Reward.create(valid_reward_attributes(options))
end

def valid_reward_attributes(options={})
  {
    :kase => kases(:powerplant_leak),
    :sender => people(:barney),
    :payment_type => :piggy_bank,
    :price => Money.new(100, "USD"),
    :expires_at => Time.now.utc + 3.days
  }.merge(options)
end
  
#--- person class test helpers

Person.class_eval do
  
  def direct_deposit_and_return(amount)
    self.piggy_bank.direct_deposit(amount.is_a?(String) ? amount.to_money(self.default_currency) : amount)
    self
  end
  
  def repute_and_return(points, tier=nil)
    rp = Reputation.create(:receiver => self, :action => :repute_and_return, :points => points, :tier => tier)
    rp.activate!
    self.reload
    self
  end
  
end

#--- tier class test helpers

Tier.class_eval do
  
  def direct_deposit_and_return(amount)
    self.piggy_bank.direct_deposit(amount.is_a?(String) ? amount.to_money(self.default_currency) : amount)
    self
  end
  
end

#--- response

def valid_response_attributes(options={}, kase_options={})
  if kase = options.delete(:kase)
    kase.update_attributes(kase_options) unless kase_options.empty?
  else
    kase = create_kase(valid_kase_attributes({:type => :problem}.merge(kase_options)))
    kase.activate!
  end
  {
    :description => "this is my great answer",
    :kase => kase,
    :person => people(:bart),
    :severity => severities(:normal)
  }.merge(options)
end

def build_response(options={}, kase_options={})
  Response.new(valid_response_attributes(options, kase_options))
end

def create_response(options={}, kase_options={})
  Response.create(valid_response_attributes(options, kase_options))
end

#--- time warp
# Extend the Time class so that we can offset the time that 'now'
# returns.  This should allow us to effectively time warp for functional
# tests that require limits per hour, what not.
Time.class_eval do 
  class << self
    attr_accessor :testing_offset
    alias_method :real_now, :now
    
    def now
      real_now - testing_offset
    end
    alias_method :new, :now
  end
end
Time.testing_offset = 0

# Time warp to the specified time for the duration of the passed block
def pretend_now_is(time)
  begin
    Time.testing_offset = Time.now.utc - time.utc
    yield
  ensure
    Time.testing_offset = 0
  end
end
