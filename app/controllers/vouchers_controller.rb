# vouchers will be able to redeemed through the controller. 
class VouchersController < FrontApplicationController
  extend SessionCaptcha::ActionControllerHelpers
  include VouchersControllerBase
  include WizardBase
  
  #--- filters
  skip_before_filter :login_required
  before_filter :load_current_user_and_person
  before_filter :load_current_voucher, :only => :show
  before_filter :load_current_voucher_or_redirect, :only => [:complete, :update]
  
  #--- wizard
  wizard do |step|
    step.add :index, "Redeem", :required => true, :link => true
    step.add :complete, "Complete", :required => true, :link => false
  end
  
  #--- actions
  create_captcha_image_action
	
  def show
    @voucher.code_confirmation = @voucher.code if @voucher
  end
  
  def create
    @voucher ||= if found = Voucher.find_by_code_confirmation_attributes(params[:voucher] || {}, @person)
      found.validate_code_confirmation = true
      found.consignee_confirmation = @person
      found.validate_verification_code = !logged_in?
      found
    else
      Voucher.new((params[:voucher] || {})) do |voucher|
        voucher.validate_code_confirmation = true
        voucher.validate_verification_code = !logged_in?
      end
    end
    @voucher.verification_code_session = get_and_clear_captcha_code if !logged_in?
      
    if @voucher.valid?
      @voucher.consignee_and_save = @person if @person
      self.current_voucher = @voucher
      cookies[voucher_cookie_auth_token] = {:value => @voucher.uuid, :expires => @voucher.expires_at}
      flash[:notice] = @voucher.description
      redirect_based_on @voucher
      return 
    end
    flash[:warning] = "The promotion code entered appears to be invalid.".t if @voucher.errors.empty?
    @voucher.clear_verification_codes if !logged_in?
    render :action => 'show'
  end
  
  def complete
  end
  
  def update
    redirect_based_on(@voucher, true)
  end
  
  protected
  
  # determines where the redirection needs to take place based on the voucher
  def redirect_based_on(voucher, force=false)
    if logged_in? || force
      case voucher.kind
      when :partner_membership
        redirect_to new_user_partner_path
      else
        redirect_to complete_voucher_path
      end
    else
      redirect_to complete_voucher_path
    end
  end
  
  # loads the user by :id parameter, if not redirects to new (first step in wizard)
  def load_current_user_and_person
    @user = current_user
    @person = @user.person if @user
    true
  end
  
  # loads the current voucher if present from session
  def load_current_voucher
    @voucher = current_voucher
    true
  end
  
  # tries to load the voucher and if not found redirects to show
  def load_current_voucher_or_redirect
    unless @voucher = current_voucher
      redirect_to voucher_path
    end
  end
  
end
