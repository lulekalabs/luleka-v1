
module FriendshipPlugin
  module UserExtensions
 
    def self.included( recipient )
      recipient.extend( ClassMethods )
    end
    
    module ClassMethods
      def has_friendships
        has_many :friendships,
          :foreign_key =>       'person_id',
          :class_name =>        'Friendship'
        has_many :befriendships,
          :foreign_key =>       'friend_id',
          :class_name =>        'Friendship'
        has_many :friends,
          :through =>     :friendships,
          :source =>      :befriendshipped,
          :conditions =>  "accepted_at IS NOT NULL" do
            
          # association extension
          def shared_with(person_b)
            f1 = "SELECT DISTINCT friend_id FROM friendships f1 WHERE f1.person_id = #{proxy_owner.id}"
            f2 = "SELECT DISTINCT friend_id FROM friendships f2 WHERE f2.person_id = #{person_b.id}"
            where_clause = "people.id IN (#{f1}) AND people.id IN (#{f2})"
            find :all, :conditions => where_clause
          end

          def count_shared_with(person_b)
            f1 = "SELECT DISTINCT friend_id FROM friendships f1 WHERE f1.person_id = #{proxy_owner.id}"
            f2 = "SELECT DISTINCT friend_id FROM friendships f2 WHERE f2.person_id = #{person_b.id}"
            where_clause = "people.id IN (#{f1}) AND people.id IN (#{f2})"
            count :conditions => where_clause
          end
        end
        
        has_many :befrienders,
          :through =>     :befriendships,
          :source =>      :friendshipped
        attr_protected :friend_ids
        attr_protected :befriender_ids
        
        include FriendshipPlugin::UserExtensions::InstanceMethods
        extend FriendshipPlugin::UserExtensions::SingletonMethods
      end
    end
    
    module SingletonMethods

      # returns true if a followers_count column exists in the schema
      def friends_count_column?
        columns.to_a.map {|a| a.name.to_sym}.include?(:friends_count)
      end
      
    end
    
    module InstanceMethods

      def friends_count_column?
        self.class.friends_count_column?
      end
      
      # Returns the number of friends we have
      def friends_count(sweep_cache=false)
        if friends_count_column?
          @friends_count_cache = nil if sweep_cache
          @friends_count_cache ||= self[:friends_count] && !sweep_cache ? self[:friends_count] : self.friends.count
        else
          @friends_count_cache ||= self.friends.count
        end
      end
      
      # updates the friends count cache
      def update_friends_count
        if self.class.friends_count_column?
          self.update_attribute(:friends_count, 
            self[:friends_count] = friends_count(true))
          self[:friends_count]
        end
      end

      # Finds friendship, pending or accepted, between self and another person object
      def friendships_with(person_obj)
        Friendship.find(:all, friendships_with_finder_attributes(person_obj))
      end
      
      # Counts friendship, pending or accepted, between self and another person object
      def friendships_count_with(person_obj)
        Friendship.count(friendships_with_finder_attributes(person_obj))
      end
      
      # finds common friends between this and the given contact
      def shared_friends_with(person_obj, options={})
        Person.find(:all, shared_friends_with_finder_attributes(person_obj, options))
      end

      # same as dito but count
      def shared_friends_count_with(person_obj, options={})
        Person.count(shared_friends_with_finder_attributes(person_obj, options))
      end

      # Provides a quick way to see if a person is a friend of another
      def is_friends_with?( person_obj )
        self.friends.include?( person_obj )
      end
            
      # Add a person as requesting a friendship
      def request_friendship_of( person_obj )
        Friendship.create!(:friendshipped => self, :befriendshipped => person_obj)
      end
      
      # All pending friendship requests
      def pending_friendships
        Friendship.find(:all, :conditions => ["friend_id = ? AND accepted_at IS NULL", id])
      end

      # Couunts pending friendship requests
      def pending_friendships_count
        Friendship.count(:conditions => ["friend_id = ? AND accepted_at IS NULL", id])
      end
      
      # Accept a specific pending friendship, creating a 2 way friendship
      def accept_friendship( friendship_obj )
        friendship_obj.update_attribute(:accepted_at, Time.now.utc)
        Friendship.create!( :befriendshipped => friendship_obj.friendshipped,
                            :friendshipped   => self, 
                            :accepted_at => Time.now.utc)
      end      

      def accept_friendship_of(person_obj)
        self.friendships_with( person_obj ).each { |friendship| self.accept_friendship(friendship) }
      end
      
      # Deny/Delete a specific pending friendship
      def deny_friendship(friendship_obj)
        friendship_obj.destroy        
      end
      
      # Directly creates a 2 way friendship without intervention
      def is_friends_with(person_obj)
        unless self.is_friends_with? person_obj
          Friendship.create( :befriendshipped => self, 
                             :friendshipped   => person_obj, 
                             :accepted_at     => Time.now.utc )
          Friendship.create( :befriendshipped => person_obj, 
                             :friendshipped   => self,
                             :accepted_at     => Time.now.utc )
        else
          self.friendships_with(person_obj).first
        end
      end
      
      # Directly remove both sides of any friendship without intervention
      def is_not_friends_with( person_obj )
        self.friendships_with(person_obj).each do |friendship|
          friendship.destroy
        end
      end
      
      protected
      
      def friendships_with_finder_attributes(person_obj)
        { :conditions => [
            '(person_id = ? AND friend_id = ?) OR (person_id = ? AND friend_id = ?)', 
            self.id,
            person_obj.id,
            person_obj.id,
            self.id
        ]}
      end
      
      def shared_friends_with_finder_attributes(person_obj, options={})
        f1 = "SELECT DISTINCT friend_id FROM friendships f1 WHERE f1.person_id = #{self.id}"
        f2 = "SELECT DISTINCT friend_id FROM friendships f2 WHERE f2.person_id = #{person_obj.id}"
        { :conditions => "id IN (#{f1}) AND id IN (#{f2})"
        }.merge(options)
      end
      
    end  
  end  
end
