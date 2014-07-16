require File.dirname(__FILE__) + '/../test_helper'

class TaxRateTest < ActiveSupport::TestCase
  fixtures :tax_rates

  def test_should_find_tax_for_country_and_state
    tr = TaxRate.find_tax_rate(
      :origin => valid_address_attributes,
      :destination => valid_address_attributes(
        :country_code => "us",
        :province_code => "or"
      )
    )
    assert_equal 8.5, tr
  end

  def test_should_find_tax_for_country_and_wildcard
    tr = TaxRate.find_tax_rate(
      :origin => valid_address_attributes,
      :destination => valid_address_attributes(
        :country_code => "de",
        :province_code => "by"
      )
    )
    assert_equal 19.0, tr
  end

  def test_should_find_tax_for_country_and_state_list
    tr = TaxRate.find_tax_rate(
      :origin => valid_address_attributes,
      :destination => valid_address_attributes(
        :country_code => "us",
        :province_code => "ny"
      )
    )
    assert_equal 8.25, tr
  end

  def test_should_not_find_tax
    tr = TaxRate.find_tax_rate(
      :origin => valid_address_attributes,
      :destination => valid_address_attributes(
        :country_code => "us",
        :province_code => nil
      )
    )
    assert_equal 0.0, tr
  end

  def test_should_not_find_tax_for_country_and_state_list
    tr = TaxRate.find_tax_rate(
      :origin => valid_address_attributes,
      :destination => valid_address_attributes(
        :country_code => "us",
        :province_code => "tx"
      )
    )
    assert_equal 0.0, tr
  end
  
end
