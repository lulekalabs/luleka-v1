# manages all user's addresses
class Account::AddressesController < Account::AccountApplicationController
  
  #--- constants
  MESSAGE_SUCCESS = "Your address was successfully updated"

  #--- filters
  before_filter :if_partner_or_redirect, :only => :business
  
  #--- actions
  
  def show
    @personal_address = @person.personal_address
    @business_address = @person.find_or_build_business_address
    @billing_address = @person.find_or_build_billing_address
  end
  
  def update
    case params[:_property].to_s
    when /personal/, /personal_address/
      @person.attributes = params[:address]
      unless (@address = @person.personal_address).save
        render :action => 'personal'
        return
      end
    when /business/, /business_address/
      @person.attributes = params[:address]
      unless (@address = @person.business_address).save
        render :action => 'business'
        return
      end
    when /billing/, /billing_address/
      @person.attributes = params[:address]
      unless (@address = @person.billing_address).save
        render :action => 'billing'
        return
      end
    end
    flash[:notice] = MESSAGE_SUCCESS
    redirect_to account_path
  end
  
  def personal
    @address = @person.find_or_build_personal_address
  end
  
  def business
    @address = @person.find_or_build_business_address
  end
  
  def billing
    @address = @person.find_or_build_billing_address
  end

  protected
  
  def if_partner_or_redirect
    if @person && !@person.partner?
      redirect_to account_address_path
      return
    end
    true
  end
  
end
