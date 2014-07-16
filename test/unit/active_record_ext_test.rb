require File.dirname(__FILE__) + '/../test_helper'

class ActiveRecordExtTest < ActiveSupport::TestCase
  
  def test_should_sanitize_and_merge_conditions_strings
    assert_equal "id = 1 AND person_id = 2",
      ActiveRecord::Base.sanitize_and_merge_conditions("id = 1", "person_id = 2")
  end

  def test_should_sanitize_and_merge_conditions_array
    assert_equal "id = 1 AND user_id IN (1,2,3)", 
      ActiveRecord::Base.sanitize_and_merge_conditions("id = 1", ["user_id IN (?)", [1, 2, 3]])
  end

  def test_should_not_sanitize_and_merge_conditions
    assert_equal "id = 1", 
      ActiveRecord::Base.sanitize_and_merge_conditions("id = 1", nil)

    assert_equal "id = 1", 
      ActiveRecord::Base.sanitize_and_merge_conditions("id = 1", "")

    assert_equal "id = 1", 
      ActiveRecord::Base.sanitize_and_merge_conditions("id = 1", [])
  end

  def test_should_sanitize_and_merge_order
    assert_equal "id ASC, people.id DESC",
      ActiveRecord::Base.sanitize_and_merge_order("id ASC", "people.id DESC")

    assert_equal "id ASC, at DESC, people.id DESC",
      ActiveRecord::Base.sanitize_and_merge_order("id ASC, at DESC,", "people.id DESC")

    assert_equal "id ASC, at DESC, people.id DESC",
      ActiveRecord::Base.sanitize_and_merge_order("id ASC, at DESC,", "", "people.id DESC")

    assert_equal "id ASC, at DESC, people.id DESC",
      ActiveRecord::Base.sanitize_and_merge_order("id ASC, at DESC,", ",", "people.id DESC")
  end

  def test_should_not_sanitize_and_merge_order
    assert_equal nil,
      ActiveRecord::Base.sanitize_and_merge_order(nil)

    assert_equal nil,
      ActiveRecord::Base.sanitize_and_merge_order(nil, nil)

    assert_equal "id ASC",
      ActiveRecord::Base.sanitize_and_merge_order(nil, "id ASC")

    assert_equal "id ASC",
      ActiveRecord::Base.sanitize_and_merge_order(nil, ",", nil, [], "id ASC", " ,")

  end

  
end
