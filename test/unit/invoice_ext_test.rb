require File.dirname(__FILE__) + '/../test_helper'

class InvoiceExtTest < ActiveSupport::TestCase
  all_fixtures

  def setup
  end

  def test_should_get_number
    assert Invoice.new.number
  end
  
  def test_should_get_short_number_for_invoice
    assert Invoice.new.short_number
    assert_equal 10, Invoice.new.short_number.length
    assert /IN-*/i.match(Invoice.new.short_number)
  end
  
  def test_should_get_short_number_for_purchase_invoice
    assert /PI-*/i.match(PurchaseInvoice.new.short_number)
  end

  def test_should_get_short_number_for_sales_order
    assert /SI-*/i.match(SalesInvoice.new.short_number)
  end

  def test_current_state_s
    assert_equal 'pending', Invoice.new.current_state_s
  end

  def test_current_state_t
    assert_equal 'pending', Invoice.new.current_state_t
  end
  
  def test_strip_number_formatting
    assert_equal "0c77727804f3b943bd455d61441d7d76a789e4f7",
      Invoice.strip_number_formatting("0c77727804-f3b943-bd455d-61441d-7d76a7-89e4f7")
  end
  
  def test_should_have_default_seller
    invoice = PurchaseInvoice.new
    assert invoice.seller
    assert_equal 'Luleka', invoice.seller.name
  end

  def test_should_have_default_origin_address
    invoice = PurchaseInvoice.new
    assert invoice.origin_address
    assert_equal "100 Rousseau St, San Francisco, California, 94112, United States", invoice.origin_address.to_s
  end

  def test_should_generate_pdf_file
    invoice = create_invoice
    invoice.to_pdf
  end
    
  protected
  
  def create_invoice
    person = people(:homer)
    person.piggy_bank.direct_deposit(Money.new(10000, 'USD'))
    order, payment = person.purchase_and_pay(topics(:three_month_partner_membership_en), person.piggy_bank)
    assert payment.success?
    order.invoice
  end
  
end
