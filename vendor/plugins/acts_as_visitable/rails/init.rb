require 'acts_as_visitable'

ActiveRecord::Base.send(:include, Acts::Visitable)

RAILS_DEFAULT_LOGGER.info "** acts_as_visitable: plugin initialized properly."