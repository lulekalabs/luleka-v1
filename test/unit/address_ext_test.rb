require File.dirname(__FILE__) + '/../test_helper'

class AddressExtTest < ActiveSupport::TestCase
  all_fixtures

  def test_should_create
    address = create_address
    assert address.valid?
  end
  
  def test_should_load_address_from_fixture
    a = addresses(:homer_personal_address)
    assert_equal 'Homer Simpson', a.name
    assert_equal people(:homer), a.addressable
  end
  
  def test_should_get_salutation
    assert_equal "Dr.", Address.new(
      :first_name => 'Adam',
      :last_name => "Smith",
      :middle_name => "D.",
      :gender => 'm',
      :academic_title => academic_titles(:dr)
    ).salutation

    assert_equal "Mr", Address.new(
      :first_name => 'Rob',
      :last_name => "Smith",
      :middle_name => "K.",
      :gender => 'm'
    ).salutation

    assert_equal "Ms", Address.new(
      :first_name => 'Barbara',
      :last_name => "Smith",
      :gender => 'f'
    ).salutation
  end

  def test_should_not_get_salutation
    assert_nil Address.new(
      :first_name => 'Adam',
      :last_name => "Smith",
      :middle_name => "D."
    ).salutation
  end

  def test_should_get_salutation_and_name
    assert_equal "Prof. Dr. Adam D. Smith", Address.new(
      :first_name => 'Adam',
      :last_name => "Smith",
      :middle_name => "D.",
      :gender => 'm',
      :academic_title => academic_titles(:prof_dr)
    ).salutation_and_name

    assert_equal "Mr Robert K. Smith", Address.new(
      :first_name => 'Robert',
      :last_name => "Smith",
      :middle_name => "K.",
      :gender => 'm'
    ).salutation_and_name

    assert_equal "Ms Barbara Smith", Address.new(
      :first_name => 'Barbara',
      :last_name => "Smith",
      :gender => 'f'
    ).salutation_and_name
  end
  
  def test_should_get_city_postal_and_province_format
    assert_equal "%c, %s %z", Address.city_postal_and_province_format('US')
    assert_equal "%z %c", Address.city_postal_and_province_format('DE')
    I18n.switch_locale :"de-DE" do
      assert_equal "%z %c", Address.city_postal_and_province_format
    end
  end

  def test_should_get_city_postal_and_province
    assert_equal "San Francisco, CA 94112", Address.new(
      :city => 'San Francisco',
      :province_code => 'CA',
      :postal_code => '94112'
    ).city_postal_and_province(:country_code => 'US')

    assert_equal "San Francisco, CA 94112", Address.new(
      :city => 'San Francisco',
      :province_code => 'CA',
      :province => 'California',
      :postal_code => '94112'
    ).city_postal_and_province(:country_code => 'US')

    assert_equal "San Francisco, California 94112", Address.new(
      :city => 'San Francisco',
      :province => 'California',
      :postal_code => '94112'
    ).city_postal_and_province(:country_code => 'US')

    assert_equal "San Francisco, CA 94112", Address.new(
      :city => 'San Francisco',
      :province_code => 'CA',
      :postal_code => '94112',
      :country_code => 'US'
    ).city_postal_and_province

    assert_equal "80469 München", Address.new(
      :city => 'München',
      :province_code => 'BY',
      :postal_code => '80469'
    ).city_postal_and_province(:country_code => 'DE')

    assert_equal "80469 München", Address.new(
      :city => 'München',
      :province_code => 'BY',
      :postal_code => '80469',
      :country_code => 'DE'
    ).city_postal_and_province
  end

  def test_should_geokit_attributes
    address = create_address
    attributes = address.geokit_attributes
    assert_equal address.postal_code, attributes[:zip]
    assert_equal address.city, attributes[:city]
    assert_equal address.country_code, attributes[:country_code]
    assert_equal address.province_code, attributes[:state]
  end
  
  
end
