require File.dirname(__FILE__) + '/../test_helper'
require 'notifier'

class NotifierTest < ActiveSupport::TestCase
  FIXTURES_PATH = File.dirname(__FILE__) + '/../fixtures'
  CHARSET = "utf-8"

  include ActionMailer::Quoting

  def setup
    ActionMailer::Base.delivery_method = :test
    ActionMailer::Base.perform_deliveries = true
    ActionMailer::Base.deliveries = []

    @expected = TMail::Mail.new
    @expected.set_content_type "text", "plain", { "charset" => CHARSET }
  end

  def test_nothing
    assert true
  end

  def xtest_confirm_account
    @expected.subject = 'Notifier#confirm_account'
    @expected.body    = read_fixture('confirm_account')
    @expected.date    = Time.now

    assert_equal @expected.encoded, Notifier.create_confirm_account(@expected.date).encoded
  end


  private
    def read_fixture(action)
      IO.readlines("#{FIXTURES_PATH}/notifier/#{action}")
    end

    def encode(subject)
      quoted_printable(subject, CHARSET)
    end
end
