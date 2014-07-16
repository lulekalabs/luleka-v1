require File.join(File.dirname(__FILE__), '../../../../test', 'test_helper.rb')
module Acts #:nodoc:
  module Rateable #:nodoc:
    
    rating_class = <<-ADDRESS
      class Rating < ActiveRecord::Base
        belongs_to :rateable, :polymorphic => true
        belongs_to :rater, :foreign_key => :rater_id, :class_name => 'Rater'
      end
    ADDRESS
    eval rating_class, TOPLEVEL_BINDING
    
    class Rater < ActiveRecord::Base #:nodoc:
      acts_as_rater
    end
    
    class RatedThing < ActiveRecord::Base #:nodoc:
      acts_as_rateable :average => false
    end
  
    class AverageRatedThing < ActiveRecord::Base #:nodoc:
      acts_as_rateable :average => true
    end

    class AverageRatedThingWithCache < ActiveRecord::Base #:nodoc:
      acts_as_rateable :average => true
    end
    
    class ActsAsRateableTest < Test::Unit::TestCase #:nodoc:
        def setup  
          ActiveRecord::Schema.define do
            # create_table :ratings, :force => true do |t|
            #   t.column :rateable_id, :integer, :null => false
            #   t.column :rateable_type, :string, :null => false
            #   t.column :rating, :integer, :null => false
            #   t.column :total, :integer, :default => 0
            # end

            create_table :raters, :force => true do |t|
              t.column :name, :string
            end
        
            create_table :rated_things, :force => true do |t|
              t.column :name, :string
            end
          
            create_table :average_rated_things, :force => true do |t|
              t.column :name, :string
            end
            
            create_table :average_rated_thing_with_caches, :force => true do |t|
              t.column :name, :string
              t.column :ratings_average, :integer
              t.column :ratings_count, :integer, :default => 0, :null => false
            end
            
          end
          
          RatedThing.new(:name => "My Favorite", :rating => 5).save
          RatedThing.new(:name => "Tied For Second", :rating => 4).save
          RatedThing.new(:name => "Also Tied For Second", :rating => 4).save
          RatedThing.new(:name => "Take it or leave it", :rating => 3).save
          RatedThing.new(:name => "Don't like this thing very much", :rating => 2).save
          RatedThing.new(:name => "My Least Favorite", :rating => 1).save
        
        end
    
        def teardown
          Rating.delete_all
          Rater.delete_all
          RatedThing.delete_all
          AverageRatedThing.delete_all
          AverageRatedThingWithCache.delete_all
        end
    
        def test_has_rateable_included
          assert RatedThing.singleton_methods.include?('acts_as_rateable'),
            "acts_as_rateable not included in ActiveRecord class"
        end
      
        def test_has_association
          RatedThing.new(:name => "A Rated Thing", :rating => 5).save
          thing = RatedThing.find_by_name("A Rated Thing")
          assert (thing.rating == 5), "Rating should be 5, got #{thing.rating.inspect}"
          RatedThing.delete(thing.id)
        end
      
        def test_find_multiple_by_rating
          things = RatedThing.find_all_by_rating(4)
          assert (things.length == 2), "Should have gotten two things with rating 4"
          assert (((things.first.name == "Tied For Second") or (things.first.name == "Also Tied For Second")) and
                  ((things.last.name == "Tied For Second") or (things.last.name == "Also Tied For Second"))),
                  "List was the right length, but contained the wrong items => #{things.inspect}"
        end
      
        def test_find_by_rating_list
          things = RatedThing.find_all_by_rating([1,2,3])
          is_things_one_to_three?(things)
        end
      
        def test_find_by_rating_list_with_range
          things = RatedThing.find_all_by_rating([1,2..3])
          is_things_one_to_three?(things)
        end
      
        def test_find_one_by_rating
          assert_kind_of RatedThing, RatedThing.find_by_rating(5)
          assert_equal "My Favorite", RatedThing.find_by_rating(5).name, "Single thing with rating=5 has wrong name"
        end
      
        def test_find_all_with_minimum_rating
          things = RatedThing.find_all_by_rating(4..-1)
          assert_equal 3, things.length
          names = things.collect {|thing| thing.name}
          assert names.include?("Tied For Second")
          assert names.include?("Also Tied For Second")
          assert names.include?("My Favorite")
        end
      
        def test_update_rating
          thing = RatedThing.find_by_rating(5)
          assert_kind_of RatedThing, thing
          assert_equal "My Favorite", thing.name
          thing.rate(4)
          thing = RatedThing.find_by_rating(5)
          assert thing.nil?, thing.inspect
          things = RatedThing.find_all_by_rating(4)
          assert_equal 3, things.length, RatedThing.find_by_name("My Favorite").inspect
          names = things.collect {|thing| thing.name}
          assert names.include?("My Favorite")
        end
      
        def test_find_all_by_rating_with_args
          things = RatedThing.find_all_by_rating(4, :order => 'name ASC')
          assert (things.length == 2), "Should have gotten two things with rating 4"
          assert_equal "Also Tied For Second", things.first.name
          assert_equal "Tied For Second", things.last.name
        end
      
        def test_find_by_range
          things = RatedThing.find_all_by_rating(1..3)
          is_things_one_to_three?(things)
        end
      
        def test_average_rating
          art = AverageRatedThing.create(:name => "Average Thing", :rating => 1)
          total_rating = 1
          total_times = 1
          assert_equal 1, art.rating
          assert_equal 1, art.ratings_count
          5.times do |i|
            total_rating += 5
            total_times += 1
            art.rate(5)
            assert_equal (total_rating.to_f / total_times.to_f).to_i, art.rating.to_i
            assert_equal total_times, art.ratings_count
          end
        end

        def test_average_rating_with_cache
          art = AverageRatedThingWithCache.create(:name => "Average Thing", :rating => 1)
          total_rating = 1
          total_times = 1
          assert_equal 1, art.rating
          assert_equal 1, art.ratings_count
          5.times do |i|
            total_rating += 5
            total_times += 1
            art.rate(5)
            assert_equal (total_rating.to_f / total_times.to_f).to_i, art.rating.to_i
            assert_equal total_times, art.ratings_count
          end
          assert_equal art[:ratings_average].to_i, art.rating.to_i
        end
        
        def test_rated_by
          person = Rater.create(:name => "Rater")
          rateable = AverageRatedThingWithCache.create(:name => "Average Thing with Cache")
          rateable.rate(5, person)
          assert rating = rateable.rated_by?(person), "should be rated by person"
          assert_equal 5, rating.rating
          assert_equal [rating], person.ratings
        end
        
        def test_undo_rate
          thing = RatedThing.create(:name => "rated thing", :rating => 5)
          assert_equal 5, thing.rating
          thing.undo_rate
          thing.reload
          assert_equal 0, thing.rating
        end

        def test_undo_rate_with_average_and_cache
          person = Rater.new(:name => "rater")
          thing = AverageRatedThingWithCache.create(:name => "rated thing")
          thing.rate(5, person)
          sleep 1

          thing.rate(1, person)
          thing = AverageRatedThingWithCache.find(thing.id)
          assert_equal 3, thing.rating
          assert_equal 3, thing[:ratings_average]
          assert_equal 2, thing.ratings_count
          assert_equal 2, thing[:ratings_count]
          assert latest = thing.rated_by?(person), "was rated by person"
          assert_equal 1, latest.rating
          
          thing.undo_rate(person)
          assert_equal 5, thing.rating
          assert_equal 1, thing.ratings_count
          assert_equal 1, thing[:ratings_count]
          
          thing.undo_rate(person)
          assert_equal 0, thing.rating
          assert_equal 0, thing.ratings_count
          assert_equal 0, thing[:ratings_count]
          
          thing = AverageRatedThingWithCache.find(thing.id)
          assert_equal 0, thing[:ratings_count]
        end

        def test_ratings_cache_columns
          assert_equal false, RatedThing.ratings_count_column?
          assert_equal false, RatedThing.ratings_average_column?

          assert_equal false, RatedThing.new.ratings_count_column?
          assert_equal false, RatedThing.new.ratings_average_column?

          assert_equal true, AverageRatedThingWithCache.ratings_count_column?
          assert_equal true, AverageRatedThingWithCache.ratings_average_column?

          assert_equal true, AverageRatedThingWithCache.new.ratings_count_column?
          assert_equal true, AverageRatedThingWithCache.new.ratings_average_column?
        end
        
        private
        
        def is_things_one_to_three?(things)
          assert_equal 3, things.length, "Incorrect Number of Rated Things with rating between 1 and 3"
          names = things.collect {|thing| thing.name}
          assert (names.include?("My Least Favorite") and names.include?("Don't like this thing very much") and names.include?("Take it or leave it")), "Incorrect records returned"
        end
      
    end
  end
end
