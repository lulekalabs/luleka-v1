module Account::InvoicesHelper
  
  def account_invoice_path(object)
    if object.is_a?(PurchaseInvoice)
      account_purchase_invoice_path(object)
    else
      account_sales_invoice_path(object)
    end
  end
  
  def formatted_account_invoice_path(object, format)
    if object.is_a?(PurchaseInvoice)
      formatted_account_purchase_invoice_path(object, format)
    else
      formatted_account_sales_invoice_path(object, format)
    end
  end
  
end
