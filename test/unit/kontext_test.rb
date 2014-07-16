require File.dirname(__FILE__) + '/../test_helper'

class KontextTest < ActiveSupport::TestCase
  all_fixtures

  # Replace this with your real tests.
  def test_should_create_with_organization
    kontext = Kontext.create(
      :kase => create_problem(:title => 'This games does not work'),
      :tier => tier = create_organization(:name => 'Nintendo')
    )
    assert kontext.valid?
    kontext = Kontext.find_by_id(kontext.id)
    assert kontext
    assert kontext.tier
    assert_equal tier, kontext.tier
  end

  # Replace this with your real tests.
  def test_should_create_with_product
    kontext = Kontext.create(
      :kase => create_problem(:title => 'This games does not work'),
      :tier => tier = create_organization(:name => 'Nintendo'),
      :topic => topic = create_product(:name => 'Gameboy')
    )
    assert kontext.valid?
    kontext = Kontext.find_by_id(kontext.id)
    assert kontext
    assert kontext.topic
    assert_equal topic, kontext.topic
  end

  # Replace this with your real tests.
  def test_should_create_with_location
    kontext = Kontext.create(
      :kase => create_problem(:title => 'This games does not work'),
      :location => location = create_location
    )
    assert kontext.valid?
    kontext = Kontext.find_by_id(kontext.id)
    assert kontext
    assert kontext.location
    assert_equal location, kontext.location
  end

end
