require File.join(File.dirname(__FILE__), '../../../../test', 'test_helper.rb')
module Acts #:nodoc:
  module Visitable #:nodoc:
    
    vote_class = <<-ADDRESS
      class Visit < ActiveRecord::Base
        belongs_to :visited, :polymorphic => true
        belongs_to :visitor, :foreign_key => :visitor_id, :class_name => 'Visitor'
      end
    ADDRESS
    eval vote_class, TOPLEVEL_BINDING
    
    class Visitor < ActiveRecord::Base #:nodoc:
      acts_as_visitor
    end
    
    class VisitedThing < ActiveRecord::Base #:nodoc:
      acts_as_visitable :class_name => 'Visitor'
    end
  
    class VisitedThingWithCache < ActiveRecord::Base #:nodoc:
      acts_as_visitable :class_name => 'Visitor'
    end

    class ActsAsVoteableTest < Test::Unit::TestCase #:nodoc:
        def setup  
          ActiveRecord::Schema.define do
            # create_table :visits, :force => true do |t|
            #  t.column :visitor_id, :integer
            #  t.column :visited_id, :integer
            #  t.column :visited_type, :string
            #  t.column :uuid, :string
            # end

            create_table :visitors, :force => true do |t|
              t.column :name, :string
            end
        
            create_table :visited_things, :force => true do |t|
              t.column :name, :string
            end
          
            create_table :visited_thing_with_caches, :force => true do |t|
              t.column :name, :string
              t.column :visits_count, :integer, :default => 0, :null => false
              t.column :views_count, :integer, :default => 0, :null => false
            end
          end
          
          @visitor = Visitor.create(:name => "A test visitor")
        end
    
        def teardown
          Visit.delete_all
          Visitor.delete_all
          VisitedThing.delete_all
          VisitedThingWithCache.delete_all
        end
    
        def test_has_visitable_included
          assert VisitedThing.singleton_methods.include?('acts_as_visitable'),
            "acts_as_visitable not included in ActiveRecord class"
        end

        def test_simple_visit
          thing = VisitedThing.create(:name => "A visited thing")

          assert_equal 0, thing.visits_count
          assert thing.visit("fe7f785b6941a20aaf5fd11816d3f28b")
          assert_equal 1, thing.visits_count
          
          assert_equal false, thing.visit("fe7f785b6941a20aaf5fd11816d3f28b")
          assert_equal 1, thing.visits_count
        end

        def test_simple_visit_with_cache
          thing = VisitedThingWithCache.create(:name => "A visited thing")

          assert_equal 0, thing.visits_count
          assert_equal 0, thing[:visits_count]
          assert thing.visit("fe7f785b6941a20aaf5fd11816d3f28b")
          assert_equal 1, thing.visits_count
          assert_equal 1, thing[:visits_count]
          
          assert_equal false, thing.visit("fe7f785b6941a20aaf5fd11816d3f28b")
          assert_equal 1, thing.visits_count
          assert_equal 1, thing[:visits_count]
        end

        def test_simple_view
          thing = VisitedThing.create(:name => "A visited thing")

          assert_equal 0, thing.visits_count
          assert_equal 0, thing.views_count
          
          assert thing.view("fe7f785b6941a20aaf5fd11816d3f28b")
          assert_equal 1, thing.visits_count
          assert_equal 1, thing.views_count
          
          assert thing.view("fe7f785b6941a20aaf5fd11816d3f28b")
          assert_equal 1, thing.visits_count
          assert_equal 2, thing.views_count
        end

        def test_simple_view_with_cache
          thing = VisitedThingWithCache.create(:name => "A visited thing")

          assert_equal 0, thing.visits_count
          assert_equal 0, thing.views_count
          
          assert thing.view("fe7f785b6941a20aaf5fd11816d3f28b")
          assert_equal 1, thing.visits_count
          assert_equal 1, thing.views_count
          
          assert thing.view("fe7f785b6941a20aaf5fd11816d3f28b")
          assert_equal 1, thing.visits_count
          assert_equal 2, thing.views_count
        end

        def test_view_with_visitor
          thing = VisitedThing.create(:name => "A visited thing")

          assert_equal 0, thing.visits_count
          assert_equal 0, thing.views_count
          
          assert thing.view(@visitor)
          assert_equal 1, thing.visits_count
          assert_equal 1, thing.views_count
          
          assert thing.view(@visitor)
          assert_equal 1, thing.visits_count
          assert_equal 2, thing.views_count
        end
        
        def test_visitors
          thing = VisitedThing.create(:name => "A visited thing")
          visitor_a = Visitor.create(:name => "Visitor A")
          visitor_b = Visitor.create(:name => "Visitor B")
          visitor_c = Visitor.create(:name => "Visitor C")
          
          assert visit_a = thing.visit(visitor_a, {:created_at => Time.now.utc - 3.minutes})
          assert visit_b = thing.visit(visitor_b, {:created_at => Time.now.utc - 2.minutes})
          assert visit_c = thing.visit(visitor_c, {:created_at => Time.now.utc - 1.minute})

          assert_equal visitor_a, visit_a.visitor
          assert_equal visitor_b, visit_b.visitor
          assert_equal visitor_c, visit_c.visitor
          
          assert_equal 3, thing.visits_count
          assert_equal [visitor_c, visitor_b, visitor_a], thing.visitors
        end

        def test_viewers
          thing = VisitedThing.create(:name => "A visited thing")
          visitor_a = Visitor.create(:name => "Visitor A")
          visitor_b = Visitor.create(:name => "Visitor B")
          visitor_c = Visitor.create(:name => "Visitor C")
          
          assert visit_a = thing.view(visitor_a, {:created_at => Time.now.utc - 6.minutes})
          assert visit_b = thing.view(visitor_b, {:created_at => Time.now.utc - 5.minutes})
          assert visit_c = thing.view(visitor_c, {:created_at => Time.now.utc - 4.minute})

          assert visit_a = thing.view(visitor_a, {:created_at => Time.now.utc - 3.minutes})
          assert visit_b = thing.view(visitor_b, {:created_at => Time.now.utc - 2.minutes})
          assert visit_c = thing.view(visitor_c, {:created_at => Time.now.utc - 1.minute})

          assert_equal 6, thing.views_count
          assert_equal 3, thing.visits_count
          assert_equal [visitor_c, visitor_b, visitor_a, visitor_c, visitor_b, visitor_a], thing.viewers
        end
        
        def test_should_be_viewed_by
          thing = VisitedThing.create(:name => "A visited thing")
          assert visit = thing.view(@visitor)
          assert_equal visit, thing.viewed_by?(@visitor)
        end

        def test_should_not_be_viewed_by
          thing = VisitedThing.create(:name => "A visited thing")
          assert_equal nil, thing.viewed_by?(@visitor)
        end

        def test_should_be_visited_by
          thing = VisitedThing.create(:name => "A visited thing")
          assert visit = thing.visit(@visitor)
          assert_equal visit, thing.visited_by?(@visitor)
        end

        def test_should_not_be_visited_by
          thing = VisitedThing.create(:name => "A visited thing")
          assert_equal nil, thing.visited_by?(@visitor)
        end
        
        def test_votes_column
          assert_equal false, VisitedThing.visits_count_column?
          assert_equal false, VisitedThing.views_count_column?
          
          assert_equal false, VisitedThing.new.visits_count_column?
          assert_equal false, VisitedThing.new.views_count_column?

          assert_equal true, VisitedThingWithCache.visits_count_column?
          assert_equal true, VisitedThingWithCache.views_count_column?
          
          assert_equal true, VisitedThingWithCache.new.visits_count_column?
          assert_equal true, VisitedThingWithCache.new.views_count_column?
        end

    end
  end
end
