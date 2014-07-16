# purchase invoices
class Account::PurchaseInvoicesController < Account::InvoicesController
  
  protected
  
  def invoice_class
    PurchaseInvoice
  end
  
  def invoice_association_name
    :purchase_invoices
  end
  
end
