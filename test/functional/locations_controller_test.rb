require File.dirname(__FILE__) + '/../test_helper'
require 'locations_controller'

# Re-raise errors caught by the controller.
class LocationsController; def rescue_action(e) raise e end; end

class LocationsControllerTest < Test::Unit::TestCase
  all_fixtures
  
  def setup
    @controller = LocationsController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
    
    @request.with_subdomain('us')

    login_as :homer
  end

  def test_should_route
    assert_routing '/locations', hash_for_path(:locations)
    # person
    assert_routing '/people/homer/locations', hash_for_path(:locations, :person_id => 'homer')

    # kase
    assert_routing '/kases/all/locations', hash_for_path(:locations, :kase_id => 'all')
    assert_routing '/categories/law/kases/all/locations', hash_for_path(:locations, :category_id => 'law', :kase_id => 'all')
    assert_routing '/organizations/luleka/kases/all/locations',
      hash_for_path(:locations, :organization_id => 'luleka', :kase_id => 'all')
    assert_routing '/tags/cancer/categories/law/kases/all/locations',
      hash_for_path(:locations, :tag_id => 'cancer', :category_id => 'law', :kase_id => 'all')
    assert_routing '/tags/cancer/organizations/luleka/kases/all/locations',
      hash_for_path(:locations, :tag_id => 'cancer', :organization_id => 'luleka', :kase_id => 'all')
    assert_routing '/tags/cancer/kases/all/locations',
      hash_for_path(:locations, :tag_id => 'cancer', :kase_id => 'all')
    assert_routing '/kases/one/locations', hash_for_path(:locations, :kase_id => 'one')
    
    # organization
    assert_routing '/organizations/all/locations', hash_for_path(:locations, :organization_id => 'all')
    assert_routing '/tags/cancer/organizations/all/locations',
      hash_for_path(:locations, :tag_id => 'cancer', :organization_id => 'all')
    assert_routing '/organizations/luleka/locations',
      hash_for_path(:locations, :organization_id => 'luleka')
  end
  
  def test_should_get_base_locations_with_current_user
    get :index
    assert_response :success
    assert @locations = assigns(:locations)
    assert_equal people(:homer), @locations.first
  end

  def test_should_get_person_location
    get :index, {:person_id => people(:homer).permalink}
    assert_response :success
    assert @locations = assigns(:locations)
    assert_equal people(:homer), @locations.first
  end

  def test_should_get_kase_location
    get :index, {:kase_id => kases(:powerplant_leak).permalink}
    assert_response :success
    assert @locations = assigns(:locations)
    assert_equal kases(:powerplant_leak), @locations.first
  end

end
