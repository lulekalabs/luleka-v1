require File.dirname(__FILE__) + '/../test_helper'

class MoneyExtTest < ActiveSupport::TestCase
  all_fixtures
  
  def setup
    I18n.locale = :"en-US"
  end
  
  def test_should_make_absolute
    assert_equal Money.new(100, 'USD'), Money.new(-100, 'USD').abs
    assert_equal Money.new(100, 'EUR'), Money.new(-100, 'EUR').abs
    assert_equal Money.new(100, 'EUR'), Money.new(100, 'EUR').abs
  end
  
  def test_should_simply_format
    I18n.switch_locale :"en-US" do
      assert_equal "$123.45", Money.new(12345, 'USD').format
      assert_equal "123.45 €", Money.new(12345, 'EUR').format
    end
    I18n.switch_locale :"de-DE" do
      assert_equal "$123,45", Money.new(12345, 'USD').format
      assert_equal "123,45 €", Money.new(12345, 'EUR').format
    end
  end

  def test_should_format_large_amounts
    I18n.switch_locale :"en-US" do
      assert_equal "$123,456.78", Money.new(12345678, 'USD').format
      assert_equal "123,456.78 €", Money.new(12345678, 'EUR').format
    end
    I18n.switch_locale :"de-DE" do
      assert_equal "$123.456,78", Money.new(12345678, 'USD').format
      assert_equal "123.456,78 €", Money.new(12345678, 'EUR').format
    end
  end

  def test_should_strip_symbol
    I18n.switch_locale :"en-US" do
      assert_equal "123,456.78", Money.new(12345678, 'USD').format(:strip_symbol => true)
      assert_equal "123,456.78", Money.new(12345678, 'EUR').format(:strip_symbol => true)

      assert_equal "123,456.78", Money.new(12345678, 'USD').format(:unit => "")
      assert_equal "123,456.78", Money.new(12345678, 'EUR').format(:unit => "")
    end
    I18n.switch_locale :"de-DE" do
      assert_equal "123.456,78", Money.new(12345678, 'USD').format(:strip_symbol => true)
      assert_equal "123.456,78", Money.new(12345678, 'EUR').format(:strip_symbol => true)
      assert_equal "123.456,78", Money.new(12345678, 'USD').format(:unit => "")
      assert_equal "123.456,78", Money.new(12345678, 'EUR').format(:unit => "")
    end
  end

  def test_should_force_cents_with_symbol
    I18n.switch_locale :"en-US" do
      assert_equal "$123,456.00", Money.new(12345600, 'USD').format(:force_cents => true)
      assert_equal "123,456.00 €", Money.new(12345600, 'EUR').format(:force_cents => true)
    end
    I18n.switch_locale :"de-DE" do
      assert_equal "$123.456,00", Money.new(12345600, 'USD').format(:force_cents => true)
      assert_equal "123.456,00 €", Money.new(12345600, 'EUR').format(:force_cents => true)
    end
  end

  def test_should_force_cents
    I18n.switch_locale :"de-DE" do
      assert_equal "$123.456,78", Money.new(12345678, 'USD').format(:force_cents => true)
      assert_equal "$123.456,78", Money.new(12345678, 'USD').format(:force_cents => false)
      assert_equal "$123.456,00", Money.new(12345600, 'USD').format(:force_cents => false)
    end
  end
  
  def test_should_fail_with_default_globalize_currency_class
    I18n.switch_locale :"en-US" do
      assert_equal "$-14.85", Money.new(-1485, 'USD').format
    end
    I18n.switch_locale :"de-DE" do
      assert_equal "-14,85 €", Money.new(-1485, 'EUR').format
    end
  end
  
end
