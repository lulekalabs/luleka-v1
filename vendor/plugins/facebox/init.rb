require 'facebox_helper'

ActionView::Base.send(:include, FaceboxHelper)

RAILS_DEFAULT_LOGGER.info "** facebox: plugin initialized properly."
