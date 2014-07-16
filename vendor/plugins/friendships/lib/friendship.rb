# Defines the basis for a self-referential friendship system
class Friendship < ActiveRecord::Base
  
  #--- associations
  belongs_to :friendshipped,   :foreign_key => 'person_id', :class_name => 'Person'
  belongs_to :befriendshipped, :foreign_key => 'friend_id', :class_name => 'Person'

  #--- callback
  after_create :update_friends_count
  after_destroy :update_friends_count
    
  #--- instance methods
  
  # add friends count in association as :counter_cache for :polymorphic is broken
  def update_friends_count
    # friendshipped
    if self.friendshipped && self.friendshipped.class.columns.to_a.map {|a| a.name.to_sym}.include?(:friends_count)
      self.friendshipped.class.transaction do 
        self.friendshipped.lock!
        self.friendshipped.update_attribute(:friends_count, self.friendshipped.friends_count)
      end
    end
    
    # befriendshipped
    if self.befriendshipped && self.befriendshipped.class.columns.to_a.map {|a| a.name.to_sym}.include?(:friends_count)
      self.befriendshipped.class.transaction do 
        self.befriendshipped.lock!
        self.befriendshipped.update_attribute(:friends_count, self.befriendshipped.friends_count(true))
      end
    end
    
  end

end
