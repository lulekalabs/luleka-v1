# Settings specified here will take precedence over those in config/environment.rb

# The production environment is meant for finished, "live" apps.
# Code is not reloaded between requests
config.cache_classes = true

# Use a different logger for distributed setups
# config.logger = SyslogLogger.new

# Full error reports are disabled and caching is turned on
config.action_controller.consider_all_requests_local = false
config.action_controller.perform_caching             = true
config.action_view.cache_template_loading            = true

#--- asset host
# Enable serving of images, stylesheets, and javascripts from an asset server
ActionController::Base.asset_host = Proc.new {|source, request|
  if request.ssl?
    "#{request.protocol}a#{source.hash % 5}.#{ActionMailer::Base.default_url_options[:host] || "staging.luleka.net"}"
  else
    "#{request.protocol}a#{source.hash % 5}.#{ActionMailer::Base.default_url_options[:host] || "staging.luleka.net"}"
  end
}

#--- session sharing between subdomains
config.action_controller.session[:domain]  = '.staging.luleka.net'

#--- action mailer
require 'smtp_tls'
config.action_mailer.raise_delivery_errors = false
config.action_mailer.default_url_options = {:host => 'staging.luleka.net'}
config.action_mailer.delivery_method = :smtp # :sendmail
config.action_mailer.smtp_settings = {
  :address => "127.0.0.1",
  :port => 25,
  :domain => "www.staging.luleka.net"
}
config.action_mailer.default_charset = "utf-8"
config.action_mailer.perform_deliveries = true

config.to_prepare do
end

# setup active merchant gateway
config.after_initialize do 
  #--- mail
  require_dependency 'smtp_tls'
  Notifier.site_url       = 'luleka.com'
  
  Notifier.service_email  = '"Service | luleka.com" <service@luleka.com>'
  Notifier.admin_email    = '"Admin | luleka.com" <admin@luleka.com>'
  Notifier.noreply_email  = '"Noreply | luleka.com" <noreply@luleka.com>'
  Notifier.info_email     = '"Info | luleka.com" <info@luleka.com>'
  Notifier.support_email  = '"Support | luleka.com" <support@luleka.com>'
  Notifier.error_email    = '"Error | luleka.com" <error@luleka.com>'

  #--- merchant
  ActiveMerchant::Billing::Base.mode = :production
  CreditCardPayment.gateway = :paypal_gateway
  PaypalDepositAccount.gateway = :paypal_gateway
  
  #--- geokit
  GeoKit::default_units = :kms
  GeoKit::default_formula = :sphere
  GeoKit::Geocoders::timeout = 3

  GeoKit::Geocoders::maxmind_ip = 'NOE3u6K7vuWq'
  GeoKit::Geocoders::yahoo      = '1DKmXdHV34GtDujSuUZVhOQLOVY2a8zZLwR8BhtmCTsDDSwYSKnwEbEXnmz9SspGiqI-'
  GeoKit::Geocoders::google     = 'ABQIAAAA3jIP-UwrX5YmhumykFl2_RTJQa0g3IQ9GZqIMmInSLzwtGDKaBSG8ZDHOTJL2qdtpxep7fkFAsL6Qw'

  GeoKit::Geocoders::geocoder_us = false 
  GeoKit::Geocoders::geocoder_ca = false

  GeoKit::Geocoders::provider_order = [:google, :yahoo, :us]
  GeoKit::Geocoders::ip_provider_order = [:maxmind_ip, :ip]

  #--- STI dependencies
  # http://dev.rubyonrails.org/ticket/11269
  Utility.require_sti_dependencies
  
  #--- pre launch
  Utility.pre_launch = false
end
