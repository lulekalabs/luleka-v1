# purchase orders as purchase history
class Account::PurchaseOrdersController < Account::OrdersController

  protected
  
  def order_class
    PurchaseOrder
  end
  
  def order_association_name
    :purchase_orders
  end

end
