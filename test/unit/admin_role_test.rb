require File.dirname(__FILE__) + '/../test_helper'

class AdminRoleTest < ActiveSupport::TestCase
  all_fixtures
  
  # Replace this with your real tests.
  def test_should_create
    assert_difference AdminRole, :count do 
      AdminRole.create(:kind => "colocator", :name => "Colocator")
    end
  end
  
  def test_human_name
    ar = AdminRole.new(:kind => "colocator")
    assert_equal "Colocator", ar.name
  end
  
end
