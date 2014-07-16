# Takes care of each vote
class Vote < ActiveRecord::Base

  #--- associations
  belongs_to :voteable, :polymorphic => true
  belongs_to :voter, :foreign_key => :voter_id, :class_name => 'Person'

end
