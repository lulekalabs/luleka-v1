# Sales orders as sales history
class Account::SalesOrdersController < Account::OrdersController

  protected
  
  def order_class
    SalesOrder
  end
  
  def order_association_name
    :sales_orders
  end

end
