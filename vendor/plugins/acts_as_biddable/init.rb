# Include hook code here
require 'acts_as_biddable'
require 'acts_as_bidder'

ActiveRecord::Base.class_eval do
  include Probono::Acts::Biddable
  include Probono::Acts::Bidder
end
