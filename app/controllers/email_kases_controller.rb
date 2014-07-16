# Used to send kase details to user who may be able to help out
class EmailKasesController < FrontApplicationController
  extend SessionCaptcha::ActionControllerHelpers
  
  #--- filters
  skip_before_filter :store_previous, :only => :verification_code
  skip_before_filter :login_required
  before_filter :load_kase_or_redirect, :except => :verification_code
  
  #--- layout
  layout :choose_layout
  
  #--- actions
  create_captcha_image_action

  def new
    @email = build_email_kase
  end
  
  def create
    @email = build_email_kase
    
    respond_to do |format|
      format.js {
        @email.verification_code_session = get_and_clear_captcha_code
        if @email.valid?
          @email.deliver
          render :update do |page|
            page << close_modal_javascript
          end
          return
        else
          @email.clear_verification_codes
          render :update do |page|
            page.replace dom_class(EmailKase), render(:file => 'email_kases/new.html.erb')
          end
          return
        end
      }
      format.html {
        @email.verification_code_session = get_and_clear_captcha_code
        if @email.valid?
          @email.deliver
          flash[:notice] = "Message has been sent!".t
          redirect_to @email.kase
          return
        end
        @email.clear_verification_codes
        render :template => 'email_kases/new'
        return
      }
    end
  end
  
  protected
  
  # load the kase instance
  def load_kase_or_redirect
    if id = class_param_id(Kase)
      @kase = Kase.find_by_permalink(id)
      @tier = @kase.tier if @kase
      @topics = @kase.topics if @kase
    end
    unless @kase
      if request.xhr?
        render :update do |page|
          page.redirect_to kases_path
        end
      else
        redirect_to kases_path
      end
      return false
    end
  end

  # builds the email
  def build_email_kase(options={})
    @email = @kase.build_email_kase({:sender => current_user ? current_user.person : nil}.merge(
      (params[:email] || {}).symbolize_keys.merge(options)))
  end

  private
  
  # Helper to choose a layout based on criteria
  def choose_layout
    request.xhr? ? 'modal' : 'front'
  end
  
end
