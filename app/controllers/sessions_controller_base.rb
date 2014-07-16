# all methods that are shared between front application sessions in 
# front application and account application
module SessionsControllerBase
  def self.included(controller)
    controller.send :helper_method, :remember_me?, :session_form_dom_id, :session_dom_id, 
      :encryption_required?, :logged_in_recently?
    controller.extend(ClassMethods)
    controller.send :alias_method_chain, :ssl_required?, :supported
    controller.before_filter :set_ssl_public_key_in_session
  end
  
  module ClassMethods
  end
  
  protected

  #--- constants
  MESSAGE_LOGIN_ERROR    = "Sorry, your username/email and password did not match"
  MESSAGE_LOGIN_SUCCESS  = "Sign in successful"
  MESSAGE_LOGOUT_SUCCESS = "You have been signed out"
  
  #--- helpers

  # dom id of the submit form
  def session_form_dom_id(postfix=nil)
    dom_class(User, postfix ? "session_form_#{postfix}" : "session_form")
  end
  
  # dom id of the container that needs Ajax replacing in create_session
  def session_dom_id
    'contentColumnModal'
  end
  
  # intercept ssl_supported? from ssl_requirement
  def ssl_required_with_supported?
    ssl_supported? ? ssl_required_without_supported? : false
  end

  # called from session/create to initiate the session
  def create_session
    login, password = get_login_and_password
    create_session_with authenticate_user(login, password, :trace => true)
  end
  
  # created a session from params but does not render, returns user if successful
  def create_session_without_render(login_content=nil, password_content=nil, encrypted_password_content=nil)
    login, password = get_login_and_password(login_content, password_content, encrypted_password_content)
    create_session_without_render_with authenticate_user(login, password, :trace => true) # if !login.blank? && !password.blank?
  end

  # creates user session without rendering anything
  def create_session_without_render_with(user)
    @logged_in_recently = false
    self.current_user = user

    # store remember me in token
    if logged_in?
      @logged_in_recently = true
      if params[:user][:remember_me] == "1"
        current_user.remember_me unless current_user.remember_token?
        cookies[cookie_auth_token] = {
          :value => self.current_user.remember_token, :expires => self.current_user.remember_token_expires_at
        }
      end
      
      # callback :after_authentication_success
      self.send(:after_authentication_success, self.current_user) if self.respond_to?(:after_authentication_success)

      flash[:notice] = MESSAGE_LOGIN_SUCCESS.t
    else
      flash[:error] = MESSAGE_LOGIN_ERROR.t
    end
    return self.current_user
  end

  # called from session/create to initiate the session and render
  def create_session_with(user)
    @logged_in_recently = false
    self.current_user = user
    
    # store remember me in token
    if logged_in?
      @logged_in_recently = true
      if params[:user][:remember_me] == "1"
        current_user.remember_me unless current_user.remember_token?
        cookies[cookie_auth_token] = {
          :value => self.current_user.remember_token, :expires => self.current_user.remember_token_expires_at
        }
      end
      
      # callback :after_authentication_success
      self.send(:after_authentication_success, self.current_user) if self.respond_to?(:after_authentication_success)
      
      if !performed? && request.xhr?
        if return_to_url
          flash[:xhr_redirect] = true
          @return_to_url = return_to_url
          session[return_to_param] = nil
        end
        render :update do |page|
          page << close_modal_javascript
          page.replace status_dom_id, :partial => 'layouts/front/status_navigation'
          page << "document.fire('authentication:success')"
          page << "document.fire('authentication:complete')"
          page.redirect_to @return_to_url if @return_to_url
        end
      elsif !performed?
        flash[:notice] = MESSAGE_LOGIN_SUCCESS.t
        redirect_back_or_default('/')
      end
    else
      flash[:error] = MESSAGE_LOGIN_ERROR.t
      if request.xhr?
        render :update do |page|
          page.replace session_dom_id, :partial => 'new'
          page << "document.fire('authentication:failure')"
          page << "document.fire('authentication:complete')"
        end
      else
        render :action => 'new'
      end
    end
  end
  
  # called from session/destroy to tear down the user session
  def destroy_session(default_location=nil)
    redirect_url = return_to_previous_url

    # facebooker?
    if current_user.respond_to?(:facebook_user?) && current_user.facebook_user?
      clear_fb_cookies!
      clear_facebook_session_information
    end

    self.current_user.forget_me if logged_in?
    reset_session
    cookies.delete cookie_auth_token, :domain => Utility.site_domain
    redirect_to redirect_url || default_location || '/'
  end

  def change_locale
    session[:locale] = params[:locale] unless params[:locale].blank?
    redirect_to :back
  end
  
  # returns true if a remember me check box option in the login view should be provided
  def remember_me?
    raise 'Must define remember_me? method in controller protected section'
  end

  # shall we encrypt the password?
  # expects that method is defined in controller
  def encryption_required?
    super
  end
  
  # generates public ssl session key to be used to encrypt password
  # in otherwise not HTTPS secured session forms
  def set_ssl_public_key_in_session
    if encryption_required?
      key = OpenSSL::PKey::RSA.new(session[:key] || 1024)
      @public_modulus  = key.public_key.n.to_s(16)
      @public_exponent = key.public_key.e.to_s(16)
      session[:key] = key.to_pem
    end
  end

  # true if the user has just logged in
  def logged_in_recently?
    logged_in? && !!@logged_in_recently
  end

  private
  
  # gets login and password from params, if necessary also decrypts password
  def get_login_and_password(login_content=nil, password_content=nil, encrypted_password_content=nil)
    login_content = params[:user][:login] if login_content.nil?
    password_content = params[:user][:password] if password_content.nil?
    encrypted_password_content = params[:user][:encrypted_password] if encrypted_password_content.nil?
    # decrypt password?
    if encryption_required? && session[:key]
      key = OpenSSL::PKey::RSA.new(session[:key])
      password = key.private_decrypt(Base64.decode64(encrypted_password_content))
    else
      password = password_content
    end
    login = login_content
    return login, password
  end
  
  def authenticate_user(login, password, options={})
    user_class.authenticate(login, password, options)
  end
  
end
