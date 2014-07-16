require File.dirname(__FILE__) + '/../test_helper'

class HashExtTest < ActiveSupport::TestCase
  
  def test_should_merge_finder_options
    assert_equal({:conditions => "a = 1 AND b = 2"},
      {:conditions => "a = 1"}.merge_finder_options(:conditions => "b = 2"))
  end

  def test_should_merge_finder_options!
    options = {:conditions => "a = 1"}
    options.merge_finder_options!(:conditions => "b = 2")
    assert_equal({:conditions => "a = 1 AND b = 2"}, options)
  end

  def test_should_merge_finder_options_with_order
    assert_equal({:conditions => "a = 1 AND b = 2", :order => "a ASC, b DESC"},
      {:conditions => "a = 1", :order => "a ASC"}.merge_finder_options(:conditions => "b = 2", :order => "b DESC"))
  end

  def test_should_merge_finder_options_with_one_order
    assert_equal({:conditions => "a = 1 AND b = 2", :order => "a ASC"},
      {:conditions => "a = 1", :order => "a ASC"}.merge_finder_options(:conditions => "b = 2", :order => nil))

    assert_equal({:conditions => "a = 1 AND b = 2", :order => "a ASC"},
      {:conditions => "a = 1"}.merge_finder_options(:conditions => "b = 2", :order => "a ASC"))

  end

  def test_should_merge_finder_options_with_more_options
    assert_equal({:conditions => "a = 1 AND b = 2", :order => "a ASC", :limit => 1},
      {:conditions => "a = 1", :order => "a ASC", :limit => 1}.merge_finder_options(:conditions => "b = 2", :order => nil))

    assert_equal({:conditions => "a = 1 AND b = 2", :order => "a ASC", :limit => 2},
      {:conditions => "a = 1", :order => "a ASC", :limit => 1}.merge_finder_options(:conditions => "b = 2", :limit => 2))

    assert_equal({:conditions => "a = 1 AND b = 2", :order => "a ASC", :limit => 1},
      {:conditions => "a = 1", :order => "a ASC", :limit => 1}.merge_finder_options(:conditions => "b = 2", :limit => nil))
  end
  
  def test_should_merge_complex
    assert_equal({:conditions=>
      "kases.lng NOT NULL AND kases.lat NOT NULL AND status NOT IN ('new','created')"},
      {:conditions => ["kases.lng NOT NULL AND kases.lat NOT NULL"]}.merge_finder_options({:conditions=>["status NOT IN (?)", ["new", "created"]]}))
  end
  
end
