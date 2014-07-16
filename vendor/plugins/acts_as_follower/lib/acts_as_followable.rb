require File.dirname(__FILE__) + '/follower_lib'

module ActiveRecord #:nodoc:
  module Acts #:nodoc:
    module Followable
      
      def self.included(base)
        base.extend ClassMethods
        base.class_eval do
          include FollowerLib
        end
      end
      
      module ClassMethods
        def acts_as_followable
          has_many :follows, :as => :followable, :dependent => :destroy
          has_many :followers,
            :class_name => 'Person',
            :through => :follows,
            :foreign_key => :follower_id,
            :conditions => ["follows.blocked = ?", false]
          
          include ActiveRecord::Acts::Followable::InstanceMethods
          extend ActiveRecord::Acts::Followable::SingletonMethods
        end
      end

      module SingletonMethods

        # returns true if a followers_count column exists in the schema
        def followers_count_column?
          columns.to_a.map {|a| a.name.to_sym}.include?(:followers_count)
        end
        
      end
      
      # This module contains instance methods
      module InstanceMethods

        def followers_count_column?
          self.class.followers_count_column?
        end
        
        # Returns the number of followers a record has.
        def followers_count(sweep_cache=false)
          if followers_count_column?
            @followers_count_cache ||= self[:followers_count] && !sweep_cache ? self[:followers_count] : self.followers.count
          else
            @followers_count_cache ||= self.followers.count
          end
        end

        # updates the followers count cache
        def update_followers_count
          if self.class.followers_count_column?
            self.update_attribute(:followers_count, 
              self[:followers_count] = followers_count(true))
            self[:followers_count]
          end
        end

=begin        
        # if "follower" is polymorphic in follows.rb, the below function is the only way to retrieve followers
        # however, that's not necessary as the followers will always be of one type, e.g. Person
        def followers
          # Follow.unblocked.find(:all, :include => [:follower], :conditions => ["followable_id = ? AND followable_type = ?", 
          #    self.id, parent_class_name(self)]).collect {|f| f.follower}
              
          Follow.find(:all, :conditions => ["blocked = ? AND followable_id = ? AND followable_type = ?", 
            false, self.id, parent_class_name(self)]).collect {|f| f.follower}
        end
=end        
        
        def follower_ids_by_type(follower_type, *args)
          Follow.unblocked.for_followable(self).by_follower_type(follower_type).find(:all, :select => :follower_id, :conditions => {:blocked => false}, *args).collect(&:follower_id)
        end
        
        def follower_count_by_type(follower_type)
          Follow.unblocked.for_followable(self).by_follower_type(follower_type).count
        end
        
        # Returns true if the current instance is followed by the passed record.
        def followed_by?(follower)
          Follow.unblocked.find(:first, :conditions => ["followable_id = ? AND followable_type = ? AND follower_id = ? AND follower_type = ?", self.id, parent_class_name(self), follower.id, parent_class_name(follower)]) ? true : false
        end
        
        def block_follower(follower, block_follower = true)
          return unless follower.follows.for_followable(self).first
          follow = self.follows.for_followable(follower).first
          follower.follows.for_followable(self).first.delete if follower.follows.for_followable(self).first
          if follow
            follow.update_attribute(:blocked, block_follower)
          else
            self.follows.create(:followable => follower, :blocked => true)
          end
        end

        def unblock_follower(follower)
          self.follows.for_followable(follower).first.delete
        end
        
        # Retrieves the parent class name if using STI.
        def parent_class_name(obj)
          if obj.class.superclass != ActiveRecord::Base
            return obj.class.superclass.name
          end

          return obj.class.name
        end
      end
      
    end
  end
end
