require 'test/unit'

require 'rubygems'
require 'active_support'
require 'action_controller'
require 'action_controller/test_process'
require 'action_view'
require 'action_view/helpers'
require 'action_view/helpers/tag_helper'
require 'i18n'

begin
  require 'redgreen'
rescue LoadError
  puts "[!] Install redgreen gem for better test output ($ sudo gem install redgreen)"
end unless ENV["TM_FILEPATH"]

require File.expand_path(File.dirname(__FILE__) + "/../lib/localized_province_select")

class LocalizedProvinceSelectTest < Test::Unit::TestCase

  include ActionView::Helpers::TagHelper
  include ActionView::Helpers::FormOptionsHelper
  include ActionView::Helpers::FormTagHelper

  def test_action_view_should_include_helper_for_object
    assert ActionView::Helpers::FormBuilder.instance_methods.include?('localized_province_select')
    assert ActionView::Helpers::FormOptionsHelper.instance_methods.include?('localized_province_select')
  end

  def test_action_view_should_include_helper_tag
    assert ActionView::Helpers::FormOptionsHelper.instance_methods.include?('localized_province_select_tag')
  end

  def test_should_return_select_tag_with_proper_name_for_object
    # puts localized_country_select(:user, :country)
    assert localized_province_select(:user, :province, :US) =~
      Regexp.new(Regexp.escape('<select id="user_province" name="user[province]">')),
        "Should have proper name for object"
  end

  def test_should_return_select_tag_with_proper_name
    assert localized_province_select_tag("competition_submission[data][citizenship]", :US, nil) =~
      Regexp.new(
        Regexp.escape('<select id="competition_submission_data_citizenship" name="competition_submission[data][citizenship]">') ),
          "Should have proper name"
  end

  def test_should_return_option_tags
    assert localized_province_select(:user, :province, :US) =~ Regexp.new(Regexp.escape('<option value="CA">California</option>'))
  end

  def test_should_return_localized_option_tags
    I18n.locale = 'de'
    assert localized_province_select(:user, :province, "DE") =~ Regexp.new(Regexp.escape('<option value="BY">Bayern</option>'))
  end

  def test_should_return_priority_provinces_first
    assert localized_province_options_for_select(:US, nil, [:CA, :OR]) =~ Regexp.new(
      Regexp.escape("<option value=\"CA\">California</option>\n<option value=\"OR\">Oregon</option><option value=\"\" disabled=\"disabled\">-------------</option>\n"))
  end

  def test_i18n_should_know_about_provinces
    assert_equal 'California', I18n.t('CA', :scope => 'provinces.US')
    I18n.locale = 'de'
    assert_equal 'Bayern', I18n.t('BY', :scope => 'provinces.DE')
  end

  def test_localized_provinces_array_returns_correctly
    assert_nothing_raised { LocalizedProvinceSelect::localized_provinces_array(:US) }

    I18n.locale = 'en'
    assert_equal 59, LocalizedProvinceSelect::localized_provinces_array(:US).size
    assert_equal 'Alabama', LocalizedProvinceSelect::localized_provinces_array(:US).first[0]
    I18n.locale = 'de'
    assert_equal 16, LocalizedProvinceSelect::localized_provinces_array(:DE).size
    assert_equal "Baden-Württemberg", LocalizedProvinceSelect::localized_provinces_array(:DE).first[0]
  end

  def test_priority_provinces_returns_correctly_and_in_correct_order
    assert_nothing_raised { LocalizedProvinceSelect::priority_provinces_array(:US, [:CA, :OR]) }
    I18n.locale = 'en'
    assert_equal [ ['California', 'CA'], ['Oregon', 'OR'] ], LocalizedProvinceSelect::priority_provinces_array(:US, [:CA, :OR])
  end

  def test_priority_provinces_allows_passing_either_symbol_or_string
    I18n.locale = 'en'
    assert_equal [ ['California', 'CA'], ['Oregon', 'OR'] ], LocalizedProvinceSelect::priority_provinces_array('US', ['CA', 'OR'])
  end

  def test_priority_provinces_allows_passing_upcase_or_lowercase
    I18n.locale = 'en'
    assert_equal [ ['California', 'CA'], ['Oregon', 'OR'] ], LocalizedProvinceSelect::priority_provinces_array('us', ['ca', 'or'])
    assert_equal [ ['California', 'CA'], ['Oregon', 'OR'] ], LocalizedProvinceSelect::priority_provinces_array(:us, [:ca, :or])
  end

  def test_should_list_provinces_with_accented_names_in_correct_order
    I18n.locale = 'de'
    assert_match Regexp.new(Regexp.escape(%Q{<option value="OR">Oregon</option>})), localized_province_select(:user, :province, :US)
  end

  private

  def setup
    ['en', 'de'].each do |locale|
      I18n.load_path += Dir[ File.join(File.dirname(__FILE__), '..', 'locale', "#{locale}.rb") ]
    end
    # I18n.locale = I18n.default_locale
    I18n.locale = 'en'
  end

end
