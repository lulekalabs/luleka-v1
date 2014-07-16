# Provides functions to show the oders for an account
class Account::OrdersController < Account::AccountApplicationController
  helper 'account/accounts', 'account/invoices'
  
  #--- actions

  def index
    @orders = do_search_orders(@person.send(self.order_association_name), nil,
      :url => hash_for_account_orders_path)
    @title = order_title(order_class)
    render :template => 'account/orders/index' unless request.xhr?
  end

  # finder :include => [:invoice, {:invoice => :payments}] 
  def show
    unless @order = @person.send(self.order_association_name).find_by_number(Order.strip_number_formatting(params[:id]))
      redirect_to account_orders_path
      return
    end
    render :template => 'account/orders/show'
  end 
  
  protected
  
  def order_class
    PurchaseOrder
  end
  
  def order_association_name
    :purchase_orders
  end
  
  def do_search_orders(class_or_record=self.order_class, method=nil, options={})
    do_search(class_or_record, method, {
      :partial => 'account/orders/list_item_content',
      :url => hash_for_account_orders_path,
      :sort => {'orders.created_at' => "Date".t},
      :sort_display => true,
    }.merge(options))
  end
  
  def order_title(klass_or_name)
    if klass_or_name.is_a?(Class)
      klass_or_name == PurchaseOrder ? "Purchase History".t : "Sales History".t
    else
      klass_or_name.to_s =~ /purchase_order/ ? "Sales History".t : "Purchase History".t
    end
  end
  helper_method :order_title
  
end
