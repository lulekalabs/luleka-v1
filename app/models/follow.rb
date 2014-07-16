# generated class from acts_as_follower
# replacing all named_scope (Rails 2.1.x) with named_scope (plugin)
class Follow < ActiveRecord::Base
  
  #--- associations
  # NOTE: Follows belong to the "followable" interface, and also to followers
  belongs_to :followable, :polymorphic => true
  belongs_to :follower,   :foreign_key => :follower_id, :class_name => 'Person'

  #--- has finder
  named_scope :for_follower, 
    lambda {|*args| {:conditions => ["follower_id = ? AND follower_type = ?", args.first.id, args.first.type.name]}}
  named_scope :for_followable, 
    lambda {|*args| {:conditions => ["followable_id = ? AND followable_type = ?", args.first.id, args.first.type.name]}}
  named_scope :recent, 
    lambda {|*args| {:conditions => ["created_at > ?", (args.first || 2.weeks.ago).to_s(:db)]}}
  named_scope :descending, :order => "created_at DESC"
  named_scope :unblocked, :conditions => {:blocked => false}
  
  # Returns the follow records related to this instance by type.
  named_scope :by_followable_type, lambda {|followable_type|
    {:conditions => {:followable_type => followable_type}}}
  named_scope :by_follower_type, lambda { |follower_type|
    {:conditions => {:follower_type => follower_type}}}
    
  #--- callback
  after_create :update_followable_count
  after_destroy :update_followable_count
    
  #--- instance methods
  
  # add followable count in association as :counter_cache for :polymorphic is broken
  def update_followable_count
    if self.followable && self.followable.class.columns.to_a.map {|a| a.name.to_sym}.include?(:followers_count)
      self.followable.class.transaction do 
        self.followable.lock!
        self.followable.update_attribute(:followers_count, self.followable.followers.count)
      end
    end
  end
  
  
end
