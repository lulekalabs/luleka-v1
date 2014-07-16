require File.dirname(__FILE__) + '/../test_helper'

class MessageTest < ActiveSupport::TestCase
  fixtures :people, :vouchers
  

  def test_simple_instantiation
    assert message = Message.new
  end
  
  def test_should_belong_to_sender_and_receiver
    message = Message.new(:sender => people(:homer), :receiver => people(:marge))
    assert_equal people(:homer), message.sender
    assert_equal people(:marge), message.receiver
  end

  def test_should_belong_to_voucher
    message = Message.new(:voucher => vouchers(:valid))
    assert_equal vouchers(:valid), message.voucher
  end
  
end
