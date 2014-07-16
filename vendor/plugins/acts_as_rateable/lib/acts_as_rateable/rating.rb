class Rating < ActiveRecord::Base
  belongs_to :rateable, :polymorphic => true
  belongs_to :rater, :foreign_key => :rater_id, :class_name => 'Person'
end