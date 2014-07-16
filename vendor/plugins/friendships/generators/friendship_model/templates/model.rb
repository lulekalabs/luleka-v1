# Defines the basis for a self-referential friendship system
class <%= class_name %> < ActiveRecord::Base
  belongs_to :friendshipped,   :foreign_key => "user_id",   :class_name => "User"
  belongs_to :befriendshipped, :foreign_key => "friend_id", :class_name => "User"

  # TODO: Add some friendly accessor methods here

end
