# Hanldes all /account/invoices such as PurchaseInvoice and SalesInvoice
class Account::InvoicesController < Account::AccountApplicationController
  helper 'account/accounts'
  
  #--- actions
  
  def index
    @invoices = do_search_invoices(@person.send(self.invoice_association_name), nil, 
      :url => hash_for_account_purchase_invoices_path)
    @title = invoice_class.human_name(:count => 2).titleize
    render :template => 'account/invoices/index' unless request.xhr?
  end
  
  def show
    unless @invoice = @person.send(self.invoice_association_name).find_by_number(
        Invoice.strip_number_formatting(params[:id]))
      redirect_to account_invoices_path
      return
    end
    respond_to do |format|
      format.html {render :template => 'account/invoices/show'}
      format.pdf do 
        @invoice.service_url = @invoice.seller.is_a?(Organization) ? new_organization_kase_url(@invoice.seller) : new_kase_url
        send_data @invoice.to_pdf,
          :filename => 'products.pdf', :type => 'application/pdf', :disposition => 'inline'
      end
    end
  end

  protected
  
  def invoice_class
    PurchaseInvoice
  end
  
  def invoice_association_name
    :purchase_invoices
  end
  
  def do_search_invoices(class_or_record=self.invoice_class, method=nil, options={})
    do_search(class_or_record, method, {
      :partial => 'account/orders/list_item_content',
      :url => hash_for_account_invoices_path,
      :sort => {'invoices.created_at' => "Date".t},
      :sort_display => true
    }.merge(options))
  end
  
end
