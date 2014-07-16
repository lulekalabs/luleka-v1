require File.join(File.dirname(__FILE__), '../../../../test', 'test_helper.rb')
module Acts #:nodoc:
  module Voteable #:nodoc:
    
    vote_class = <<-ADDRESS
      class Vote < ActiveRecord::Base
        belongs_to :voteable, :polymorphic => true
        belongs_to :voter, :foreign_key => :voter_id, :class_name => 'Voter'
      end
    ADDRESS
    eval vote_class, TOPLEVEL_BINDING
    
    class Voter < ActiveRecord::Base #:nodoc:
      acts_as_voter
    end
    
    class VotedThing < ActiveRecord::Base #:nodoc:
      acts_as_voteable
    end
  
    class VotedThingWithCache < ActiveRecord::Base #:nodoc:
      acts_as_voteable
    end

    class ActsAsVoteableTest < Test::Unit::TestCase #:nodoc:
        def setup  
          ActiveRecord::Schema.define do
            # create_table :votes, :force => true do |t|
            #   t.column :voter_id, :integer
            #   t.column :voteable_id, :integer, :null => false
            #   t.column :voteable_type, :string, :null => false
            #   t.column :vote, :integer, :null => false
            # end

            create_table :voters, :force => true do |t|
              t.column :name, :string
            end
        
            create_table :voted_things, :force => true do |t|
              t.column :name, :string
            end
          
            create_table :voted_thing_with_caches, :force => true do |t|
              t.column :name, :string
              t.column :votes_count, :integer, :default => 0, :null => false
              t.column :up_votes_count, :integer, :default => 0, :null => false
              t.column :down_votes_count, :integer, :default => 0, :null => false
              t.column :votes_sum, :integer, :default => 0, :null => false
            end
          end
          
          @voter = Voter.create(:name => "A test voter")
        end
    
        def teardown
          Vote.delete_all
          Voter.delete_all
          VotedThing.delete_all
          VotedThingWithCache.delete_all
        end
    
        def test_has_voteable_included
          assert VotedThing.singleton_methods.include?('acts_as_voteable'),
            "acts_as_voteable not included in ActiveRecord class"
        end

        def test_simple_vote
          thing = VotedThing.create(:name => "A voted thing")
          assert thing.vote(1)
          assert_equal 1, thing.votes_sum
          assert_equal 1, thing.votes_count
          assert_equal 1, thing.up_votes_count
          assert_equal 0, thing.down_votes_count
        end

        def test_complex_vote
          voter_a = Voter.create(:name => "Voter A")
          voter_b = Voter.create(:name => "Voter B")
          voter_c = Voter.create(:name => "Voter C")
          thing = VotedThing.create(:name => "A voted thing")
          assert thing.vote_up(voter_a)
          assert thing.vote_down(voter_b)
          assert thing.vote_up(voter_c)
          assert_equal 1, thing.votes_sum
          assert_equal 3, thing.votes_count
          assert_equal 2, thing.up_votes_count
          assert_equal 1, thing.down_votes_count
        end

        def test_should_be_voted?
          thing = VotedThing.create(:name => "A voted thing")
          assert thing.vote_down
          assert thing.voted?, "should be voted"
        end

        def test_should_not_be_voted?
          thing = VotedThing.create(:name => "A voted thing")
          assert !thing.voted?, "should not be voted"
        end
        
        def test_vote_up_with_voter
          thing = VotedThing.create(:name => "A voted thing")
          thing.vote_up(@voter)
          assert_equal 1, thing.votes_sum
          assert_equal 1, thing.votes_count
          assert_equal 1, thing.up_votes_count
          assert_equal 0, thing.down_votes_count
        end
        
        def test_undo_vote
          thing = VotedThing.create(:name => "voted thing")
          assert vote = thing.vote_down(@voter)
          assert_equal -1, thing.votes_sum
          assert_equal vote, thing.undo_vote(@voter)
          thing = VotedThing.find(thing.id)
          assert_equal 0, thing.votes_sum
          assert_equal 0, thing.votes_count
          assert_equal 0, thing.up_votes_count
          assert_equal 0, thing.down_votes_count
        end

        def test_simple_vote_with_cache
          thing = VotedThingWithCache.create(:name => "A voted thing")
          assert thing.vote(1)
          assert_equal 1, thing.votes_sum
          assert_equal 1, thing.votes_count
          assert_equal 1, thing.up_votes_count
          assert_equal 0, thing.down_votes_count

          thing = VotedThingWithCache.find(thing.id)
          
          assert_equal 1, thing[:votes_sum]
          assert_equal 1, thing[:votes_count]
          assert_equal 1, thing[:up_votes_count]
          assert_equal 0, thing[:down_votes_count]
        end

        def test_complex_vote_with_cache
          voter_a = Voter.create(:name => "Voter A")
          voter_b = Voter.create(:name => "Voter B")
          voter_c = Voter.create(:name => "Voter C")
          thing = VotedThingWithCache.create(:name => "A voted thing")
          assert thing.vote_up(voter_a)
          assert thing.vote_down(voter_b)
          assert thing.vote_up(voter_c)
          assert_equal 1, thing.votes_sum
          assert_equal 3, thing.votes_count
          assert_equal 2, thing.up_votes_count
          assert_equal 1, thing.down_votes_count
        end
        
        def test_votes_column
          assert_equal false, VotedThing.votes_count_column?
          assert_equal false, VotedThing.up_votes_count_column?
          assert_equal false, VotedThing.down_votes_count_column?
          assert_equal false, VotedThing.votes_sum_column?

          assert_equal false, VotedThing.new.votes_count_column?
          assert_equal false, VotedThing.new.up_votes_count_column?
          assert_equal false, VotedThing.new.down_votes_count_column?
          assert_equal false, VotedThing.new.votes_sum_column?

          assert_equal true, VotedThingWithCache.votes_count_column?
          assert_equal true, VotedThingWithCache.up_votes_count_column?
          assert_equal true, VotedThingWithCache.down_votes_count_column?
          assert_equal true, VotedThingWithCache.votes_sum_column?

          assert_equal true, VotedThingWithCache.new.votes_count_column?
          assert_equal true, VotedThingWithCache.new.up_votes_count_column?
          assert_equal true, VotedThingWithCache.new.down_votes_count_column?
          assert_equal true, VotedThingWithCache.new.votes_sum_column?
        end

    end
  end
end
