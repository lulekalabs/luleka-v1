# Session handler for /account sub app
class Account::SessionsController < Account::AccountApplicationController
  include SessionsControllerBase

  #--- filters
  skip_before_filter :login_required, :except => :destroy
  skip_before_filter :load_current_user_and_person, :except => :destroy
  after_filter :discard_flash, :only => [:new, :create]

  #--- actions
  
  def new
    flash[:warning] = "For security reasons we kindly ask you to repeat your sign in to reduce the risk of your account being abused.".t
  end

  def create
    create_session
  end

  def destroy
    destroy_session
  end
  
  # workaround for situation where a signed up partner that may have received
  # an invitation (plus voucher) accepts the partner invitation, but will not
  # have registered with his business address, which is mandatory. In this
  # case, we will redirect the user after session signup to the partner signup
  # process again
  def after_authentication_success(user)
    if user.person.partner? && !user.person.valid? 
      redirect_to amend_user_partner_path
    end
  end
  
  protected
  
  # overrides standard user authentication to allow for login or email authentication
  def authenticate_user(login, password, options={})
    user_class.authenticate_by_login_or_email(login, password, :trace => true)
  end
  
  # override from SessionsControllerBase
  def remember_me?
    false
  end
  
end
