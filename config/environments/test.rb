# Settings specified here will take precedence over those in config/environment.rb

# The test environment is used exclusively to run your application's
# test suite.  You never need to work with it otherwise.  Remember that
# your test database is "scratch space" for the test suite and is wiped
# and recreated between test runs.  Don't rely on the data there!
config.cache_classes = true

# Log error messages when you accidentally call methods on nil.
config.whiny_nils = true

# Show full error reports and disable caching
config.action_controller.consider_all_requests_local = true
config.action_controller.perform_caching             = false

# Disable request forgery protection in test environment
config.action_controller.allow_forgery_protection    = false

#--- session sharing between subdomains
ActionController::CgiRequest::DEFAULT_SESSION_OPTIONS.update(
  :session_domain => '.luleka.local'
)

#--- mailer
# Tell ActionMailer not to deliver emails to the real world.
# The :test delivery method accumulates sent emails in the
# ActionMailer::Base.deliveries array.
config.action_mailer.delivery_method = :test

# setup active merchant gateway
config.after_initialize do 
  #--- merchant
  ActiveMerchant::Billing::Base.mode = :test
  CreditCardPayment.gateway = ActiveMerchant::Billing::BogusGateway.new
  PaypalDepositAccount.gateway = ActiveMerchant::Billing::BogusGateway.new
  
  #--- geokit
  GeoKit::default_units = :kms
  GeoKit::default_formula = :sphere
  GeoKit::Geocoders::timeout = 3

  GeoKit::Geocoders::maxmind_ip = ''  # Eric K's key 'NOE3u6K7vuWq'
  GeoKit::Geocoders::yahoo      = '1DKmXdHV34GtDujSuUZVhOQLOVY2a8zZLwR8BhtmCTsDDSwYSKnwEbEXnmz9SspGiqI-'
  GeoKit::Geocoders::google     = 'ABQIAAAA3jIP-UwrX5YmhumykFl2_RTJQa0g3IQ9GZqIMmInSLzwtGDKaBSG8ZDHOTJL2qdtpxep7fkFAsL6Qw'

  GeoKit::Geocoders::geocoder_us = false 
  GeoKit::Geocoders::geocoder_ca = false

  GeoKit::Geocoders::provider_order = [:google, :yahoo, :us]
  GeoKit::Geocoders::ip_provider_order = [:ip] # [:maxmind_ip, :ip]

  #--- mail
  Notifier.site_url    = 'www.testluleka.net'
  Notifier.admin_email = 'Test Admin <noreply@testluleka.com>' 
  Notifier.info_email  = 'Test Info <info@testluleka.com>'
  Notifier.support_email  = 'Support <support@luleka.net>'
end

config.to_prepare do
  #--- STI dependencies
  # http://dev.rubyonrails.org/ticket/11269
  Utility.require_sti_dependencies
end

#--------------------------------------------------------------------------------------------------
# Test specific required libraries (test env only!)
#--------------------------------------------------------------------------------------------------
require 'ruby-debug'
