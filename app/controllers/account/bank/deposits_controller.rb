# Handles all bank deposit actions
class Account::Bank::DepositsController < Account::Bank::BanksController
  include WizardBase
  include MerchantsControllerBase
  
  #--- filters
  before_filter :build_purchasing_credits, :only => [:new, :create]
  before_filter :load_current_cart_or_redirect, :only => [:edit, :update]
  before_filter :clear_current_cart, :except => [:edit, :update]
  before_filter :load_current_order_or_redirect, :only => [:complete]
  after_filter :clear_current_order, :only => [:complete]
  before_filter :find_or_build_billing_address, :only => [:edit, :update]

  #--- wizard
  wizard do |step|
    step.add :new, "Amount", :required => true, :link => true
    step.add :edit, "Payment", :required => true, :link => false
    step.add :complete, "Complete", :required => true, :link => false
  end

  #--- actions
  
  def new
  end
  
  def create
    @credits = params[:credits] || []
    @times = params[:times]
    @credits.each do |sku|
      if item = @purchasing_credits.find {|i| i.item_number == sku}
        if (quantity = @times[sku].to_i) > 0
          item.quantity = quantity
          @person.cart.add item
        end
      end
    end
    unless @person.cart.total.zero?
      self.current_cart = @person.cart
      redirect_to edit_account_bank_deposit_path
      return
    end
    flash[:warning] = "Select an amount to proceed.".t
    render :action => 'new'
  end

  def edit
    build_payment_methods
  end

  def update
    @payment_object = build_payment_method(
      params[:payment_method], params[params[:payment_method]]
    ) if params[:payment_method]

    @person.valid?
    if @payment_object
      @payment_object.valid?
    else
      flash[:error] = "Select from one of the following payment methods".t
    end
    if @cart && @person.errors.empty? && @payment_object && @payment_object.errors.empty?
      @order, @payment = @person.purchase_and_pay(@cart, @payment_object, {:ip => request.remote_ip})
      if @payment && @payment.success?
        self.current_order = @order
        self.current_cart = nil
        flash[:info] = "You have successfully purchased your credit.".t
        redirect_to complete_account_bank_deposit_path
        return
      else
        flash[:warning] = @payment.message.humanize
      end
    end
    render :action => 'edit'
  end
  
  def complete
  end

  protected
  
  def build_purchasing_credits
    @purchasing_credits ||= @person.cart.cart_line_items Product.find_available_purchasing_credits(
      :country_code => @person.default_country
    ) if @person
  end
  
  # loads the cart from session or redirects to new if not present
  def load_current_cart_or_redirect
    @cart ||= current_cart
    unless @cart
      redirect_to new_account_bank_deposit_path
      return
    end
  end
  
  # clears the cart in session and person.cart
  def clear_current_cart
    @person.cart.empty! if @person
    self.current_cart = @cart = nil
    true
  end

  # loads the current order or redirects to new
  def load_current_order_or_redirect
    @order ||= current_order
    unless @order
      redirect_to new_account_bank_deposit_path
      return
    end
  end
  
  # clears the current order from session in after_filter
  def clear_current_order
    self.current_order = @order = nil
    true
  end

  # makes sure we have a billing address
  def find_or_build_billing_address
    @person.find_or_build_billing_address if @person
    true
  end
  
end
