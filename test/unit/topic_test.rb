require File.dirname(__FILE__) + '/../test_helper'

class TopicTest < ActiveSupport::TestCase
  ROOT = File.join(File.dirname(__FILE__), '..')
  all_fixtures

  def setup
    I18n.locale = :"en-US"
    GeoKit::Geocoders::MultiGeocoder.stubs(:geocode).returns(valid_geo_location)
    # create slugs
    Tier.all.each {|r| r.save(:validate => false)}
    Topic.all.each {|r| r.save(:validate => false)}
  end

  def test_should_instantiate
    topic = Topic.new
    assert topic.is_a?(Topic)
    assert_equal :topic, topic.kind
  end

  def test_should_instantiate_product
    product = Product.new
    assert product.is_a?(Product)
    assert product.is_a?(Topic)
    assert_equal :product, product.kind

    product = Topic.new :type => :product
    assert product.is_a?(Product)
    assert product.is_a?(Topic)
    assert_equal :product, product.kind

    product = Topic.new :type => 'Product'
    assert product.is_a?(Product)
    assert product.is_a?(Topic)
    assert_equal :product, product.kind

    product = Topic.new :type => Product
    assert product.is_a?(Product)
    assert product.is_a?(Topic)
    assert_equal :product, product.kind
  end

  def test_should_instantiate_service
    service = Service.new
    assert service.is_a?(Service)
    assert service.is_a?(Product)
    assert service.is_a?(Topic)
    assert_equal :service, service.kind

    service = Topic.new :type => :service
    assert service.is_a?(Service)
    assert service.is_a?(Product)
    assert service.is_a?(Topic)
    assert_equal :service, service.kind

    service = Topic.new :type => 'Service'
    assert service.is_a?(Service)
    assert service.is_a?(Product)
    assert service.is_a?(Topic)
    assert_equal :service, service.kind

    service = Topic.new :type => Service
    assert service.is_a?(Service)
    assert service.is_a?(Product)
    assert service.is_a?(Topic)
    assert_equal :service, service.kind
  end
  
  def test_should_validate_uniqueness_of_name
    assert_difference Topic, :count, 3 do 
      assert topic_en_US = create_topic(:language_code => 'en', :country_code => 'US')
      assert topic_en_US.valid?, "topic should be valid"

      assert topic_de_DE = build_topic(:language_code => 'de', :country_code => 'DE')
      assert topic_de_DE.valid?, "topic should validate same name in de region"
      assert topic_de_DE.save, "should save topic with same name in de region"

      assert topic_ww = build_topic(:language_code => nil, :country_code => nil)
      assert topic_ww.valid?, "topic should validate same name world wide"
      assert topic_ww.save, "should save topic with same name world wide"
    end
  end

  def test_should_not_validate_uniqueness_of_name
      assert topic_a = create_topic(:language_code => 'en', :country_code => 'US')
      assert topic_a.valid?, "topic should be valid"

      assert topic_b = build_topic(:language_code => 'en', :country_code => 'US')
      assert !topic_b.valid?, "topic should not be valid due to duplicate name in same region"
      assert topic_b.errors.on(:name), "topic should not be valid due to duplicate name in same region"
  end

  def test_should_attach_image
    topic = build_topic
    topic.image = File.new(File.join(ROOT, "fixtures", "files", "beetle_48kb.jpg"), 'rb')
    assert topic.save, "should save"
    assert topic.image.file?,"should have file attached"
    assert topic.image(:thumb).match("thumb_beetle_48kb.jpg"), "should attach thumb"
    assert topic.image(:profile).match("profile_beetle_48kb.jpg"), "should attach profile"
    assert topic.image(:portrait).match("portrait_beetle_48kb.jpg"), "should attach portrait"
  end

  def test_should_not_validate_image_size
    topic = build_topic
    topic.image = File.new(File.join(ROOT, "fixtures", "files", "beetle_296kb.jpg"), 'rb')
    assert !topic.valid?, "should not validate file size"
    assert_equal "exceeds 256KB image size", topic.errors.on(:image)
  end

  def test_should_not_validate_image_file_type
    topic = build_topic
    topic.image = File.new(File.join(ROOT, "fixtures", "files", "beetle_228kb.bmp"), 'rb')
    assert !topic.valid?, "should not validate file size"
    assert_equal "GIF, PNG, JPG, and JPEG files only", topic.errors.on(:image)
  end

  def test_should_self_and_subclasses
    assert_equal [Topic, Product, Service].to_set, Topic.self_and_subclasses.to_set
  end

  def test_should_self_and_subkinds
    assert_equal [:topic, :product, :service].to_set, Topic.self_and_subkinds.to_set
  end

  def test_subclass_param_ids
    assert_equal [:product_id, :service_id].to_set, Topic.subclass_param_ids.to_set
    assert_equal [:service_id].to_set, Product.subclass_param_ids.to_set
    assert_equal [].to_set, Service.subclass_param_ids.to_set
  end

  def test_self_and_subclass_param_ids
    assert_equal [:topic_id, :product_id, :service_id].to_set, Topic.self_and_subclass_param_ids.to_set
    assert_equal [:product_id, :service_id].to_set, Product.self_and_subclass_param_ids.to_set
    assert_equal [:service_id].to_set, Service.self_and_subclass_param_ids.to_set
  end
  
  def test_should_find_featured
    topic = topics(:electricity)
    topic.update_attributes(:featured => true)
    topic.reload
    assert_equal [topic], Topic.find_featured('US')
  end
  
  def test_should_get_and_set_country_code
    topic = build_topic(:country_code => 'us')
    assert_equal "US", topic.country_code
    topic.country_code = nil
    assert_nil topic.country_code, 'country_code should be nil now'
  end

  def test_should_get_and_set_language_code
    topic = build_topic(:language_code => 'DE')
    assert_equal "de", topic.language_code
    topic.language_code = nil
    assert_nil topic.language_code, 'language_code should be nil now'
  end
  
  def test_should_localize_name
    assert_equal ["name", "name_de", "name_es"].to_set, Topic.localized_facets(:name).to_set
  end

  def test_should_localize_description
    assert_equal ["description", "description_de", "description_es"].to_set, Topic.localized_facets(:description).to_set
  end

  def test_should_have_kases_count_column
    assert_equal true, Topic.kases_count_column?
  end

  def test_should_have_kases_count
    assert_equal 0, topics(:nut).kases_count
  end

  def test_should_update_kases_count
    assert_equal 0, topics(:nut).update_kases_count
  end
  
  def test_should_kase_topics_count
    assert_difference Topic, :count do
      tier = tiers(:powerplant)
      topic = create_topic(:tier => tier)
      assert topic.register!
      assert topic.activate!
      assert_equal :active, topic.current_state
      assert_equal 1, tier.topics_count
      topic.suspend!
      assert_equal 0, tier.topics_count
    end
  end

  def test_should_find_by_permalink
      pp = tiers(:powerplant)
      ll = tiers(:luleka)
      pp_t = create_topic(:tier => pp, :name => "Atomium")
      ll_t = create_topic(:tier => ll, :name => "Atomium")
      assert pp_t.register!
      assert pp_t.activate!
      assert ll_t.register!
      assert ll_t.activate!
      
      assert "atomium", pp_t.permalink
      assert "atomium", ll_t.permalink
      
      found = pp.topics.find_by_permalink_and_region_and_active("atomium")
      assert_equal pp_t, found, "should find topic by permalink" 
      assert_equal true, found.friendly_id_status.best?, "should find the best match"
      
      pp_t.name = "palace"
      assert_equal true, pp_t.save, "should save"
      assert_equal "palace", pp_t.permalink
      
      found_new = pp.topics.find_by_permalink_and_region_and_active("palace")
      assert_equal pp_t, found_new, "should find topic by new permalink" 
      assert_equal true, found_new.friendly_id_status.best?, "should find the best match"

      found_old = pp.topics.find_by_permalink_and_region_and_active("atomium")
      assert_equal pp_t, found_old, "should find topic by old permalink" 
      assert_equal false, found_old.friendly_id_status.best?, "should not be best match"
  end
  
  def test_should_validate_invalid_site_names
    topic = build_topic(:name => "Faq")
    assert_equal false, topic.valid?
    assert topic.errors.on(:name), "topic with faq should not be valid"

    topic = build_topic(:name => "WWW")
    assert_equal false, topic.valid?
    assert topic.errors.on(:name), "topic with faq should not be valid"
  end
  
  def test_should_normalize_permalink
    I18n.switch_locale :"en-US" do
      t1 = create_topic(:name => 'Jürgen Feßlmeier', :country_code => "DE", :language_code => "de")
      assert_equal "juergen-fesslmeier", t1.permalink
    end

    I18n.switch_locale :"de-DE" do
      t3 = create_topic(:name => 'Jürgen Feßlmeier', :country_code => "US", :language_code => "en")
      assert_equal "jurgen-fesslmeier", t3.permalink
    end
  end

  def test_should_create_tags_with_language_code
    assert_difference Topic, :count do 
      assert_difference Tag, :count, 3 do 
        topic = create_topic(:language_code => 'es', 
          :tag_list => ["uno", "dos", "tres"])
        assert_equal "es", topic.language_code
        assert topic.tags.any? {|t| t.language_code == "es"}, "should have language code tags"
      end
    end
  end

end
