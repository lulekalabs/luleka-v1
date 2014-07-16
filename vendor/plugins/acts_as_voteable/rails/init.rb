require 'acts_as_voteable'

ActiveRecord::Base.send :include, Acts::Voteable

RAILS_DEFAULT_LOGGER.info "** acts_as_voteable: plugin initialized properly."