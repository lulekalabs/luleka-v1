# Responses handles answers to a kase
class ResponsesController < FrontApplicationController
  include PropertyEditor
  include FlagsControllerBase
  include TiersControllerBase
  include CommentablesControllerBase
  include VoteablesControllerBase
  include SessionsControllerBase

  helper :kases, :flags, :property_editor, :voteables

  #--- filters
  skip_before_filter :login_required, :only => [:new, :create]
  before_filter :load_kase
  before_filter :load_response, :only => [:accept, :vote_up, :vote_down, :edit_description_in_place]

  #--- theme
  choose_theme :which_theme?

  #--- actions
  property_action :response, :description, :partial => 'responses/description', :locals => {:label => false}

  def new
    respond_to do |format|
      format.js {
        @response = @kase.build_response(@person, {}, true)
        if @response.allowed?
          # enable the response/description input
          render :update do |page|
            page.replace_html dom_id(@response), :partial => "responses/new"
          end
        else
          # update response message
          render :update do |page|
            page.replace_html dom_class(Response, :message), 
              form_error_messages_for([:kase, :response], :type => :warning, :unique => true, :attr_names => {
            	  :base => '', :kase => @kase.kind.human_name.capitalize, :person => "Person".t
            	}, :header => "You cannot post a reply due to the following:".t)
          end
        end
      }
      format.html {
        render :nothing => true
      }
    end
  end

  def create
    @response = build_response(params[:response]) 
    if request.xhr?
      response_id = dom_id(@response)
      if save_and_activate
        render :update do |page|
          page[dom_class(Response, :message)].hide
          page.replace response_id, :partial => 'responses/response', :object => @response
        end
        return
      end
      render :update, :status => 444 do |page|
        page.replace dom_id(@response), :partial => "responses/response",
          :object => @response
        
        page.replace_html dom_class(Response, :message), 
          form_flash_messages + 
          form_error_messages_for([:response, :user], :unique => true, :attr_names => {
        	  :base => '', :description => Response.human_name, 
        	  :login => User.human_attribute_name(:login), :email => User.human_attribute_name(:email),
        	  :email_confirmation => User.human_attribute_name(:email_confirmation)
        	})
        page << "new Effect.ScrollTo('#{dom_class(Response, :message)}', {offset:-12})"
        page[dom_class(Response, :message)].show
      end
      return
    else
      render :nothing => true
    end
  end
  
  def index
    do_search_responses
    return
  end
  
  # get /responses/popular
  def popular
    do_search_responses(Response.finder_options_for_popular)
    return
  end
  
  # put /kases/:kase_id/responses/:id/accept
  def accept
    respond_to do |format|
      format.js {
        debugger
        if @response.can_be_accepted_by?(current_user.person) && @response.accept! == true
          # render response list and scroll to accepted response
          render :update do |page|
            page.replace dom_id(@kase), :partial => "kases/show"
            page.replace_html dom_class(Response, :list), :partial => "responses/list", :object => @kase.responses
            page.replace 'sidebarActions', :partial => "kases/sidebar_actions"
            page << "new Effect.ScrollTo('#{dom_id(@response)}', {offset:-12})"
          end
        else
          # update response message
          flash[:error] = "You cannot accept this recommendation.".t
          render :update do |page|
            page.replace_html dom_class(Response, :message), form_flash_messages
            page << "new Effect.ScrollTo('#{dom_class(Response, :message)}', {offset:-12})"
          end
          flash.discard
        end
      }
      format.html {
        render :nothing => true
      }
    end
  end
  
  def activate
    if @response = Response.find_by_activation_code(params[:id])
      @response.person = @person

      if @response.activate! && @response.active?
        flash[:notice] = (PUBLISH_SUCCESS.t % {:object => @response.class.human_name}).to_sentence
        redirect_to member_path([@response.kase.tier, @response.kase])
        return
      end
    end
    flash[:error] = (PUBLISH_FAIL.t % {:object => (@response.class || Response).human_name}).to_sentence
    redirect_to '/'
  end
  
  protected 
  
  def do_search_responses(finder_options={})
    @responses = @kase.responses.find(:all, finder_options)
    if request.xhr?
      render :update do |page|
        page.replace dom_class(Response, :list), :partial => 'responses/list', :object => @responses
      end
    else
      redirect_to member_path([@kase])
      return
    end
  end
  
  def load_kase
    if id = class_param_id(Kase)
      @kase = Kase.find_by_permalink(id)
      @tier = @kase.tier if @kase
      @topics = @kase.topics if @kase
    else
      return false
    end
  end
  
  def load_response
    if @kase && params[:id]
      @response = @kase.responses.find_by_id(params[:id])
    elsif params[:object_name] == "response" && params[:id]
      # this is done for the in place editor
      @response = Response.find_by_id(params[:id])
    end
  end
  
  # builds the response from kase
  def build_response(options={}, user_options={})
    @response = @kase.build_response(logged_in? ? current_user.person : nil, options)

    # check user
    if @response && !logged_in?
      signin_login = params[:user].delete(:signin_login) if params[:user]
      if @response.authenticate_with_signin?
        @user = create_session_without_render(signin_login)
        if @user
          @response.person = @person = @user.person
        end
      elsif @response.authenticate_with_signup?
        @user = User.new((params[:user] || {}).symbolize_keys.merge(user_options.symbolize_keys))
        @user.guest!
        @response.sender_email = @user.email
      else
        # by default set authentication type to signin
        @response.authentication_type = "signin"
      end
    end
    @response
  end

  # validates @response and if not logged in the @user as well
  def valid?
    result = @response.valid?
    unless logged_in?
      if @response.authenticate_with_signin?
        # if we were authenticated, we would not end up here, so not good!
        result = false
      elsif @response.authenticate_with_signup?
        result = @user.new_record? && @user.valid? && result
      end
    end
    result
  end

  # save all necessary instances, including @user if necessary
  def save_and_activate
    result = self.valid?
    if result && !logged_in? 
      if @response.authenticate_with_signin?
        # nothing
      elsif @response.authenticate_with_signup?
        result = result && @user.new_record? && @user.valid?
      end
    end
    if result = result && @response.save
      @user.register! if @response.authenticate_with_signup? && @user.valid?
      @response.activate!
      flash[:info] = if @response.active?
        (PUBLISH_SUCCESS.t % {:object => @response.class.human_name}).to_sentence
      elsif @response.created?
        (CREATE_SUCCESS.t % {:object => @response.class.human_name}).to_sentence
      end
    end
    result
  end

  # determine which theme we should set?
  def which_theme?
    @response && @response.accepted? ? :response : :form
  end

end
