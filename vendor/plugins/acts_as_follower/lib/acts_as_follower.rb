require File.dirname(__FILE__) + '/follower_lib'

module ActiveRecord #:nodoc:
  module Acts #:nodoc:
    module Follower
      
      def self.included(base)
        base.extend ClassMethods
        base.class_eval do
          include FollowerLib
        end
      end
      
      module ClassMethods
        def acts_as_follower
          has_many :follows, :as => :follower, :dependent => :destroy
          include ActiveRecord::Acts::Follower::InstanceMethods
        end
      end
      
      # This module contains instance methods
      module InstanceMethods
        
        # Returns true if this instance is following the object passed as an argument.
        def following?(followable)
          Follow.unblocked.exists?(follower_and_followable_conditions(self, followable))
        end
        
        def blocks?(followable)
          self.follows.for_followable(followable).exists?(:blocked => true)
        end
        
        # Returns the number of objects this instance is following.
        def follow_count
          Follow.unblocked.count(:all, :conditions => ["follower_id = ? AND follower_type = ?", self.id, parent_class_name(self)])
        end
        
        # Creates a new follow record for this instance to follow the passed object.
        # Does not allow duplicate records to be created.
        def follow(followable)
          follow = get_follow(followable)
          unless follow
            Follow.create(:followable => followable, :follower => self)
          end
        end
        
        # Deletes the follow record if it exists.
        def stop_following(followable)
          follow = get_follow(followable)
          if follow
            follow.destroy
          end
        end
        
        # TODO: Remove from public API.
        # Returns the follow records related to this instance by type.
        def follows_by_type(followable_type)
          followable_type.constantize.find(follow_ids_by_type(followable_type))
        end
        
        def followable_ids_by_type(followable_type, *args)
          Follow.unblocked.for_follower(self).by_followable_type(followable_type).find(:all, :select => :followable_id, :conditions => {:blocked => false}, *args).collect(&:followable_id)
        end

        def followable_count_by_type(followable_type)
          Follow.unblocked.for_follower(self).by_followable_type(followable_type).count
        end

        # TODO: Remove from public API.
        # Returns the follow records related to this instance by type.
        def all_follows
          Follow.unblocked.find(:all, :include => [:followable], :conditions => ["follower_id = ? AND follower_type = ?", self.id, parent_class_name(self)])
        end
        
        # Returns the actual records which this instance is following.
        def all_following
          all_follows.map { |f| f.followable }
        end
        
        # Returns the actual records of a particular type which this record is following.
        def following_by_type(followable_type)
          #klass = eval(followable_type) # be careful with this.
          #klass.find(:all, :joins => :follows, :conditions => ['follower_id = ? AND follower_type = ?', self.id, parent_class_name(self)])
          follows_by_type(followable_type).map { |f| f.followable }
        end
        
        # Allows magic names on following_by_type
        # e.g. following_users == following_by_type('User')
        def method_missing(m, *args)
          if m.to_s[/following_(.+)/]
            #following_by_type(parent_class_name($1).classify)
            following_by_type($1.singularize.classify)
          else
            super
          end
        end
        
        private
        
        # Returns a follow record for the current instance and followable object.
        def get_follow(followable)
#          Follow.find(:first, :conditions => ["follower_id = ? AND follower_type = ? AND followable_id = ? AND followable_type = ?", self.id, parent_class_name(self), followable.id, parent_class_name(followable)])

          Follow.find(:first, :conditions => follower_and_followable_conditions(self, followable))
        end

      end
      
    end
  end
end
