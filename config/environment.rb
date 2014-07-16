# Be sure to restart your server when you modify this file

# Specifies gem version of Rails to use when vendor/rails is not present
RAILS_GEM_VERSION = '2.3.4' unless defined? RAILS_GEM_VERSION

# Bootstrap the Rails environment, frameworks, and default configuration
require 'thread'
require File.join(File.dirname(__FILE__), 'boot')

# added from https://rails.lighthouseapp.com/projects/8994/tickets/4026
if Gem::VERSION >= "1.3.6"
  module Rails
    class GemDependency
      def requirement
        r = super
        (r == Gem::Requirement.default) ? nil : r
      end
    end
  end
end

Rails::Initializer.run do |config|
  # Settings in config/environments/* take precedence over those specified here.
  # Application configuration should go into files in config/initializers
  # -- all .rb files in that directory are automatically loaded.

  # Add additional load paths for your own custom dirs
  config.load_paths += %W(#{RAILS_ROOT}/app/sweepers #{RAILS_ROOT}/lib/jobs)

  # Specify gems that this application depends on and have them installed with rake gems:install
  config.gem "money", :version => "=1.7.1"
  config.gem "tzinfo", :version => ">=0.3.17"
  config.gem "uuidtools", :version => ">=2.0.0"
  config.gem "rmagick", :lib => "RMagick2"
  config.gem "pdf-writer", :lib => "pdf/writer", :version => ">1.1.7"
  config.gem "aws-s3", :lib => "aws/s3", :version => ">=0.6.2"
  config.gem "right_http_connection", :version => ">=1.2.4"
  config.gem "right_aws", :version => ">=1.10.0"
  config.gem "hpricot", :version => ">=0.6.164"
  config.gem "babosa", :version => ">= 0.2.0"
  config.gem "facebooker2"
  config.gem "oauth"
  config.gem "faraday"
  config.gem "twitter"
  
  # Only load the plugins named here, in the order given (default is alphabetical).
  # :all can be used as a placeholder for all plugins not explicitly named
  config.plugins = [:i18n_backend_database, :globalize2, :globalize_bridge, :all]

  # Your secret key for verifying cookie session data integrity.
  # If you change this key, all old sessions will become invalid!
  # Make sure the secret is at least 30 characters and all random, 
  # no regular words or you'll be exposed to dictionary attacks.
  config.action_controller.session = {
    :session_key => '_luleka_session',
    :secret      => '81587f48245f25c5915236dc57a4c5089281b110'
  }

  # Use the database for sessions instead of the file system
  # (create the session table with 'rake db:sessions:create')
  config.action_controller.session_store = :active_record_store
  # config.action_controller.session_store = :cookie_store

  # Skip frameworks you're not going to use. To use Rails without a database,
  # you must remove the Active Record framework.
  # config.frameworks -= [ :active_record, :active_resource, :action_mailer ]

  # Activate observers that should always be running
  # config.active_record.observers = :cacher, :garbage_collector, :forum_observer

  # Make Active Record use UTC-base instead of local time
  config.active_record.default_timezone = :utc

  # Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
  # Run "rake -D time" for a list of tasks for finding time zone names.
  config.time_zone = 'UTC'
  
  # ActiveRecord optimistic locking
  # http://api.rubyonrails.com/classes/ActiveRecord/Locking/Optimistic/ClassMethods.html
  # turned off as orders and invoice would throw error due to ?bug? lock_version
  config.active_record.lock_optimistically = false
  
  # caching config
  config.action_controller.page_cache_directory = File.join(RAILS_ROOT, '/public/cache')
  config.action_controller.cache_store = :file_store, File.join(RAILS_ROOT, '/public/cache/fragments')
  
end