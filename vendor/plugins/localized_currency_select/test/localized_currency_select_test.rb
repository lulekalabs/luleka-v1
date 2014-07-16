require 'test/unit'

require 'rubygems'
require 'action_pack'
require 'active_support'
require 'active_resource'
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

require File.expand_path(File.dirname(__FILE__) + "/../lib/localized_currency_select")

class LocalizedCurrencySelectTest < Test::Unit::TestCase

  include ActionView::Helpers::TagHelper
  include ActionView::Helpers::FormOptionsHelper
  include ActionView::Helpers::FormTagHelper

  def test_action_view_should_include_helper_for_object
    assert ActionView::Helpers::FormBuilder.instance_methods.include?('localized_currency_select')
    assert ActionView::Helpers::FormOptionsHelper.instance_methods.include?('localized_currency_select')
  end

  def test_action_view_should_include_helper_tag
    assert ActionView::Helpers::FormOptionsHelper.instance_methods.include?('localized_currency_select_tag')
  end

  def test_should_return_select_tag_with_proper_name_for_object
    # puts localized_currency_select(:user, :currency)
    assert localized_currency_select(:user, :currency) =~
              Regexp.new(Regexp.escape('<select id="user_currency" name="user[currency]">')),
              "Should have proper name for object"
  end

  def test_should_return_select_tag_with_proper_name
    # puts localized_currency_select_tag( "competition_submission[data][citizenship]", nil)
    assert localized_currency_select_tag( "competition_submission[data][citizenship]", nil) =~
              Regexp.new(
              Regexp.escape('<select id="competition_submission_data_citizenship" name="competition_submission[data][citizenship]">') ),
              "Should have proper name"
  end

  def test_should_return_option_tags
    assert localized_currency_select(:user, :currency) =~ Regexp.new(Regexp.escape('<option value="EUR">Euro</option>'))
  end

  def test_should_return_localized_option_tags
    I18n.locale = 'de'
    assert localized_currency_select(:user, :currency) =~ Regexp.new(Regexp.escape('<option value="USD">US-Dollar</option>'))
  end

  def test_should_return_priority_currencies_first
    assert localized_currency_options_for_select(nil, [:EUR, :USD]) =~ Regexp.new(
      Regexp.escape("<option value=\"EUR\">Euro</option>\n<option value=\"USD\">US Dollar</option>"))
  end

  def test_i18n_should_know_about_currencies
    assert_equal 'Euro', I18n.t('EUR.name', :scope => 'currencies')
    I18n.locale = 'de'
    assert_equal 'US-Dollar', I18n.t('USD.name', :scope => 'currencies')
  end

  def test_localized_currencies_array_returns_correctly
    assert_nothing_raised { LocalizedCurrencySelect::localized_currencies_array() }
    # puts LocalizedCountrySelect::localized_countries_array.inspect
    I18n.locale = 'en'
    assert_equal 2, LocalizedCurrencySelect::localized_currencies_array.size
    assert_equal 'Euro', LocalizedCurrencySelect::localized_currencies_array.first[0]
    I18n.locale = 'de'
    assert_equal 2, LocalizedCurrencySelect::localized_currencies_array.size
    assert_equal 'Euro', LocalizedCurrencySelect::localized_currencies_array.first[0]
  end

  def test_priority_currencies_allows_passing_either_symbol_or_string
    I18n.locale = 'en'
    assert_equal [ ['Euro', 'EUR'], ['US Dollar', 'USD'] ], LocalizedCurrencySelect::priority_currencies_array(['EUR', 'USD'])
  end

  def test_priority_currencies_allows_passing_upcase_or_lowercase
    I18n.locale = 'en'
    assert_equal [ ['Euro', 'EUR'], ['US Dollar', 'USD'] ], LocalizedCurrencySelect::priority_currencies_array(['eur', 'usd'])
    assert_equal [ ['Euro', 'EUR'], ['US Dollar', 'USD'] ], LocalizedCurrencySelect::priority_currencies_array([:eur, :usd])
  end

  def test_should_list_currencies_with_accented_names_in_correct_order
    I18n.locale = 'de'
    assert_match Regexp.new(Regexp.escape(%Q{<option value="EUR">Euro</option>\n<option value="USD">US-Dollar</option>})), localized_currency_select(:user, :currency)
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
