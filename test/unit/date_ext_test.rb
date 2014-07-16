require File.dirname(__FILE__) + '/../test_helper'

class DateExtTest < ActiveSupport::TestCase

  def setup
  end

  def test_to_s
    I18n.switch_locale :"en-US" do
      assert_equal "2005-02-21", Date.new(2005, 2, 21).to_s
      assert_equal "Feb 21", Date.new(2005, 2, 21).to_s(:short)
      assert_equal "February 21, 2005", Date.new(2005, 2, 21).to_s(:long)
      assert_equal "Monday, February 21, 2005", Date.new(2005, 2, 21).to_s(:full)
      assert_equal "02/21/05", Date.new(2005, 2, 21).to_s(:numeric)
      assert_equal "2005-02-21", Date.new(2005, 2, 21).to_s(:schmarrn)
    end
    I18n.switch_locale :"de-DE" do
      assert_equal "2005-02-21", Date.new(2005, 2, 21).to_s
      assert_equal "21. Feb", Date.new(2005, 2, 21).to_s(:short)
      assert_equal "21. Februar 2005", Date.new(2005, 2, 21).to_s(:long)
      assert_equal "Montag, 21. Februar 2005", Date.new(2005, 2, 21).to_s(:full)
      assert_equal "21.02.05", Date.new(2005, 2, 21).to_s(:numeric)
      assert_equal "2005-02-21", Date.new(2005, 2, 21).to_s(:schmarrn)
    end
  end

  def test_date_format_array
    I18n.switch_locale :"en-US" do
      assert_equal [:month, :day, :year], Date.format_array
    end
    I18n.switch_locale "de-DE" do
      assert_equal [:day, :month, :year], Date.format_array
    end
  end
  
end
