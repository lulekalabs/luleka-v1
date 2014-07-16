class Bid < ActiveRecord::Base
  # Associations
  belongs_to :bidder, :foreign_key => :bidder_id, :class_name => 'Person'
  belongs_to :biddable, :polymorphic => true
  
  money :bid, :cents => :bid_cents
  money :current_bid, :cents => :current_bid_cents

end
