# extends flag model with validations from can_flag plugin
Flag.class_eval do

  #--- assocations
  belongs_to :user, :foreign_key => :user_id, :class_name => "User"
  belongs_to :flaggable_user, :foreign_key => :user_id, :class_name => "User"

  #--- validations
  validates_presence_of :description, :reason

  # hack to sure active scaffold flags work
  class Flaggable < ActiveRecord::Base
  end

end