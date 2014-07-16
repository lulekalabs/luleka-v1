require File.dirname(__FILE__) + '/../test_helper'

class TierTest < ActiveSupport::TestCase
  ROOT = File.join(File.dirname(__FILE__), '..')
  all_fixtures

  def setup
    GeoKit::Geocoders::MultiGeocoder.stubs(:geocode).returns(valid_geo_location)
    ActionMailer::Base.deliveries.clear
    # create slugs
    Tier.all.each {|r| r.save(:validate => false)}
  end

  def test_should_instantiate
    tier = Tier.new
    assert tier.is_a?(Tier)
    assert_equal :tier, tier.kind
  end
  
  def test_subkinds
    assert_equal [:organization, :group].to_set, Tier.subkinds.to_set
  end

  def test_self_and_subkinds
    assert_equal [:tier, :organization, :group].to_set, Tier.self_and_subkinds.to_set
  end
  
  def test_self_and_subclasses
    assert_equal [Tier, Organization, Group].to_set, Tier.self_and_subclasses.to_set
  end
  
  def test_should_instantiate_organization
    organization = Organization.new
    assert organization.is_a?(Organization)
    assert organization.is_a?(Tier)
    assert_equal :organization, organization.kind

    organization = Tier.new :type => :organization
    assert organization.is_a?(Organization)
    assert organization.is_a?(Tier)
    assert_equal :organization, organization.kind

    organization = Tier.new :type => 'Organization'
    assert organization.is_a?(Organization)
    assert organization.is_a?(Tier)
    assert_equal :organization, organization.kind

    organization = Tier.new :type => Organization
    assert organization.is_a?(Organization)
    assert organization.is_a?(Tier)
    assert_equal :organization, organization.kind
  end

  def test_should_return_site_domain
    assert_equal 'powerplant.net', tiers(:powerplant).site_domain
    assert_equal 'freak.de', build_organization(:site_url => 'https://what.the.freak.de:8808/blup/can/do').site_domain
  end

  def test_should_not_return_site_domain
    assert_nil build_organization(:site_url => 'https://what:8808/blup/can/do').site_domain
  end
  
  def test_has_many_topics
    org = tiers(:luleka)
    assert 9, org.topics.size
    org = tiers(:luleka_de)
    assert 9, org.topics.size
  end
  
  def test_should_has_many_popular_topics
    powerplant = tiers(:powerplant)
    assert_equal 0, powerplant.popular_topics.size
  end

  def test_should_has_many_recent_topics
    powerplant = tiers(:powerplant)
    assert_equal 3, powerplant.recent_topics.size
  end
  
  def test_employments
    powerplant = create_tier
    m1 = Employment.create(:tier_id => powerplant.id, :person_id => people(:quentin)) and m1.activate!
    m2 = Employment.create(:tier_id => powerplant.id, :person_id => people(:aaron)) and m2.activate! and m2.admin!
    m3 = Employment.create(:tier_id => powerplant.id, :person_id => people(:lisa)) and m3.activate! and m3.moderator!
    e1 = Employment.create(:tier_id => powerplant.id, :person_id => people(:bart))
    e2 = Employment.create(:tier_id => powerplant.id, :person_id => people(:quentin))
    
    assert_equal 5, powerplant.memberships.count
    assert_equal 3, powerplant.members.count
    assert_equal 1, powerplant.admins.count
    assert_equal 1, powerplant.moderators.count
  end

  def test_should_attach_image
    tier = build_tier
    tier.image = File.new(File.join(ROOT, "fixtures", "files", "beetle_48kb.jpg"), 'rb')
    assert tier.save, "should save"
    assert tier.image.file?,"should have file attached"
    assert tier.image(:thumb).match("thumb_beetle_48kb.jpg"), "should attach thumb"
    assert tier.image(:profile).match("profile_beetle_48kb.jpg"), "should attach profile"
    assert tier.image(:portrait).match("portrait_beetle_48kb.jpg"), "should attach portrait"
  end

  def test_should_attach_logo
    tier = build_tier
    tier.logo = File.new(File.join(ROOT, "fixtures", "files", "logo_4kb.png"), 'rb')
    assert tier.save, "should save"
    assert tier.logo.file?,"should have file attached"
    assert tier.logo(:normal).match("normal_logo_4kb.png"), "should attach thumb"
  end

  def test_should_not_validate_image_size
    tier = build_tier
    tier.image = File.new(File.join(ROOT, "fixtures", "files", "beetle_296kb.jpg"), 'rb')
    assert !tier.valid?, "should not validate file size"
    assert_equal "exceeds 256KB image size", tier.errors.on(:image)
  end

  def test_should_not_validate_image_file_type
    tier = build_tier
    tier.image = File.new(File.join(ROOT, "fixtures", "files", "beetle_228kb.bmp"), 'rb')
    assert !tier.valid?, "should not validate file size"
    assert_equal "GIF, PNG, JPG, and JPEG files only", tier.errors.on(:image)
  end

  def test_topic_class
    assert_equal Topic, Tier.topic_class
    assert_equal Topic, Tier.new.topic_class
    
    assert_equal Product, Organization.topic_class
    assert_equal Product, Organization.new.topic_class
  end

  def test_topic_kind
    assert_equal :topic, Tier.topic_kind
    assert_equal :topic, Tier.topic_type
    assert_equal :topic, Tier.new.topic_kind
    assert_equal :topic, Tier.new.topic_type

    assert_equal :product, Organization.topic_kind
    assert_equal :product, Organization.topic_type
    assert_equal :product, Organization.new.topic_kind
    assert_equal :product, Organization.new.topic_type
  end

  def test_topic_s
    assert_equal "topic", Tier.topic_s
    assert_equal "topic", Tier.new.topic_s

    assert_equal "topics", Tier.topics_s
    assert_equal "topics", Tier.new.topics_s
  end

  def test_topic_t
    assert_equal "topic", Tier.topic_t
    assert_equal "topic", Tier.new.topic_t

    assert_equal "topics", Tier.topics_t
    assert_equal "topics", Tier.new.topics_t
  end
  
  def test_subclass_param_ids
    assert_equal [:organization_id, :group_id].to_set, Tier.subclass_param_ids.to_set
    assert_equal [].to_set, Organization.subclass_param_ids.to_set
  end

  def test_self_and_subclass_param_ids
    assert_equal [:tier_id, :organization_id, :group_id].to_set, Tier.self_and_subclass_param_ids.to_set
    assert_equal [:organization_id].to_set, Organization.self_and_subclass_param_ids.to_set
  end

  def test_should_read_subclass_params
    params = {}
    params[:organization_id] = "yes"
    id = Tier.self_and_subclass_param_ids.each {|id| return params[id] if params[id]} 
    assert_equal "yes", id
    
    params = {}
    id = Tier.self_and_subclass_param_ids.each {|id| return params[id] if params[id]} 
    assert_equal nil, id

    params = {:sepp_id => 'no'}
    id = Tier.self_and_subclass_param_ids.each {|id| return params[id] if params[id]} 
    assert_equal nil, id
    
  end

  def test_address_attributes
    assert_difference Address, :count do
      tier = build_tier(:address_attributes => valid_address_attributes)
      assert_equal "100 Washington St., Santa Cruz, California, 95065, United States of America", tier.address.to_s
      assert tier.save
    end
  end

  def test_find_by_permalink_and_region_and_active
    assert_equal tiers(:luleka), Tier.find_by_permalink_and_region_and_active('luleka', 'US', true)
    assert_equal tiers(:luleka), Tier.find_by_permalink_and_region_and_active('luleka', 'DE', true)
    assert_equal tiers(:luleka), Tier.find_by_permalink_and_region_and_active('luleka', nil, true)
    assert_equal tiers(:luleka), Tier.find_by_permalink_and_region_and_active('luleka', nil, nil)
    assert_raise ActiveRecord::RecordNotFound do
      Tier.find_by_permalink_and_region_and_active('luleka', 'US', false)
    end
    assert_equal tiers(:persil_de), Tier.find_by_permalink_and_region_and_active('persil', 'DE', true)
    assert_equal tiers(:persil_uk), Tier.find_by_permalink_and_region_and_active('persil', 'UK', true)
    assert_equal tiers(:persil_de), Tier.find_by_permalink_and_region_and_active('persil', nil, true)
  end
  
  def test_find_by_permalink_and_region_and_active_when_renamed
    tier = Tier.find_by_permalink_and_region_and_active('powerplant')
    assert_equal tiers(:powerplant), tier, "should find tier by permalink"
    assert_equal true, tier.friendly_id_status.best?, "should set slug in result"
    tier.site_name = "kraftwerk"
    assert_equal true, tier.save, "should save tier under new name"
    new_tier = Tier.find_by_permalink_and_region_and_active('kraftwerk')
    assert_equal tiers(:powerplant), new_tier
    assert_equal true, new_tier.friendly_id_status.best?, "should be found as best match"
    old_tier = Tier.find_by_permalink_and_region_and_active('powerplant')
    assert_equal tiers(:powerplant), old_tier, "should still be found"
    assert_equal false, old_tier.friendly_id_status.best?, "should be found but not as best match"
  end
  
  def test_should_find_all_by_region_and_active
    tiers = Tier.find_all_by_region_and_active('US', true)
    assert_equal ["Persil Inc", "Luleka", "Springfield Nuclear Powerplant Inc."].to_set,
      tiers.map(&:name).to_set

    tiers = Tier.find_all_by_region_and_active('DE', true)
    assert_equal ["Luleka", "Persil GmbH"].to_set, tiers.map(&:name).to_set
  end

  def test_should_find_worldwide_by_permalink
    assert_equal tiers(:luleka), Tier.find_worldwide_by_permalink_and_active("luleka")
    assert_nil Tier.find_worldwide_by_permalink_and_active("persil")
  end

  def xtest_should_create_roots_on_activation_with_worldwide_first
    ww = Tier.create(valid_tier_attributes(:country_code => nil))
    assert ww.register!
    assert ww.activate!
    
    de = Tier.create(valid_tier_attributes(:country_code => "DE"))
    assert de.register!
    assert de.activate!
    
    us = Tier.create(valid_tier_attributes(:country_code => "US"))
    assert us.register!
    assert us.activate!
    
    # reload?
    assert_nil ww.parent
    assert_equal ww, us.parent
    assert_equal ww, de.parent
  end

  def test_should_create_roots_on_activation_with_worldwide_last
    de = Tier.create(valid_tier_attributes(:country_code => "DE"))
    assert de.register!
    assert de.activate!
    
    us = Tier.create(valid_tier_attributes(:country_code => "US"))
    assert us.register!
    assert us.activate!
    
    ww = Tier.create(valid_tier_attributes(:country_code => nil))
    assert ww.register!
    assert ww.activate!
    
    ww.reload and us.reload and de.reload
    
    assert_nil ww.parent
    assert_equal ww, us.parent
    assert_equal ww, de.parent
  end

  def test_should_localize_name
    assert_equal ["name", "name_de", "name_es"].to_set, Tier.localized_facets(:name).to_set
  end

  def test_should_localize_description
    assert_equal ["description", "description_de", "description_es"].to_set, Tier.localized_facets(:description).to_set
  end

  def test_should_localize_summary
    assert_equal ["summary", "summary_de", "summary_es"].to_set, Tier.localized_facets(:summary).to_set
  end

  def test_simple_find_by_query
    assert_equal tiers(:persil_us), Tier.find_by_query(:first, 'persil')
  end

  def test_should_have_kases_count_column
    assert_equal true, Tier.kases_count_column?
  end

  def test_should_have_kases_count
    assert_equal 0, tiers(:powerplant).kases_count
  end

  def test_should_update_kases_count
    assert_equal 1, tiers(:powerplant).update_kases_count
  end

  def test_should_have_members_count_column
    assert_equal true, Tier.members_count_column?
  end
  
  def test_should_have_members_count
    assert_equal 0, tiers(:powerplant).members_count
  end

  def test_should_update_members_count
    assert_equal 0, tiers(:powerplant).update_members_count
  end

  def test_should_have_topics_count_column
    assert_equal true, Tier.topics_count_column?
  end

  def test_should_have_topics_count
    assert_equal 0, tiers(:powerplant).topics_count
  end

  def test_should_update_topics_count
    assert_equal 3, tiers(:powerplant).update_topics_count
  end

  def test_category
    assert_difference Tier, :count do 
      tier = create_tier(:type => "Organization", :category => tier_categories(:government))
      assert_equal tier_categories(:government), tier.category
    end
  end
  
  def test_find_all_categories_with_organziation
    ocs = Organization.find_all_categories
    assert ocs.include?(tier_categories(:company))
    assert ocs.include?(tier_categories(:government))
    assert !ocs.include?(tier_categories(:neighborhood))
  end

  def test_find_all_categories_with_group
    ocs = Group.find_all_categories
    assert !ocs.include?(tier_categories(:company))
    assert !ocs.include?(tier_categories(:government))
    assert ocs.include?(tier_categories(:neighborhood))
  end
  
  def test_should_validate_category
    tier = build_tier(:category => nil)
    assert !tier.valid?, "should not validate"
    assert tier.errors.on(:category)
  end

  def test_should_send_registration_mail
    ActionMailer::Base.deliveries.clear
    assert_difference Tier, :count do 
      tier = Tier.create(valid_tier_attributes(:country_code => nil))
      assert tier.register!
      assert_equal 1, ActionMailer::Base.deliveries.size
    end
  end

  def test_should_send_activation_mail
    ActionMailer::Base.deliveries.clear
    assert_difference Tier, :count do 
      tier = Tier.create(valid_tier_attributes(:name => "activate_test", :country_code => nil))
      assert tier.register!
      assert tier.activate!
      assert_equal 3, ActionMailer::Base.deliveries.size
      assert ActionMailer::Base.deliveries[0].subject.match(/registered/i), "should have sent registered"
      assert ActionMailer::Base.deliveries[1].subject.match(/activated/i), "should have sent activated"
      assert ActionMailer::Base.deliveries[2].subject.match(/welcome/i), "should have sent template kase"
      tier.reload
      assert_equal 1, tier.kases.length, "should have added template kase"
    end
  end
  
  def test_should_destroy_associated_kases
    assert_difference Kontext, :count, -1 do
      assert_difference Kase, :count, -1 do 
        tier = tiers(:powerplant)
        assert_equal 1, tier.kontexts.count
        assert_equal 1, tier.all_kases.count
        tier.destroy
      end
    end
  end
  
  def test_should_find_deeply_tagged_with
    assert_difference Tier, :count do
      assert_difference Topic, :count do
        assert_difference Kase, :count do
          @tier = create_tier(:name => 'Bayerische Motorenwerke', :site_name => 'bmw', :country_code => "DE")
      
          # find by tier name
          tiers = Tier.find_deeply_tagged_with(["motorenwerke"])
          assert_equal @tier, tiers.first
      
          # find by tier tag
          @tier.tag_with(["fahrvergnügen"]) && @tier.save
          tiers = Tier.find_deeply_tagged_with(["fahrvergnügen"])
          assert_equal @tier, tiers.first
      
          # find by topic name
          @topic = create_topic(:tier => @tier, :name => "Roadster Z4", :language_code => "de")
          tiers = Tier.find_deeply_tagged_with(["roadster"])
          assert_equal @tier, tiers.first

          # find by topic tag
          @topic.tag_with(["semmeln"]) && @topic.save
          tiers = Tier.find_deeply_tagged_with(["semmeln"])
          assert_equal @tier, tiers.first
        
          # find by kase name
          @kase = create_problem(:tier => @tier, :topics => [@topic], :title => "Schmockes with the break!")
          tiers = Tier.find_deeply_tagged_with(["schmockes"])
          assert_equal @tier, tiers.first

          # find by kase tag
          @kase.tag_with(["schmarrn"]) && @kase.save
          tiers = Tier.find_deeply_tagged_with(["schmarrn"])
          assert_equal @tier, tiers.first
        end
      end
    end
  end
  
  def test_should_create_tags_with_language_code
    assert_difference Tier, :count do 
      assert_difference Tag, :count, 3 do 
        tier = create_tier(:language_code => 'es', 
          :tag_list => ["uno", "dos", "tres"])
        assert_equal "es", tier.language_code
        assert tier.tags.any? {|t| t.language_code == "es"}, "should have language code tags"
      end
    end
  end

end
