require 'acts_as_addressable'
ActiveRecord::Base.send(:include, Acts::Addressable)

# Load locales for countries from +locale+ directory into Rails
I18n.load_path += Dir[File.join(File.dirname(__FILE__), '..', 'locale', '*.{rb,yml}')]

RAILS_DEFAULT_LOGGER.info "** acts_as_addressable: plugin initialized properly."
