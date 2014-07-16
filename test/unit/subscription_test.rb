require File.dirname(__FILE__) + '/../test_helper'

class SubscriptionTest < ActiveSupport::TestCase
  fixtures :topics, :people

  def test_should_create
    sub = Subscription.create(
      :person => people(:homer),
      :product => topics(:three_month_partner_membership_en),
      :length_in_issues => 6
    )
    assert sub.valid?
    assert_equal :created, sub.current_state
    assert_equal 6, sub.length_in_issues
    assert_nil sub.activated_at
    assert_nil sub.suspended_at
    assert_nil sub.last_renewal_on
  end
  
  def should_not_validate
    sub = build_subscription(invalid_subscription_attributes)
    assert !sub.valid?
    assert :length_in_issues, sub.errors.invalid?(:length_in_issues)
  end
  
  def test_should_activate
    sub = create_subscription
    assert_equal :created, sub.current_state
    assert sub.activate!
    assert_equal :active, sub.current_state
    assert_equal Time.now.utc.to_date, sub.activated_at.to_date
    assert_equal Date.today, sub.last_renewal_on
  end

  def test_should_suspend
    sub = create_subscription
    assert_equal :created, sub.current_state
    assert sub.activate!
    assert_equal :active, sub.current_state
    assert sub.suspend!
    assert_equal :suspended, sub.current_state
  end

  def test_should_renew
    sub = create_subscription
    assert_equal :created, sub.current_state
    assert sub.activate!
    assert_equal :active, sub.current_state
    sub.update_attributes(:last_renewal_on => (Time.now.utc - 5.days).to_date)
    sub.reload
    assert_equal (Time.now.utc - 5.days).to_date, sub.last_renewal_on
    assert sub.renew!
    assert_equal Date.today, sub.last_renewal_on
  end

  def test_should_exprire_on
    sub = create_subscription(:length_in_issues => 3)
    sub.activate!
    assert sub.valid?
    assert_equal (Time.now.utc + 3.months).to_date, sub.expires_on
  end

  def test_should_not_exprire_on
    sub = create_subscription(:length_in_issues => 3)
    assert sub.valid?
    sub.activate!
    sub.suspend!
    assert_nil sub.expires_on
  end

  def xtest_has_partner_membership_finder
    assert_difference Subscription, :count, 2 do 
      create_subscription(:product => topics(:three_month_partner_membership_en))
      create_subscription(:product => topics(:one_year_partner_membership_en))
    end
    subs = Subscription.partner_subscriptions
    assert subs.map{|s| s.product}.map(&:name).include?("Three-Month Partner Membership")
    assert subs.map{|s| s.product}.map(&:name).include?("One-Year Partner Membership")
  end
  
  def test_should_be_expired
    sub = create_subscription
    assert sub.expired?
    
    sub.activate!
    sub.update_attributes(
      :last_renewal_on => (Time.now.utc - 1.month - 1.day).to_date,
      :length_in_issues => 1
    )
    sub.reload
    assert sub.expired?
  end

  def test_should_not_be_expired
    sub = create_subscription
    sub.activate!
    assert !sub.expired?
    
    sub.update_attributes(
      :last_renewal_on => (Time.now.utc - 1.month).to_date,
      :length_in_issues => 1
    )  
    sub.reload
    assert !sub.expired?
  end
  
  protected
  
  def valid_subscription_attributes(options={})
    {
      :person => people(:homer),
      :product => topics(:three_month_partner_membership_en),
      :length_in_issues => 12,
      :auto_renew => false
    }.merge(options)
  end

  def invalid_subscription_attributes(options={})
    {
      :person => people(:homer),
      :product => topics(:three_month_partner_membership_en),
      :length_in_issues => nil,
      :auto_renew => false
    }.merge(options)
  end
  
  def create_subscription(options={})
    Subscription.create(valid_subscription_attributes(options))
  end

  def build_subscription(options={})
    Subscription.new(valid_subscription_attributes(options))
  end
  
end
