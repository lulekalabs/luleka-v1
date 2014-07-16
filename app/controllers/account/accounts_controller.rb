# Handles the actual updates to the uses account
class Account::AccountsController < Account::AccountApplicationController
  
  #--- actions

  def show
    # purchase orders
    if params[:purchase_orders]
      @purchase_orders_pages, @purchase_orders = uses_list_for(@person, :purchase_orders, :items_per_page => 5)

      # ajax
      if request.xml_http_request?
        begin
          render :partial => 'shared/orders_list_content', :locals => { :orders => @purchase_orders, :paginator => @purchase_orders_pages, :html_id => params[:html_id], :html_message_id => params[:html_message_id] }
        rescue ActiveRecord::RecordInvalid => ex
          render :text => form_error_messages_for(:purchase_orders), :status => 444
        rescue Exception => ex
          flash[:error] = "There were unexpected errors.".t
          render :text => form_flash_messages, :status => 444
        end
        return
      end
    end
    
    # sales_orders
    if params[:sales_orders]
      @sales_orders_pages, @sales_orders = uses_list_for(@person, :sales_orders, :items_per_page => 5)
      # ajax
      if request.xml_http_request?
        begin
          render :partial => 'shared/orders_list_content', :locals => { :orders => @sales_orders, :paginator => @sales_orders_pages, :html_id => params[:html_id], :html_message_id => params[:html_message_id] }
        rescue ActiveRecord::RecordInvalid => ex
          render :text => form_error_messages_for(:sales_orders), :status => 444
        rescue Exception => ex
          flash[:error] = "There were unexpected errors.".t
          render :text => form_flash_messages, :status => 444
        end
        return
      end
    end
  end

  # sidebar statistics
  def statistics
    if request.xhr?
      render :partial => 'sidebar_statistics', :object => @person
    else
      render :nothing => true
    end
  end
  
  # disconnect facebook account
  def unlink_fb_connect
    @user.unlink_fb_connect
    flash[:notice] = "You have successfully disconnected Facebook from your account.".t
    redirect_to account_path
    return
  end
  
end
