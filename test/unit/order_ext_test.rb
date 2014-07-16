require File.dirname(__FILE__) + '/../test_helper'

class OrderExtTest < ActiveSupport::TestCase

  def test_should_get_number
    assert Order.new.number
  end
  
  def test_should_get_short_number_for_order
    assert Order.new.short_number
    assert /OR-*/i.match(Order.new.short_number)
  end
  
  def test_should_get_short_number_for_purchase_order
    assert /PO-*/i.match(PurchaseOrder.new.short_number)
  end

  def test_should_get_short_number_for_sales_order
    assert /SO-*/i.match(SalesOrder.new.short_number)
  end

  def test_current_state_s
    assert_equal 'created', Order.new.current_state_s
  end

  def test_current_state_t
    assert_equal 'created', Order.new.current_state_t
  end

  def test_strip_number_formatting
    assert_equal "0c77727804f3b943bd455d61441d7d76a789e4f7",
      Order.strip_number_formatting("0c77727804-f3b943-bd455d-61441d-7d76a7-89e4f7")
  end
  
end
