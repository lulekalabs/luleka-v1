require File.dirname(__FILE__) + '/../test_helper'

class EmailTest < ActiveSupport::TestCase
  all_fixtures
  
  def test_simple_email
    email = Email.new(valid_email_attributes)
    assert email.valid?, "simple email should be valid"
  end

  def test_should_validate_subject_and_message
    email = Email.new(valid_email_attributes({:subject => "", :message => ""}))
    assert !email.valid?, "email should not be valid without subject and message"
    assert email.errors.on(:subject), "should validate subject"
  end

  def test_should_validate_sender_and_receiver
    email = Email.new(valid_email_attributes({:sender_name => "", :sender_email => "", :receiver_email => ""}))
    assert !email.valid?, "email should not be valid without sender and receiver"
    assert email.errors.on(:sender_name), "should validate sender_name"
    assert email.errors.on(:sender_email), "should validate sender email"
    assert email.errors.on(:receiver_email), "should validate receiver email"
  end

  def test_should_not_validate_email_address
    email = Email.new(valid_email_attributes(:receiver_email => "invalid@email"))
    assert !email.valid?, "invalid email address"
  end

  def test_should_not_validate_email_addresses
    email = Email.new(valid_email_attributes(:receiver_email => "valid@email.tst, invalid@email"))
    assert ["valid@email.tst", "invalid@email"], email.to_email_a
    assert !email.valid?, "invalid email addresses"
  end

  def test_from
    email = Email.new(valid_email_attributes)
    assert_equal "Terry Simpson <terry@simpson.tst>", email.from
  end

  def test_from_with_person
    email = Email.new(valid_email_attributes(:sender => people(:bart)))
    assert_equal "Bart Simpson <bart@simpson.tt>", email.from
  end

  def test_to_and_to_email
    email = Email.new(valid_email_attributes)
    assert_equal "barney@simpson.tst", email.to
    assert_equal "barney@simpson.tst", email.to_email
  end

  def test_to_and_to_email_with_person
    email = Email.new(valid_email_attributes(:receiver => people(:homer)))
    assert_equal "Homer Simpson <homer@simpson.tt>", email.to
    assert_equal "homer@simpson.tt", email.to_email
  end

  def test_to_a
    email = Email.new(valid_email_attributes(:receiver_email => "adam@test.tst, Eve <eve@test.tst>"))
    assert_equal ["adam@test.tst", "Eve <eve@test.tst>"], email.to_a
  end

  def test_should_uniq_to_a
    email = Email.new(valid_email_attributes(:receiver_email => "Eve <eve@test.tst>, Eve <eve@test.tst>"))
    assert_equal ["Eve <eve@test.tst>"], email.to_a
  end

  def test_to_email_a
    email = Email.new(valid_email_attributes(:receiver_email => "adam@test.tst, eve@test.tst"))
    assert_equal ["adam@test.tst", "eve@test.tst"], email.to_email_a
  end

  def test_should_uniq_to_email_a
    email = Email.new(valid_email_attributes(:receiver_email => "adam@test.tst, adam@test.tst"))
    assert_equal ["adam@test.tst"], email.to_email_a
  end

  def test_should_deliver_email_kase
    email = EmailKase.new(valid_email_attributes(:subject => nil, :kase => kases(:powerplant_leak)))
    assert "Terry Simpson wants to know what you think", email.subject
    assert email.valid?, 'email kase should be valid'
    email.deliver
    
    assert_equal 1, ActionMailer::Base.deliveries.size
    assert_equal "Terry Simpson wants to know what you think", ActionMailer::Base.deliveries.last.subject
  end
  
  protected
  
  def valid_email_attributes(options={})
    {
      :sender_name => "Terry Simpson",
      :sender_email => "terry@simpson.tst",
      :receiver_email => "barney@simpson.tst",
      :message => "Test message",
      :subject => "Test subject",
      :verification_code => 'want2test',
      :verification_code_session => 'want2test'
    }.merge(options)
  end
  
end
