# Settings specified here will take precedence over those in config/environment.rb

# In the development environment your application's code is reloaded on
# every request.  This slows down response time but is perfect for development
# since you don't have to restart the webserver when you make code changes.
config.cache_classes = false

# Log error messages when you accidentally call methods on nil.
config.whiny_nils = true

# Show full error reports and disable caching
config.action_controller.consider_all_requests_local = true
config.action_view.debug_rjs                         = true
config.action_controller.perform_caching             = false  # true for fragment caching

#--- asset host
# Enable serving of images, stylesheets, and javascripts from an asset server
ActionController::Base.asset_host = Proc.new {|source, request|
  if request.ssl?
    "#{request.protocol}a#{source.hash % 5}.#{ActionMailer::Base.default_url_options[:host] || request.host_with_port}"
  else
    "#{request.protocol}a#{source.hash % 5}.#{ActionMailer::Base.default_url_options[:host] || request.host_with_port}"
  end
}

#--- session sharing between subdomains
config.action_controller.session[:domain]  = '.luleka.local'

#--- action mailer
require 'smtp_tls'
config.action_mailer.delivery_method = :smtp
config.action_mailer.default_url_options = {
  :host => 'luleka.local'
}

#config.action_mailer.smtp_settings = {
ActionMailer::Base.smtp_settings = {
  :tls => true,
  :address => "smtp.gmail.com",
  :port => "587",
  :domain => 'luleka.net',
  :authentication => :plain, 
  :user_name => "mailer@luleka.net",
  :password => "probonow3rks"
}
config.action_mailer.default_charset = "utf-8"
config.action_mailer.raise_delivery_errors = false
config.action_mailer.perform_deliveries = true
# Tell ActionMailer not to deliver emails to the real world.
# The :test delivery method accumulates sent emails in the
# ActionMailer::Base.deliveries array.
#config.action_mailer.delivery_method = :test

# setup active merchant gateway
config.after_initialize do 
  #--- setup
  #--- active merchant
  # ActiveMerchant::Billing::Base.mode = :test
  # CreditCardPayment.gateway = ActiveMerchant::Billing::BogusGateway.new

  CreditCardPayment.gateway = :paypal_gateway
  PaypalDepositAccount.gateway = :paypal_gateway

  #--- geokit
  GeoKit::default_units = :kms
  GeoKit::default_formula = :sphere
  GeoKit::Geocoders::timeout = 3

  GeoKit::Geocoders::maxmind_ip = '' # Eric K's key 'NOE3u6K7vuWq'
  GeoKit::Geocoders::yahoo      = '1DKmXdHV34GtDujSuUZVhOQLOVY2a8zZLwR8BhtmCTsDDSwYSKnwEbEXnmz9SspGiqI-'
  GeoKit::Geocoders::google     = 'ABQIAAAA3jIP-UwrX5YmhumykFl2_RTJQa0g3IQ9GZqIMmInSLzwtGDKaBSG8ZDHOTJL2qdtpxep7fkFAsL6Qw'

  GeoKit::Geocoders::geocoder_us = false 
  GeoKit::Geocoders::geocoder_ca = false

  GeoKit::Geocoders::provider_order = [:google, :yahoo, :us]
  GeoKit::Geocoders::ip_provider_order = [:ip] # [:maxmind_ip, :ip]
end

config.to_prepare do
  require_dependency 'smtp_tls'
  Utility.site_domain = "luleka.local"
  Utility.site_url = Notifier.site_url = 'http://luleka.local'
  
  Notifier.service_email  = '"Service | luleka.com" <service@luleka.com>'
  Notifier.admin_email    = '"Admin | luleka.com" <admin@luleka.com>'
  Notifier.noreply_email  = '"Info | luleka.com" <noreply@luleka.com>'
  Notifier.info_email     = '"Info | luleka.com" <info@luleka.com>'
  Notifier.support_email  = '"Support | luleka.com" <support@luleka.com>'
  Notifier.error_email    = '"Error | luleka.com" <error@luleka.com>'
  
  # deposit account
  PaypalDepositAccount.gateway = ActiveMerchant::Billing::BogusGateway.new

  #--- STI dependencies
  # http://dev.rubyonrails.org/ticket/11269
  Utility.require_sti_dependencies
  
  #--- pre launch
  Utility.pre_launch = false
end

#--------------------------------------------------------------------------------------------------
# development specific required libraries (development env only!)
#--------------------------------------------------------------------------------------------------
require 'ruby-debug'
