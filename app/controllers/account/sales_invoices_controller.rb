# sales invoices
class Account::SalesInvoicesController < Account::InvoicesController

  protected
  
  def invoice_class
    SalesInvoice
  end
  
  def invoice_association_name
    :sales_invoices
  end
end
