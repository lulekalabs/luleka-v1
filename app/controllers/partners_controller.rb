# controller handles the partner signup process
class PartnersController < FrontApplicationController
  include WizardBase
  include UsersControllerBase
  include MerchantsControllerBase
  include VouchersControllerBase

  #--- filters
  before_filter :login_required
  before_filter :load_current_user_and_person
  skip_before_filter :login_required, :only => [:new, :index, :show, :plans, :benefits, :signup]
  before_filter :load_current_cart
  before_filter :load_current_cart_or_redirect_to_default, :except => [:index, :show, :plans, :new, :create, :update, :complete, :amend, :benefits, :signup]
  before_filter :build_partner_memberships, :only => [:new, :create]
  before_filter :clear_current_order, :except => [:complete, :update]
  before_filter :select_current_partner_membership, :only => :new
  before_filter :load_current_order_or_redirect_to_default, :only => :complete
  before_filter :edit_or_redirect_to_payment, :only => :edit
  before_filter :amend_or_redirect_to_profile, :only => :amend
  before_filter :payment_or_purchase_and_pay_with_redirect_to_complete, :only => :payment
  
  #--- wizard
  wizard do |step|
    step.add :new,      "Partner Membership", :required => true, :link => true
    step.add :edit,     "Profile",    :required => true, :link => :current_cart, :display => :never_partner_before?
    step.add :payment,  "Payment",    :required => true, :link => :current_cart, :display => :cart_or_order_without_voucher?
    step.add :complete, "Complete",   :required => true, :link => true
  end

  #--- actions
  
  def index
  end
  
  def show
    render :template => 'index'
  end

  def plans
    @features = [
      ["Seek advice and share recommendations".t, true, true],
      ["Earn reputation for your online activity".t, true, true],
      ["Offer monetary rewards on concerns".t, true, true],
      ["Earn money from bonuses and rewards".t, true, true],
      ["Invite friends to join your network".t, true, true],
      ["Professional profile page".t, true, true],
      ["Add credit to your #{SERVICE_PIGGYBANK_NAME} account".t, true, true],
      ["Join organizations as employee".t, false, true],
      ["See who visits your content and profile".t, false, true],
      ["Transfer funds to your bank account".t, false, true],
      ["Start your own community".t, false, true],
      ["Earn portions of your contacts' revenues".t, false, true],
      ["Monthly membership fee".t, "free".t, "#{Money.new(495, Utility.currency_code).format}<span class=\"req\">*<span>"],
    ]
  end
  
  def new
  end
  
  def create
    if params[:partner_membership] =~ /voucher/ || current_partner_voucher
      @selected = @voucher = if params[:partner_membership] =~ /voucher/
        if found = PartnerMembershipVoucher.find_by_code_confirmation_attributes(params[:voucher] || {}, @person)
          found.validate_code_confirmation = true,
          found.consignee_confirmation = @person
          found
        else
          PartnerMembershipVoucher.new(params[:voucher] || {}) do |voucher|
            voucher.validate_code_confirmation = true,
            voucher.consignee_confirmation = @person
          end
        end
      elsif found = current_partner_voucher
        found.consignee_confirmation = @person
        found
      end
      
      if @voucher.is_a?(PartnerMembershipVoucher) && @voucher.valid?
        @voucher.consignee_and_save = current_user.person if current_user
        @user.person.cart.empty!
        @user.person.cart.add @voucher.promotable_product
        @user.person.cart.add @voucher
        self.current_cart = @cart = @user.person.cart
        self.current_voucher = @voucher
        flash[:notice] = @voucher.description
        redirect_to edit_user_partner_path
        return 
      end
      flash[:warning] = "The promotion code entered appears to be invalid.".t if @voucher.errors.empty?
    elsif @selected = Product.find_by_sku(params[:partner_membership] || '')
      @user.person.cart.empty!
      @user.person.cart.add(@selected)
      self.current_cart = @cart = @user.person.cart
      self.current_voucher = nil
      flash[:notice] = "%{product_name} added".t % {:product_name => self.current_cart.line_items.first.product.name}
      redirect_to edit_user_partner_path
      return 
    end
    render :action => 'new'
  end

  def edit
