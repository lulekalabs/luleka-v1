class Counting < ActiveRecord::Base
  # Associations
  belongs_to :outcome
  belongs_to :poll
  belongs_to :participant, :foreign_key => :participant_id
end
