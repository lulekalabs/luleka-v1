module Account::OrdersHelper

  def account_order_path(object)
    if object.is_a?(PurchaseOrder)
      account_purchase_order_path(object)
    else
      account_sales_order_path(object)
    end
  end

end