#    @person.find_or_build_business_address(@person.personal_address ? @person.personal_address.content_attributes : {})
  end

  # used when the partner signup previously failed
  def amend
    @person.find_or_build_business_address
    @person.valid?
    flash[:warning] = ["It appears that we are missing some information.".t,
      "Please review and complete your #{SERVICE_PARTNER_NAME} profile before we can activate your account.".t].to_sentences
  end

  # :put /users/<login>/
  def update
    @user.person.attributes = (params[:person] || {})
    build_billing_address(@user.person)
    
    case params[:_property]
    when /payment/, /pay/
      # check for @cart present
      redirect_to_default and return unless @cart
      
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
        @person.save
        @person.billing_address.save # if record was modified we need to explicitly save again
        
        @order, @payment = @person.purchase_and_pay(@cart, @payment_object)
        if @payment && @payment.success?
          self.current_order = @order
          self.current_cart = nil
          flash[:info] = "You have successfully purchased your subscription.".t
          redirect_to complete_user_partner_path
          return
        else
          flash[:warning] = @payment.message.humanize
        end
      end
      render :action => 'payment'
      return
    when /amend/
      if @person.valid?
        @person.save
        @person.business_address.save
        redirect_to person_path(@person)
      else
        render :action => 'amend'
      end
      return
    else
      @person.billing_address.destroy if @person.billing_address && !@person.billing_address.new_record?
      if @person.valid?
        @person.save
        @person.business_address.save
        if params[:_property] =~ /save/
          redirect_to edit_user_partner_path
          return
        else
          redirect_to payment_user_partner_path
          return
        end
      end
    end
    render :action => 'edit'
  end

  def payment
    build_billing_address(@person)
    build_payment_methods
  end
  
  # :get /users/<login>/partner/complete
  def complete
  end
  
  protected

  # overrides FrontApplicationController
  # loads the user by :id parameter, if not redirects to new (first step in wizard)
  def load_current_user_and_person
    super
    @person.registering_partner = true if @person
    @person
  end

  # just load the @cart
  def load_current_cart
    @cart = self.current_cart
  end
  
  # loads a current cart object into the cart instance variable
  # if cart is empty or it does not contain a partner membership, we
  # redirect to new
  def load_current_cart_or_redirect_to_default
    @cart ||= self.current_cart
    if !@cart || @cart.line_items.empty? || !@cart.line_items.first.product.is_partner_membership?
      redirect_to new_user_partner_path
      return false
    end
  end
  
  # removes any order that is in the session, called from before filter
  def clear_current_order
    self.current_order = nil
    true
  end
  
  # tries to load the order from session, otherwise, redirects to
  # beginning of signup process
  def load_current_order_or_redirect_to_default
    @order = self.current_order
    unless @order
      redirect_to_default
      return false
    end
    @order
  end
  
  # default redirect location in case something goes wrong
  def redirect_to_default
    redirect_to new_user_partner_path
  end

  # returns false if there is a voucher inside the cart and the cart total is zero otherwise is true
  def cart_or_order_without_voucher?
    @cart.line_items.each {|l| return false if l.product.is_a?(PartnerMembershipVoucher) && @cart.total.zero?} if @cart
    @order.line_items.each {|o| return false if o.sellable.product.is_a?(PartnerMembershipVoucher) && @order.total.zero?} if @order
    true
  end

  # returns true if this user has never signed up as partern before,
  # used to determine if the profile step is necessary?
  def never_partner_before?
    return !@user.person.ever_subscribed_as_partner? if @user && @user.person
    true
  end

  # return true or redirects to payment if the current user has
  # to complete the profile. 
  # check performed in before filter for edit action
  def edit_or_redirect_to_payment
    unless never_partner_before?
      redirect_to payment_user_partner_path
      return
    end
    true
  end

  # redirects on amend action when the partner profile is ok
  def amend_or_redirect_to_profile
    if !@person.partner? || @person.valid?
      redirect_to person_path(@person)
      return
    end
    true
  end

  # returns true if the wizard payment step is necessary, otherwise it will redirect to update action
  def payment_or_purchase_and_pay_with_redirect_to_complete
    unless cart_or_order_without_voucher?
      if @cart && @cart.total.zero?
        @order, @payment = @person.purchase_and_pay(@cart, @person.piggy_bank)
        if @payment && @payment.success?
          self.current_order = @order
          self.current_cart = nil
          self.current_voucher = nil
          flash[:info] = "You have successfully redeemed your voucher.".t
          redirect_to complete_user_partner_path
          return
        else
          flash[:warning] = @payment.message.humanize
        end
      end
    end
    true
  end

end
