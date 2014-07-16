# ActsAsVoteable
#
# In the voteable schema the following columns can be used to cache votes
#
#   :votes_sum :integer
#   :votes_count, :integer
#   :up_votes_count, :integer
#   :down_votes_count :integer
#
module Acts #:nodoc:
  module Voteable #:nodoc:

    def self.included(base)
      base.extend ClassMethods
    end

    module ClassMethods

      def acts_as_voteable(options={})
        options = options_for_voteable(options)

        has_many :votes, :as => :voteable, :dependent => :destroy
        if options[:voter_class_name]
          has_many options[:voter_class_name].tableize.to_sym, 
          :through => :votes, 
          :foreign_key => :voter_id,
          :source => options[:voter_class_name],
          :source_type => options[:voter_class_name]
        end
        
#        after_create :update_voteable_cache
        
        include Acts::Voteable::InstanceMethods
        extend Acts::Voteable::SingletonMethods
      end

      private

      def options_for_voteable(options={})
        {:voter_class_name => 'Person'}.merge(options)
      end
    
    end
    
    # This module contains class methods
    module SingletonMethods

      def votes_count_column?
        table_exists? ? columns.to_a.map {|a| a.name.to_sym}.include?(:votes_count) : false
      end

      def up_votes_count_column?
        table_exists? ? columns.to_a.map {|a| a.name.to_sym}.include?(:up_votes_count) : false
      end

      def down_votes_count_column?
        table_exists? ? columns.to_a.map {|a| a.name.to_sym}.include?(:down_votes_count) : false
      end

      def votes_sum_column?
        table_exists? ? columns.to_a.map {|a| a.name.to_sym}.include?(:votes_sum) : false
      end
      
      private
      
      def find_votes_cast_by_voter(a_voter)
        voteable = ActiveRecord::Base.send(:class_name_of_active_record_descendant, self).to_s
        votes.find(
          :all,
          :conditions => ["voter_id = ?", a_voter.id],
          :order => "created_at DESC"
        )
      end
    end
    
    # This module contains instance methods
    module InstanceMethods
      
      def votes_count_column?
        self.class.votes_count_column?
      end
      
      def up_votes_count_column?
        self.class.up_votes_count_column?
      end

      def down_votes_count_column?
        self.class.down_votes_count_column?
      end

      def votes_sum_column?
        self.class.votes_sum_column?
      end
      
      # cast a vote, a voter can only vote once
      #
      # e.g.
      #
      #   @post.vote(1)
      #   @post.vote(-1, @person)
      #
      def vote(value, voter=nil, options={})
        vote = nil
        if self.new_record?
          vote = self.votes.build({:vote => value, :voter => voter}.merge(options))
          @update_voteable_cache = true
        else
          vote = self.votes.create({:vote => value, :voter => voter}.merge(options))
          update_voteable_cache(true)
          update_voter_cache(voter, true)
        end
        vote
      end
      
      # vote up = +1 vote
      def vote_up(voter=nil)
        self.vote(1, voter)
      end

      # vote down = -1 vote
      def vote_down(voter=nil)
        self.vote(-1, voter)
      end

      # undos the vote, returns the destroyed vote or nil
      def undo_vote(voter)
        if voter
          if vote = voted_by?(voter)
            vote.destroy
            update_voteable_cache(true)
            update_voter_cache(voter, true)
            self.votes.reload
            vote
          end
        end
      end
      
      # Has the votable already been voted for and/or was it voted by this voter?
      def voted?(voter=nil)
        if voter
          return self.votes.find(:first, :conditions => {:voter_id => voter.id},
            :order => "votes.created_at DESC") unless voter.new_record?
        else
          !self.votes.empty?
        end
      end
      
      # returns the vote if the voter has voted before, otherwise, false
      def voted_by?(voter)
        self.voted?(voter)
      end

      def votes_sum
        self.votes_sum_cache || self.votes_sum_cache = self.calculate_votes_sum
      end
      
      def votes_count
        self.votes_count_cache || self.votes_count_cache = self.calculate_votes_count
      end

      def up_votes_count
        self.up_votes_count_cache || self.up_votes_count_cache = self.calculate_up_votes_count
      end

      def down_votes_count
        self.down_votes_count_cache || self.down_votes_count_cache = self.calculate_down_votes_count
      end
      
      # called after create to update cached columns
      def update_voteable_cache(sweep_cache=@update_voteable_cache)
        if sweep_cache
          @update_voteable_cache = false
          # sweep cache
          @votes_sum_cache = false
          @votes_count_cache = false
          @up_votes_count_cache = false
          @down_votes_count_cache = false
        end
        # update attributes
        ua = voteable_cache_attributes
        unless ua.empty?
          self.class.transaction do
            Vote.transaction do  
              self.lock_self_and_votes!
              self.update_attributes(ua)
            end
          end
        end
      end
      
      # override in voteable model
      def update_voter_cache(voter, sweep_cache=false)
        # e.g. voter.update_received_votes_cache if voter
      end

      protected
      
      # get vote sum or vote sum cache
      def votes_sum_cache
        @votes_sum_cache || @votes_sum_cache = self.votes_sum_column? ? self[:votes_sum] : false
      end

      # set vote sum and cache
      def votes_sum_cache=(sum)
        if self.votes_sum_column?
          self[:votes_sum] = @votes_sum_cache = sum
        else
          @votes_sum_cache = sum
        end
      end

      # database calculation
      def calculate_votes_sum
        self.votes.sum(:vote).to_i
      end

      # get votes count and votes count cache
      def votes_count_cache
        @votes_count_cache || @votes_count_cache = self.votes_count_column? ? self[:votes_count] : false
      end

      # set votes count and votes count cache
      def votes_count_cache=(count)
        if self.votes_count_column?
          self[:votes_count] = @votes_count_cache = count
        else
          @votes_count_cache = count
        end
      end

      # goes out to the database and calculates
      def calculate_votes_count
        self.votes.count
      end

      # get vote ups count and cache
      def up_votes_count_cache
        @up_votes_count_cache || @up_votes_count_cache = self.up_votes_count_column? ? self[:up_votes_count] : false
      end

      # set vote ups count and cache
      def up_votes_count_cache=(count)
        if self.up_votes_count_column?
          self[:up_votes_count] = @up_votes_count_cache = count
        else
          @up_votes_count_cache = count
        end
      end

      # goes out to the database and calculates
      def calculate_up_votes_count
        self.votes.count(:conditions => ["votes.vote > 0"]).to_i
      end

      # get vote downs count and cache
      def down_votes_count_cache
        @down_votes_count_cache || @down_votes_count_cache = self.down_votes_count_column? ? self[:down_votes_count] : false
      end

      # set vote downs count and cache
      def down_votes_count_cache=(count)
        if self.down_votes_count_column?
          self[:down_votes_count] = @down_votes_count_cache = count
        else
          @down_votes_count_cache = count
        end
      end

      # goes out to the database and calculates
      def calculate_down_votes_count
        self.votes.count(:conditions => ["votes.vote < 0"]).to_i
      end
      
      # returns the attributes of cache values that need to be updated
      def voteable_cache_attributes
        attributes = {}
        attributes[:votes_sum] = self.votes_sum_cache = self.calculate_votes_sum if self.votes_sum_column?
        attributes[:votes_count] = self.votes_count_cache = self.calculate_votes_count if self.votes_count_column?
        attributes[:up_votes_count] = self.up_votes_count_cache = self.calculate_up_votes_count if self.up_votes_count_column?
        attributes[:down_votes_count] = self.down_votes_count_cache = self.calculate_down_votes_count if self.down_votes_count_column?
        attributes
      end
      
      # pessimistically locks all votes
      def lock_self_and_votes!
        self.lock!
        self.votes(:lock => true)
      end
      
    end
  end
end
