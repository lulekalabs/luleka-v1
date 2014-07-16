require File.dirname(__FILE__) + '/../test_helper'

class OrganizationTest < ActiveSupport::TestCase
  all_fixtures

  def setup
    GeoKit::Geocoders::MultiGeocoder.stubs(:geocode).returns(valid_geo_location)
  end

  def test_should_create
    org = create_organization
    assert org.valid?
  end

  def test_subkinds
    assert_equal 0, Organization.subkinds.size
  end

  def test_should_not_validate
    org = Organization.new invalid_organization_attributes
    assert !org.valid?
    assert org.errors.on(:name)
    assert org.errors.on(:site_name)
    # name
    org.name = "Ab"
    assert !org.valid?
    assert org.errors.on(:name)
    org.name = "Abc"
    assert !org.valid?
    assert !org.errors.on(:name)
    # site_name
    (Organization::BANNED_SITE_NAMES + %w(_abcd ?bla)).each do |invalid_site_name|
      org.site_name = invalid_site_name
      assert !org.valid?
      assert org.errors.on(:site_name)
    end
    org.site_name = 'hello-abc'
    org.valid?
    assert !org.errors.on(:site_name)
    # site_url
    %w(site://blup.com blup).each do |invalid_url|
      org.site_url = invalid_url
      assert !org.valid?
      assert org.errors.on(:site_url)
    end
  end

  def test_should_activate_suspend_unsuspend
    org = create_organization
    assert org.valid?
    assert !org.activation_code.blank?
    assert_equal :pending, org.current_state
    assert org.activate!
    assert_equal :active, org.current_state
    assert !org.activated_at.blank?
    saved_activated_at = org.activated_at
    assert org.suspend!
    assert_equal :suspended, org.current_state
    assert org.unsuspend!
    assert_equal :active, org.current_state
    assert_equal saved_activated_at.to_date.to_s, org.activated_at.to_date.to_s
  end

  def test_should_create_permalink
    org = create_organization :name => 'The Fox jumps over the fence'
    assert org.valid?
    assert 'the-fox-jumps-over-the-fence', org.permalink
  end

  def test_has_many_products
    org = tiers(:luleka)
    assert 9, org.products.size
    org = tiers(:luleka_de)
    assert 9, org.products.size
  end

  def test_has_finder_active
    orgs = Organization.active
    assert_equal 8, orgs.size
  end
  
  def test_has_many_kases_through_kontext
    powerplant = tiers(:powerplant)
    kases_count = powerplant.kases.count
    kase = create_idea(:title => 'Core Meltdown')
    assert kase.valid?
    assert_difference Kontext, :count, 1 do 
      powerplant.kases << kase
    end
    assert powerplant.save
    powerplant.reload
    assert_equal kases_count, powerplant.kases.count
    assert_difference Kontext, :count, -1 do 
      powerplant.kases.delete(kase)
    end
    powerplant.reload
    assert_equal kases_count, powerplant.kases.count
  end
  
  def test_should_find_by_permalink_and_region_and_active
    org = Organization.find_by_permalink_and_region_and_active('luleka', 'US', true)
    assert org
    assert 'Luleka Inc.', org.name
  end
  
  def test_should_not_find_by_permalink_and_region_and_active
    assert_raise ActiveRecord::RecordNotFound do
      Organization.find_by_permalink_and_region_and_active('luleka', 'US', false)
    end
  end
  
  def test_created_by_association
    homer = people(:homer)
    org = create_organization(:created_by => homer)
    assert org.valid?
    assert_equal homer, org.created_by
    homer.reload
    assert_equal org, homer.created_organizations.first
  end
  
  def test_has_many_people_association
    assert_difference Kase, :count do 
      assert_difference Kontext, :count do
        powerplant = tiers(:powerplant)
        kase = create_idea(:title => "Core Meltdown", :person => people(:marge), :tier => powerplant)
        assert kase.activate!, "should activate"
        powerplant.reload
        assert !powerplant.people.empty?, "should have associated people"
        assert powerplant.people.include?(people(:marge)), "should include Marge Simpson"
      end
    end
  end
  
  def test_has_finder_most_active
    orgs = Organization.most_active
    assert !orgs.empty?
  end
  
  def test_has_finder_region
    orgs = Organization.region('DE')
    assert orgs.include?(tiers(:powerplant_de))
    assert !orgs.include?(tiers(:powerplant))
  end

  def test_has_finder_current_region
    orgs = Organization.current_region
    assert !orgs.include?(tiers(:powerplant_de))
    assert orgs.include?(tiers(:powerplant))
  end
  
  def test_should_find_recent_organizations
    old_count = Organization.count
    assert_difference Organization, :count, 5 do
      create_organizations(5) do |org|
        org.activate!
      end
    end
    new_count = Organization.count
    assert_equal 5, new_count - old_count
    assert_equal 5, Organization.recent.size
  end
  
  def test_should_find_popular_organizations
    assert_equal 3, Organization.popular.size
  end
  
  def test_should_has_many_popular_products
    powerplant = tiers(:powerplant)
    assert_equal 0, powerplant.popular_products.size
  end

  def test_should_has_many_recent_products
    powerplant = tiers(:powerplant)
    assert_equal 3, powerplant.recent_products.size
  end
  
  def test_should_retrieve_all_organizations
    all = tiers(:luleka_de).worldwide
    assert_equal 3, all.size
    assert all.map(&:name).include?('Luleka'), 'should get Luleka'
    assert all.map(&:name).include?('Luleka Inc.'), 'should get Luleka Inc'
    assert all.map(&:name).include?('Luleka GmbH'), 'should get Luleka GmbH'
    assert_equal 3, tiers(:luleka).worldwide.size
  end

  def test_default_currency
    assert_equal 'EUR', build_organization(:country_code => 'DE').default_currency
    assert_equal 'USD', build_organization(:country_code => 'US').default_currency
    assert_equal 'USD', build_organization(:country_code => nil).default_currency
  end

  def test_should_create_piggy_bank_account
    assert_difference PiggyBankAccount, :count do
      org = create_organization
      assert org.valid?
      assert_equal org, org.piggy_bank.owner
    end
  end
  
  def test_should_find_root_by_permalink
    org = Organization.find_worldwide_or_regional_by_permalink_and_active('luleka', true, :include => :piggy_bank)
    assert org
    assert_equal tiers(:luleka).id, org.id

    org = Organization.find_worldwide_or_regional_by_permalink_and_active('powerplant', true, :include => :piggy_bank)
    assert org
    assert_equal tiers(:powerplant).id, org.id
  end

  def test_should_get_probono_as_company
    assert_equal tiers(:luleka), Organization.probono
  end

  def test_should_have_one_address
    assert Organization.probono.address, 'should have a default address'
    assert_equal "100 Rousseau St, San Francisco, California, 94112, United States", Organization.probono.address.to_s
  end
  
  def test_should_build_address_and_geocode
    assert org = create_organization
    org.build_address(valid_address_attributes)
    org.save
    org = Organization.find_by_id(org.id)
    assert_equal "100 Enterprise Way, Scotts Valley, CA, 95060, United States", org.address.to_s
    assert org.lat
    assert org.lng
  end

  def test_should_create_address_and_geocode
    assert org = create_organization
    org.create_address(valid_address_attributes)
    org = Organization.find_by_id(org.id)
    assert_equal "100 Enterprise Way, Scotts Valley, CA, 95060, United States", org.address.to_s
    assert org.lat
    assert org.lng
  end

  def test_should_get_geo_location
    assert org = create_organization
    org.build_address(valid_address_attributes)
    geo = org.geo_location
    assert geo.success, "should have a geo location"
#    assert_equal 37.720592, geo.lat
#    assert_equal -122.443287, geo.lng
    org.save
    org = Organization.find_by_id(org.id)
    geo = org.geo_location
    assert geo.success, "should have a geo location"
#    assert_equal 37.7206, geo.lat
#    assert_equal -122.443, geo.lng
  end
  
  def test_should_be_geo_coded
    assert tiers(:luleka).geo_coded?, "luleka should be geocoded"
  end

  def test_employments
    powerplant = create_organization
    e1 = Employment.create(:tier_id => powerplant.id, :person_id => people(:bart)) and e1.activate! and e1.admin!
    e2 = Employment.create(:tier_id => powerplant.id, :person_id => people(:quentin)) and e2.activate! and e2.moderator!
    e3 = Employment.create(:tier_id => powerplant.id, :person_id => people(:aaron)) and e3.activate!
    e4 = Employment.create(:tier_id => powerplant.id, :person_id => people(:lisa))
    m1 = Membership.create(:tier_id => powerplant.id, :person_id => people(:marge)) and m1.activate!

    powerplant.reload
    assert_equal 4, powerplant.members_count
    
    assert_equal 5, powerplant.memberships.size
    assert_equal 4, powerplant.employments.size
    assert_equal 3, powerplant.employees.size
    assert_equal 1, powerplant.admins.size
    assert_equal 1, powerplant.moderators.size
  end

  def test_should_validate_tax_code
    powerplant = build_organization(:country_code => 'US', :tax_code => "123-12-1234")
    assert powerplant.valid?
    assert !powerplant.errors.on(:tax_code)

    powerplant = build_organization(:country_code => 'US', :tax_code => "12-1234567")
    assert powerplant.valid?
    assert !powerplant.errors.on(:tax_code)

    powerplant = build_organization(:country_code => 'US', :tax_code => "900-12-3456")
    assert powerplant.valid?
    assert !powerplant.errors.on(:tax_code)
  end

  def test_should_not_validate_tax_code
    powerplant = build_organization(:country_code => 'US', :tax_code => "xxx")
    assert !powerplant.valid?
    assert powerplant.errors.on(:tax_code), "tax_code should be invalid"
  end
  
  def test_should_have_many_claimings
    organization = tiers(:luleka)
    assert organization.claimings, 'should have claimings'
  end

  def test_should_add_english_kase_template_upon_activation
    assert_difference Organization, :count do
      assert_difference Kase, :count do
        organization = create_organization(:name => "Apple")
        assert organization.activate!
        organization.reload
        assert kase = organization.kases.first, "should have a kase template"
        assert_equal "Welcome Apple!", kase.title
        assert_equal "Here you can find and start cases about Apple.", kase.description
        assert kase.permalink.match(/^welcome-apple-[a-z0-9]*/i), "should create unique permalink"
      end
    end
  end

  def test_should_add_german_kase_template_upon_activation
    assert_difference Organization, :count do
      assert_difference Kase, :count do
        organization = create_organization(:name => "Osram", :language_code => 'de')
        assert organization.activate!
        organization.reload
        assert kase = organization.kases.first, "should have a kase template"
        assert_equal "Willkommen Osram!", kase.title
        assert_equal "Hier können Sie einen Fall über Osram starten und sich mit anderen Interessierten und Betroffenen austauschen.", 
          kase.description
        assert kase.permalink.match(/^willkommen-osram-[a-z0-9]*/i), "should create unique permalink"
      end
    end
  end

  protected
  
  def valid_address_attributes(options={})
    {
      :first_name => 'Bob',
      :last_name => 'Smith',
      :street => '100 Enterprise Way',
      :city => 'Scotts Valley',
      :postal_code => '95060',
      :province_code => 'CA',
      :country_code => 'US',
      :phone => '+1 (408) 123-4567',
      :mobile => '+1 (408) 456-4321',
      :fax => '+1 (408) 467-0934'
    }.merge(options)
  end
  
end
