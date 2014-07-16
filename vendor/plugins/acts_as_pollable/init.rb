require 'acts_as_pollable'
require 'acts_as_poller'

ActiveRecord::Base.class_eval do
  include Probono::Acts::Pollable
end


