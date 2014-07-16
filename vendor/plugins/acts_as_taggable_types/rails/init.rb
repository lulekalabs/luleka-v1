require 'acts_as_taggable_types'

ActiveRecord::Base.send(:include, ActiveRecord::Acts::TaggableTypes)
ActionView::Base.send(:include, ActionView::Acts::TaggableTypes)

RAILS_DEFAULT_LOGGER.info "** acts_as_taggable_types: plugin initialized properly."

