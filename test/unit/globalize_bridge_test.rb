require File.dirname(__FILE__) + '/../test_helper'

class GlobalizeBridgeTest < ActiveSupport::TestCase
  all_fixtures

  def setup
    #I18n.cache_store = ActiveSupport::Cache.lookup_store(:memory_store)
    I18n.locale = :"en-US"
    I18n.switch_locale :"en-US" do
      "once upon a time in germany".t
    end
  end
  
  def test_should_create_translation_entry
    I18n.switch_locale :"en-US" do
      assert_difference Translation, :count, 1 do 
        "once upon a time in america".t
        "once upon a time in america".t
      end
      assert_equal "once upon a time in america", Translation.last.raw_key
      assert_equal "once upon a time in america", Translation.last.value
    end
  end

  def test_should_create_new_german_translation_entry_with_empty_value
    I18n.switch_locale :"de-DE" do
      assert_difference Translation, :count, 1 do 
        "once upon a time in germany".t
        "once upon a time in germany".t
      end
      assert_equal "once upon a time in germany", Translation.last.raw_key
      assert_equal nil, Translation.last.value  # because it needs to be translated
    end
  end
  
  def test_should_not_create_translation_entry_on_reserved_keywords
    I18n.switch_locale :"en-US" do
      assert_no_difference Translation, :count do 
        "activerecord.whatever".t
      end
    end
  end
  
  def test_should_fallback_with_database_simple
    t = Translation.create(:key => "We should fallback", :value => "Wir sollten jetzt zurückfallen", 
      :pluralization_index => 1, :locale => Locale.find_by_code("de"))
    
    I18n.switch_locale :"de-DE" do
      assert_equal "Wir sollten jetzt zurückfallen", "We should fallback".t
    end
  end

  def test_should_fallback_with_database_complex
    assert_difference Translation, :count, 2 do
      t1 = Translation.create(:key => "Seek advice?", :value => "Buscar consejo?", 
        :pluralization_index => 1, :locale => Locale.find_by_code("es-CL"))
      t2 = Translation.create(:key => "Seek advice?", :value => "Buscar asesoramiento?", 
        :pluralization_index => 1, :locale => Locale.find_by_code("es"))

      # Spanish
      I18n.switch_locale :"es-CL" do
        assert_equal "Buscar consejo?", "Seek advice?".t
      end

      # Spanish - Chile
      I18n.switch_locale :"es" do
        assert_equal "Buscar asesoramiento?", "Seek advice?".t
      end

      # Spanish - Argentina
      I18n.switch_locale :"es-AR" do
        assert_equal "Buscar asesoramiento?", "Seek advice?".t
      end

      # Spanish - Argentina
      I18n.switch_locale :"es-ES" do
        assert_equal "Buscar asesoramiento?", "Seek advice?".t
      end
    end
  end

  def test_should_sweep_cache
    t1 = Translation.create(:key => "Seek advice?", :value => "Buscar asesoramiento?", 
      :pluralization_index => 1, :locale => Locale.find_by_code("es"))

    # Spanish - Argentina
    I18n.switch_locale :"es-AR" do
      assert_equal "Buscar asesoramiento?", "Seek advice?".t
    end
    
    t1.update_attributes(:value => "Buscar consejo?")
    t1 = Translation.find_by_id(t1.id)
    assert_equal "Buscar consejo?", t1.value

    # Español -> after change!
    I18n.switch_locale :"es" do
      assert_equal "Buscar consejo?", "Seek advice?".t
    end

    # Spanish - Argentina -> after change!
    I18n.switch_locale :"es-AR" do
      assert_equal "Buscar consejo?", "Seek advice?".t
    end
  end
  
  def test_should_fallback_with_empty_translation
    assert_difference Translation, :count, 3 do
      t1 = Translation.create(:key => "happyness", :value => "felicidad", 
        :pluralization_index => 1, :locale => Locale.find_by_code("es-AR"))
      t1 = Translation.create(:key => "happyness", :value => "felicidad", 
        :pluralization_index => 1, :locale => Locale.find_by_code("es"))
      t1 = Translation.create(:key => "happyness", :value => nil, 
        :pluralization_index => 1, :locale => Locale.find_by_code("es-ES"))

      # Spanish - Spain
      I18n.switch_locale :"es-ES" do
        assert_equal "felicidad", "happyness".t
      end
      
      # Spanish
      I18n.switch_locale :"es" do
        assert_equal "felicidad", "happyness".t
      end

    end
  end
  
  
end
