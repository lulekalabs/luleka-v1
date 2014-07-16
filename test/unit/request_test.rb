require File.dirname(__FILE__) + '/../test_helper'

class RequestTest < ActiveSupport::TestCase
  fixtures :people, :vouchers

  def test_simple_instantiation
    assert request = Request.new
    assert request.is_a?(Message)
  end
  
  def test_should_belong_to_sender_and_receiver
    request = Request.new(:sender => people(:homer), :receiver => people(:marge))
    assert_equal people(:homer), request.sender
    assert_equal people(:marge), request.receiver
  end

  def test_should_belong_to_voucher
    request = Request.new(:voucher => vouchers(:valid))
    assert_equal vouchers(:valid), request.voucher
  end
  
end
