require File.dirname(__FILE__) + '/../test_helper'

class LocationTest < ActiveSupport::TestCase
  fixtures :addresses

  def setup
    GeoKit::Geocoders::MultiGeocoder.stubs(:geocode).returns(valid_geo_location)
  end
  
  def test_should_create
    loc = build_location
    assert loc.valid?
    assert loc.save
  end

  def test_should_geocode_address
    loc = create_location
    assert_equal 37.720592, loc.lat
    assert_equal -122.443287, loc.lng
  end

  def test_should_not_geocode_address
    loc = create_location(:lat => 123.45678, :lng => 12.345678)
    assert_equal 123.45678, loc.lat
    assert_equal 12.345678, loc.lng
  end

  def test_should_return_address_string
    loc = create_location
    assert_equal "100 Rousseau St., San Francisco, CA, 94112, US", loc.to_s
  end

  def test_should_return_kind
    assert_equal :location, Location.kind
    assert_equal :location, Location.new.kind
  end
  
  def test_should_build_from_geo_coordinates
    loc = Location.build_from("geo:lat = 37.720592 geo:lon = -122.443287")
    assert loc
    assert_equal 37.720592, loc.lat
    assert_equal -122.443287, loc.lng
    
    loc = Location.build_from("geo:lat = 37.720592 geo:lng = -122.443287")
    assert loc
    assert_equal 37.720592, loc.lat
    assert_equal -122.443287, loc.lng

    loc = Location.build_from("geo:lat=-0.3515602939922709 geo:lon=-0.390625")
    assert loc
    assert_equal -0.3515602939922709, loc.lat
    assert_equal -0.390625, loc.lng
  end
  
  def test_should_build_from_address
    loc = Location.build_from("100 Rousseau St., San Francisco, CA, 94112, US")
    assert loc
    assert loc.is_a?(Location), 'should be a location instance'
    assert_equal 37.720592, loc.lat
    assert_equal -122.443287, loc.lng
    assert_equal '100 Rousseau St', loc.street
    assert_equal 'US', loc.country_code
    assert_equal '94112', loc.postal_code
    assert_equal 'CA', loc.province_code
    assert_equal 'San Francisco', loc.city
  end

  def test_should_build_from_location
    loc = Location.build_from(create_location)
    assert loc
    assert loc.is_a?(Location), 'should be a location instance'
    assert_equal 37.720592, loc.lat
    assert_equal -122.443287, loc.lng
    assert_equal '100 Rousseau St.', loc.street
    assert_equal 'US', loc.country_code
    assert_equal '94112', loc.postal_code
    assert_equal 'CA', loc.province_code
    assert_equal 'San Francisco', loc.city
  end

  def test_should_build_from_address
    loc = Location.build_from(create_address)
    assert loc
    assert loc.is_a?(Location), 'should be a location instance'
    assert_equal 37.720592, loc.lat
    assert_equal -122.443287, loc.lng
    assert_equal '100 Washington St.', loc.street
    assert_equal 'US', loc.country_code
    assert_equal '95065', loc.postal_code
    assert_equal 'CA', loc.province_code
    assert_equal 'Santa Cruz', loc.city
  end
  
  def test_should_geokit_attributes
    loc = create_location
    attributes = loc.geokit_attributes
    assert_equal loc.postal_code, attributes[:zip]
    assert_equal loc.city, attributes[:city]
    assert_equal loc.country_code, attributes[:country_code]
    assert_equal loc.province_code, attributes[:state]
    assert_equal loc.lat, attributes[:lat]
    assert_equal loc.lng, attributes[:lng]
  end
  
  def test_should_return_lat_lng_s
    loc = Location.new(:lat => 37.720592, :lng => -122.443287)
    assert_equal "geo:lat=37.720592 geo:lng=-122.443287", loc.to_lat_lng_s
  end
  
  def test_should_return_geo_string_for_to_s
    loc = Location.new(:lat => 37.720592, :lng => -122.443287)
    assert_equal "geo:lat=37.720592 geo:lng=-122.443287", loc.to_s
  end
  
  def test_should_not_return_geo_string_for_to_s
    loc = Location.new(:country_code => 'US', :lat => 37.720592, :lng => -122.443287)
    assert_equal "US", loc.to_s
  end
  
end
