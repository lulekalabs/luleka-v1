class UsersController < FrontApplicationController
  extend SessionCaptcha::ActionControllerHelpers
  include WizardBase
  include UsersControllerBase
  include SessionsControllerBase
  include VouchersControllerBase
  include InvitationsControllerBase
  helper :people
  
  #--- exceptions
  #rescue_from Facebooker::Session::SessionExpired, :with => :facebook_session_expired
  
  #--- filters
  skip_before_filter :login_required
  skip_before_filter :load_current_user_and_person
  before_filter :clear_current_user, :except => [:complete, :signup, :link_fb_connect]
  before_filter :destroy_session_and_redirect_to_new_password, :only => [:new_password, :reset_password]
  before_filter :clear_current_registering_user, :except => [:confirm, :activate, :resend, :update]
  before_filter :build_partner_memberships, :only => :complete
  before_filter :select_current_partner_membership, :only => :complete
  after_filter :after_create, :only => :create
  after_filter :discard_flash, :only => :new
  
  #--- layout
#  layout :choose_layout
  
  #--- wizard
  wizard do |step|
    step.add :new,      "Register", :required => true, :link => false
    step.add :confirm,  "Confirm",  :required => true, :link => false
    step.add :activate, "Activate", :required => true, :link => false
    step.add :complete, "Complete", :required => true, :link => true
  end
  
  #--- actions
  
  def new
    @user = build_user(:guest => true)
    respond_to do |format|
      format.js {
        if uses_opened_modal?
          render :update do |page|
            page.replace 'contentColumnModal', render(:file => 'users/new.html.erb')
          end
        else
          with_format :html do
            render :action => "users/new"
          end
        end
      }
      format.html {
      }
    end
  end

  # callback to connect facebook user accounts with following scenarios:
  #
  #   1. Not logged in, fb session id not found -> new user
  #   2. Not logged in, found fb session -> login session
  #   3. Logged in, link accout to fb
  #
  def link_fb_connect
    if !current_user && current_facebook_user && (facebooker = User.find_by_fb_user(current_facebook_user))
      # fb user found, sign in using that session
      create_session_with facebooker
      return
    elsif !current_user && current_facebook_user
      # build fb user
      session[:link_fb_connect] = true
      @user = build_user
      respond_to do |format|
        format.js {
          if uses_opened_modal?
            flash[:notice] = ["Please wait while %{service_name} syncs with your %{connect_service_name} profile.".t,
              "This may take a few seconds.".t].to_sentences % {:service_name => SERVICE_NAME, :connect_service_name => "Facebook"}
            new_url = member_url([:tier, :user], :new, {:tier_id => @tier || params[:tier_id], :uses_opened_modal => "1"})
            render :update do |page|
              page.replace 'contentColumnModal', content_modal(form_flash_messages)
              page << remote_function(:url => new_url, :method => :get)
            end
          else
            @uses_modal = true
            render :update do |page|
              with_format :html do
                page << "#{facebox_instance_javascript}.reveal('#{escape_javascript(render(:partial => 'users/new'))}');"
              end
            end
          end
          return
        }
        format.html {
          redirect_to new_user_path
        }
      end
      flash.discard
      return
    elsif current_user
      # connect accounts
      current_user.link_fb_connect(current_facebook_user) # unless self.current_user.fb_user_id == facebook_session.user.id
      render :nothing => true
      return
    end
    # or otherwise redirect
    respond_to do |format|
      format.js {
        render :update do |page|
          page.redirect_to params[:redirect_to].blank? ? '/' : params[:redirect_to]
        end
      }
      format.html {
        redirect_to params[:redirect_to].blank? ? '/' : params[:redirect_to]
      }
    end
    return
  end

  def create
    @user = build_user(:guest => true)
    @person.valid? and @person.personal_address.valid?
    if @user.save
      @user.register!
      self.current_registering_user = @user
      respond_to do |format|
        format.js {
          @uses_modal = true
          render :update do |page|
            page.replace 'contentColumnModal', render(:file => 'users/confirm.html.erb')
          end
        }
        format.html {
          redirect_to confirm_users_path
        }
      end
      return
    end
    respond_to do |format|
      format.js {
        @uses_modal = true
        render :update do |page|
          page.replace 'contentColumnModal', render(:file => 'users/new.html.erb')
        end
      }
      format.html {
        render :action => 'new'
      }
    end
    return
  end

  # confirms that user registration
  def confirm
    unless @user = current_registering_user
      redirect_to new_user_path
      return
    end
    @uses_modal = true if request.xhr?
  end

  # :post /users/:login/activate
  # e.g. http://luleka.com/user/28f2dac258f52a949d2efd2a881cc578c3454e27/activate
  def activate
    unless params[:id] && @user = User.find_by_activation_code(params[:id])
      redirect_to new_user_path
      return
    end
    # make sure we build all necessary associations, but does not overwrite fetched @user
    @user = build_user(:guest => false)
  end

  # activate account
  # :put /users/<activation-code>
  def update
    if @user = User.find_by_activation_code(params[:id])
      @user = build_user(:guest => false)
      @user.not_guest!
      if @user.valid?
        @user.activate!
        self.create_session_without_render_with @user
      
        # handle invitation and make friends
        # redeem voucher if one is present
        if @invitation = current_invitation
          @invitation.invitee = @user.person if @invitation
          @invitation.accept! if @invitation && @invitation.registering?
          self.current_voucher = @invitation.voucher if @invitation && @invitation.with_voucher?
          self.current_invitation = nil
        end

        redirect_to complete_users_path
        return
      else
        # user does not validate
        render :action => 'activate'
        return
      end
    end
    redirect_to new_user_path
    return
  end

  # :get /users/complete
  # * build partner memberships
  # * check for current partner vouchers
  def complete
    @user = current_user || current_registering_user
    redirect_to new_user_path unless @user
  end

  # :get /users/<activation-code>/resend
  def resend
    if @user = User.find_by_activation_code(params[:id])
      @user.resend_confirmation_request
      current_registering_user = @user
      flash[:notice] = "Your confirmation request has just been resent.".t
      respond_to do |format|
        format.js {
          @uses_modal = true
          if uses_opened_modal?
            render :update do |page|
              page.replace 'contentColumnModal', render(:file => 'users/confirm.html.erb')
            end
          else
            with_format :html do
              render :action => "users/confirm"
            end
          end
        }
        format.html {
          redirect_to confirm_users_path
        }
      end
      return
    end
    redirect_to new_user_path
  end

  # :get /user/forgot_password
  def forgot_password
    respond_to do |format|
      format.js {
        if uses_opened_modal?
          render :update do |page|
            page.replace 'contentColumnModal', render(:file => 'users/forgot_password.html.erb')
          end
        else
          with_format :html do
            render :action => "users/forgot_password"
          end
        end
      }
      format.html {
      }
    end
  end
  
  # :post /user/create_reset_password
  def create_reset_password
    if @user = User.find_by_login_or_email(params[:user][:login])
      @user.create_reset_code
      flash[:notice] = "Reset code was sent by email.".t
      respond_to do |format|
        format.js {
          render :update do |page|
            page.replace 'contentColumnModal', form_flash_messages
            page.delay(MODAL_FLASH_DELAY) do 
              page << close_modal_javascript
            end
          end
          flash.discard
          return
        }
        format.html {
          # render form again to show flash message
          render :action => 'forgot_password'
          return
        }
      end
    end
    flash[:error] = "Username or email did not match.".t
    respond_to do |format|
      format.js {
        render :update do |page|
          @uses_modal = true
          if uses_opened_modal?
            render :update do |page|
              page.replace 'contentColumnModal', render(:file => 'users/forgot_password.html.erb')
            end
          else
            with_format :html do
              render :action => "users/forgot_password"
            end
          end
        end
        return
      }
      format.html {
        render :action => 'forgot_password'
        return
      }
    end
  end

  # :get /users/<reset-code>/reset
  def reset
    if @user = User.find_by_reset_code(params[:id])
      if @user.pending?
        if @user.activation_code
          redirect_to activate_user_path(:id => @user.activation_code)
        else
          redirect_to new_user_path
        end
        return 
      elsif !@user.active?
        flash[:warning] = "User is not active.".t
        redirect_to new_user_path
        return
      end
    else
      flash[:error] = "Invalid user password reset code.".t
      redirect_to forgot_password_users_path
      return 
    end
  end
  
  # :put /users/<reset-code>/update_password
  def update_password
    if @user = User.find_by_reset_code(params[:id])
      if @user.active?
        @user.attributes = params[:user]
        @user.password_required!
        if @user.save
          self.current_user = nil # @user
          @user.delete_reset_code
          flash[:notice] = "Password successfully reset.".t
          redirect_to(new_session_path)
          return
        end
      else
        flash[:warning] = "User is not active.".t
      end
    end
    render :action => 'reset'
  end
    
  def validates_uniqueness
    if request.xhr?
      @user = User.new({params[:field].to_sym => params[:value].to_s.strip})
      @user.valid?
      if @user.errors.on(params[:field].to_sym)
        @caption = "#{User.human_attribute_name(params[:field])} \"#{params[:value]}\" #{@user.errors.on(params[:field].to_sym)}"
        @message_type = :warning
      else
        @caption = "%{field} available".t % {:field => "#{User.human_attribute_name(params[:field])} \"#{params[:value]}\""}
        @message_type = :notice
      end
      @dom_id = params[:dom_id]
    else
      render :nothing => true
    end
  end
  
  # used for address province field update
  # TODO: refactor, should not be here!
  def update_address_province
    if request.xhr?
      #--- do not delete this
      Person
      #--- thanks! reason? Person dynamically loads PersonalAddress, etc.
      @provinces = /---|...|^$/.match(params[:value].to_s) ? [] : collect_provinces_for_select(params[:value])
      address = if /([a-zA-Z_]*)_attributes/.match(params[:method_name].to_s)
        $1.camelize.constantize.new
      end
      render :update do |page|
        page.replace params[:html_id], :partial => 'shared/address_province', :object => address,
          :locals => {:object_name => params[:object_name], :method_name => params[:method_name],
            :provinces => @provinces, :html_id => params[:html_id],
            :disabled => @provinces.is_a?(Array) && @provinces.empty? ? true : false,
            :req => (params[:req] ? true : false), :lock => (params[:lock] ? true : false)}
      end
    else
      render :nothing => true
    end
  end

  protected
  
  def ssl_required?
    ssl_supported?
  end
  
  def ssl_allowed?
    request.xhr? # uses_modal?
  end
  
  # hash key for registering user in the session
  def registering_user_session_param
    :registering_user_id
  end
  
  # Accesses the current registering user from the session. 
  # Future calls avoid the database because nil is not equal to false.
  def current_registering_user
    @current_registering_user ||= load_registering_user_from_session unless @current_registering_user == false
  end
  helper_method :current_registering_user

  # Store the given registering user id in the session.
  def current_registering_user=(new_user)
    session[registering_user_session_param] = new_user ? new_user.id : nil
    @current_registerin_user = new_user || false
  end
  
  # used in before filter to remove session user
  def clear_current_user
    self.current_user = nil
  end

  # kills the session
  def destroy_session_and_redirect_to_new_password
    if logged_in?
      destroy_session(new_password_user_path)
      return
    end
    true
  end
  
  # used in before filter to remove session registering user
  def clear_current_registering_user
    self.current_registering_user = nil
  end
  
  def load_registering_user_from_session
    self.current_registering_user = user_class.find_by_id(session[registering_user_session_param]) if session[registering_user_session_param]
  end

  # overrides current_invitation from InvitationControllersBase
  # returns an invitation's instance invitee email that matches the current user's email
  # and has been marked been confirmed as registering (see /invitations/:uuid/confirm)
  def current_invitation
    @current_invitation ||= load_invitation_from_session unless @current_invitation == false
    @current_invitation ||= Invitation.registering(:conditions => {:email => current_user.email}).first if current_user
    @current_invitation
  end

  # override from front app controller
  # loads the current user and person or redirects to the the user's
  # person profile page if the person has been activated as member or partner already
  def load_current_user_and_person
    super
    if @person && @person.active? 
      unless action_name =~ /complete/
        redirect_to person_path(@person)
        return
      end
    end
  end

  # build regular (native) user
  # or build user from facebook session
  # Note: add here other accounts we may want to add
  def build_user(options={})
    options.symbolize_keys!
    options.reverse_merge!({:language => Utility.language_code, :country => Utility.country_code,
      :email => current_invitation ? current_invitation.email : nil}.reject {|k,v| v.blank?})
    as_guest = !!options.delete(:guest)
    if session[:link_fb_connect] && current_facebook_user
      current_facebook_user.fetch
      @user = User.new_from_fb_user(current_facebook_user,
        {:email => current_invitation ? current_invitation.email : nil})
    else
      @user = User.new({:email => current_invitation ? current_invitation.email : nil}) unless @user
    end
    as_guest ? @user.guest! : @user.not_guest!
    @user.person.build unless @user.person
    @user.person.attributes = {}.merge((params[:person] || {}).symbolize_keys).merge(options[:person] || {})
    @address = @user.person.personal_address || @user.person.build_personal_address(:country_code => Utility.country_code)
    @user.attributes = options.reject {|k,v| k == :person}.merge((params[:user] || {}).symbolize_keys)
    @person = @user.person
    @user
  end

  def after_create
    session[:link_fb_connect] = nil
  end
  
  def facebook_session_expired
    flash[:error] = ["Your Facebook session has expired.".t, "Please try again.".t].to_sentences
    destroy_session new_session_path
  end

  private
  
  # Helper to choose a layout based on criteria
  def choose_layout
    request.xhr? || uses_modal? ? false : 'front'
  end

end
