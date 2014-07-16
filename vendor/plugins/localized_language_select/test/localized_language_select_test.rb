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

require File.expand_path(File.dirname(__FILE__) + "/../lib/localized_language_select")

class LocalizedLanguageSelectTest < Test::Unit::TestCase

  include ActionView::Helpers::TagHelper
  include ActionView::Helpers::FormOptionsHelper
  include ActionView::Helpers::FormTagHelper

  def test_action_view_should_include_helper_for_object
    assert ActionView::Helpers::FormBuilder.instance_methods.include?('localized_language_select')
    assert ActionView::Helpers::FormOptionsHelper.instance_methods.include?('localized_language_select')
  end

  def test_action_view_should_include_helper_tag
    assert ActionView::Helpers::FormOptionsHelper.instance_methods.include?('localized_language_select_tag')
  end

  def test_should_return_select_tag_with_proper_name_for_object
    # puts localized_language_select(:user, :country)
    assert localized_language_select(:user, :language) =~
              Regexp.new(Regexp.escape('<select id="user_language" name="user[language]">')),
              "Should have proper name for object"
  end

  def test_should_return_select_tag_with_proper_name
    # puts localized_language_select_tag( "competition_submission[data][citizenship]", nil)
    assert localized_language_select_tag( "competition_submission[data][citizenship]", nil) =~
              Regexp.new(
              Regexp.escape('<select id="competition_submission_data_citizenship" name="competition_submission[data][citizenship]">') ),
              "Should have proper name"
  end

  def test_should_return_option_tags
    assert localized_language_select(:user, :language) =~ Regexp.new(Regexp.escape('<option value="es">Spanish</option>'))
  end

  def test_should_return_localized_option_tags
    I18n.locale = 'de'
    assert localized_language_select(:user, :language) =~ Regexp.new(Regexp.escape('<option value="es">Spanisch</option>'))
  end

  def xtest_should_return_priority_countries_first
    assert localized_country_options_for_select(nil, [:es, :de]) =~ Regexp.new(
      Regexp.escape("<option value=\"es\">Spanisch</option>\n<option value=\"de\">German</option><option value=\"\" disabled=\"disabled\">-------------</option>\n<option value=\"AF\">Afghanistan</option>\n"))
  end

  def test_i18n_should_know_about_languages
    assert_equal 'Spanish', I18n.t('es', :scope => 'languages')
    I18n.locale = 'de'
    assert_equal 'Deutsch', I18n.t('de', :scope => 'languages')
  end

  def test_localized_languages_array_returns_correctly
    assert_nothing_raised { LocalizedLanguageSelect::localized_languages_array() }
    # puts LocalizedCountrySelect::localized_countries_array.inspect
    I18n.locale = 'en'
    assert_equal 185, LocalizedLanguageSelect::localized_languages_array.size
    assert_equal 'Abkhazian', LocalizedLanguageSelect::localized_languages_array.first[0]
    I18n.locale = 'de'
    assert_equal 185, LocalizedLanguageSelect::localized_languages_array.size
    assert_equal 'Abchasisch', LocalizedLanguageSelect::localized_languages_array.first[0]
  end

  def test_priority_countries_returns_correctly_and_in_correct_order
    assert_nothing_raised { LocalizedLanguageSelect::priority_languages_array([:de, :es]) }
    I18n.locale = 'en'
    assert_equal [ ['German', 'de'], ['Spanish', 'es'] ], LocalizedLanguageSelect::priority_languages_array([:de, :es])
  end

  def test_priority_languages_allows_passing_either_symbol_or_string
    I18n.locale = 'en'
    assert_equal [ ['German', 'de'], ['Spanish', 'es'] ], LocalizedLanguageSelect::priority_languages_array(['de', 'es'])
  end

  def test_priority_languages_allows_passing_upcase_or_lowercase
    I18n.locale = 'en'
    assert_equal [ ['German', 'de'], ['Spanish', 'es'] ], LocalizedLanguageSelect::priority_languages_array([:DE, :ES])
    assert_equal [ ['German', 'de'], ['Spanish', 'es'] ], LocalizedLanguageSelect::priority_languages_array(['DE', 'ES'])
  end

  def xtest_should_list_countries_with_accented_names_in_correct_order
    I18n.locale = 'cz'
    assert_match Regexp.new(Regexp.escape(%Q{<option value="BI">Burundi</option>\n<option value="TD">Čad</option>})), localized_country_select(:user, :country)
  end

  private

  def setup
    ['de', 'en', 'es'].each do |locale|
      # I18n.load_translations( File.join(File.dirname(__FILE__), '..', 'locale', "#{locale}.rb")  )  # <-- Old style! :)
      I18n.load_path += Dir[ File.join(File.dirname(__FILE__), '..', 'locale', "#{locale}.rb") ]
    end
    # I18n.locale = I18n.default_locale
    I18n.locale = 'en'
  end

end
