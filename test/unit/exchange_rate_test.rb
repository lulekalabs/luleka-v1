require File.dirname(__FILE__) + '/../test_helper'

class ExchangeRateTest < ActiveSupport::TestCase
  all_fixtures
  
  def setup
    I18n.locale = :"en-US"
    ExchangeRate.setup_money_bank
  end

  def test_should_get_from_euro_to_usd
    assert_equal 1.3448, ExchangeRate.get("EUR", "USD")
    assert_equal 1.3448, ExchangeRate.get("eur", "usd")
  end

  def test_should_get_from_usd_to_eur
    assert_equal 0.74360499702558, ExchangeRate.get("USD", "EUR")
    assert_equal 0.74360499702558, ExchangeRate.get("usd", "eur")
  end

  def test_should_get_from_usd_to_gbp
    assert_equal 0.639500297441999.to_s, ExchangeRate.get("USD", "GBP").to_s
    assert_equal 0.639500297441999.to_s, ExchangeRate.get("usd", "gbp").to_s
  end

  def test_should_get_from_gbp_to_usd
    assert_equal 1.56372093023256.to_s, ExchangeRate.get("GBP", "USD").to_s
    assert_equal 1.56372093023256.to_s, ExchangeRate.get("gbp", "usd").to_s
  end
  
  def xtest_money_bank
    assert_equal Money.new(234, "USD"), Money.new(100, "USD") + Money.new(100, "EUR")
    assert_equal Money.new(174, "EUR"), Money.new(100, "EUR") + Money.new(100, "USD")
  end

end
