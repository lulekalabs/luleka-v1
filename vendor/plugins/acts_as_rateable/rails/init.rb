require 'acts_as_rateable'

ActiveRecord::Base.send :include, Acts::Rateable
ActionView::Base.send :include, Acts::Rateable::Helper
RAILS_DEFAULT_LOGGER.info "** acts_as_rateable: plugin initialized properly."