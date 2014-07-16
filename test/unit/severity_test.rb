require File.dirname(__FILE__) + '/../test_helper'

class SeverityTest < ActiveSupport::TestCase
  fixtures :severities

  def setup
    I18n.locale = :"en-US"
  end

  # Replace this with your real tests.
  def test_should_load
    assert severities(:trivial)
    assert severities(:minor)
    assert severities(:normal)
    assert severities(:major)
    assert severities(:critical)
  end
  
  def test_should_get_name
    assert_equal 'trivial', Severity.trivial.name
    assert_equal 'minor', Severity.minor.name
    assert_equal 'normal', Severity.normal.name
    assert_equal 'major', Severity.major.name
    assert_equal 'critical', Severity.critical.name
  end

  def test_should_get_kind
    assert_equal :trivial, Severity.trivial.kind
    assert_equal :minor, Severity.minor.kind
    assert_equal :normal, Severity.normal.kind
    assert_equal :major, Severity.major.kind
    assert_equal :critical, Severity.critical.kind
  end

  def test_get_median_id
    assert_equal 3, Severity.median_id
  end
  
end
