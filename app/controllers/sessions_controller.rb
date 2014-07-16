# Handles the user session, meaning, the user sign in and sign out
# OpenSSL::HMAC.hexdigest(OpenSSL::Digest::Digest.new('SHA1'), '123', 'abc')
class SessionsController < FrontApplicationController
  include SessionsControllerBase

  #--- filters
  skip_before_filter :verify_authenticity_token, :only => [:create]
  skip_before_filter :login_required, :except => :destroy
  skip_before_filter :load_current_user_and_person, :except => :destroy
  after_filter :discard_flash, :only => [:new, :create]
  
  #--- layout
  layout :choose_layout

  #--- actions
  
  def new
    respond_to do |format|
      format.html {}
      format.js {
        if xhr_redirect? && !uses_modal?
          # modal not open yet, so open and render content
          @uses_modal = true
          render :update do |page|
            with_format :html do
              page << "#{facebox_instance_javascript}.reveal('#{escape_javascript(render(:partial => 'sessions/new'))}');"
            end
            page << "document.fire('authentication:new')"
          end
        else
          with_format :html do
            render :action => 'sessions/new'
          end
        end
      }
    end
  end

  def create
    create_session
    debugger
    puts "s"
  end

  def destroy
    destroy_session
  end
  
  protected

  # override from SessionsControllerBase to offer remember me option on signin dialog
  def remember_me?
    true
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
  
  # override from ssl_requirement
  # ssl only if supported and for :create, :destroy, and :new only if not xhr
  def ssl_required?
    ssl_supported? && ([:create, :destroy].include?(action_name.to_sym) || (!request.xhr? && :new == action_name.to_sym))
  end
  
  def ssl_allowed?
    true
  end

  private
  
  # overrides standard user authentication to allow for login or email authentication
  def authenticate_user(login, password, options={})
    user_class.authenticate_by_login_or_email(login, password, :trace => true)
  end
  
  # Helper to choose a layout based on criteria
  def choose_layout
    request.xhr? || uses_modal? ? false : 'front'
  end

end
