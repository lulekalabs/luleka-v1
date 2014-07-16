require File.dirname(__FILE__) + '/../test_helper'

class UtilityTest < ActiveSupport::TestCase
  all_fixtures
  
  def setup
  end

  def test_should_get_currency_code
    assert_equal 'EUR', Utility.currency_code('de-DE')

    I18n.switch_locale :"de-DE" do
      assert_equal 'EUR', Utility.currency_code
    end
  end

  def test_should_get_country_code
    assert_equal 'DE', Utility.country_code('de-DE')

    I18n.switch_locale 'de-DE' do
      assert_equal 'DE', Utility.country_code
    end
  end

  def test_should_get_language_code
    assert_equal 'de', Utility.language_code('de-DE')

    I18n.switch_locale 'de-DE' do
      assert_equal 'de', Utility.language_code
    end
  end

  def test_should_return_paper_format
    assert_equal 'Letter', Utility.paper_size('en-US')
    assert_equal 'A4', Utility.paper_size('de-DE')
    assert_equal 'Letter', Utility.paper_size('ZY')
  end

  def test_should_return_current_paper_format
    I18n.switch_locale :"en-US" do
      assert_equal 'Letter', Utility.paper_size
    end
    I18n.switch_locale :"de-DE" do
      assert_equal 'A4', Utility.paper_size
    end
  end
  
  def test_should_return_content_type
    assert_equal ["image/png", "image/x-png"], Utility.content_type("test.png")
    assert_equal ["image/gif"], Utility.content_type(".gif")
  end

  def test_should_not_return_content_type
    assert_nil Utility.content_type("png")
    assert_nil Utility.content_type("test.tst")
  end
  
  def test_should_return_image_content_types
    assert_equal ["image/gif", "image/png", "image/x-png", "image/jpeg", "image/pjpeg"],
      Utility.image_content_types
  end

  def test_should_uniq_extname
    assert_equal "jpg", Utility.uniq_file_extname('jpg')
    assert_equal "jpg", Utility.uniq_file_extname('test.jpeg')
    assert_equal "xls", Utility.uniq_file_extname('csv')
    assert_equal "png", Utility.uniq_file_extname('ginger.png')
  end

  def test_should_not_uniq_extname
    assert_nil Utility.uniq_file_extname('xxx')
    assert_nil Utility.uniq_file_extname(nil)
  end

  def test_should_models_to_translate
    assert models = Utility.models_to_translate
    assert_equal 13, models.size
  end

  def test_should_support_locale
    assert_equal true, Utility.supported_locale?('de-DE')
    assert_equal true, Utility.supported_locale?('us')
  end

  def test_should_not_support_locale
    assert_equal false, Utility.supported_locale?('xe-DE')
    assert_equal false, Utility.supported_locale?('xx')
  end

  def test_should_request_host_to_supported_locale
    assert_equal :"en-US", Utility.request_host_to_supported_locale("luleka.com")
    assert_equal :"de-DE", Utility.request_host_to_supported_locale("luleka.de")
  end

  def test_should_not_request_host_to_supported_locale
    assert_nil Utility.request_host_to_supported_locale("luleka.xx")
  end

  def xtest_should_request_language_to_supported_locale
    assert_equal "en-US", Utility.request_language_to_supported_locale("en-us,en;q=0.5")
    assert_equal :"de-DE", Utility.request_language_to_supported_locale("de;q=0.5")
  end

  def test_should_not_request_language_to_supported_locale
    assert_nil Utility.request_language_to_supported_locale("pt")
  end
  
end
