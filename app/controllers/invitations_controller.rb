# Manages invitations of other memembers, or invitees. Both new
# and existing members can be invited.
class InvitationsController < FrontApplicationController
  include WizardBase
  include InvitationsControllerBase
  helper :contacts

  #--- filters
  skip_before_filter :load_user, :except => [:new, :create, :index, :accept, :decline]
  before_filter :load_invitee
  skip_before_filter :login_required, :only => :new_user
  before_filter :load_current_invitation_or_redirect, :only => :complete
  before_filter :clear_current_invitation, :except => :complete
  after_filter :clear_current_invitation, :only => :complete
  
  #--- layout
  layout :choose_layout

  #--- theme
  set_theme :profile

  #--- wizard
  wizard do |step|
    step.add :new, "Invite", :required => true, :link => true
    step.add :show, "Complete", :required => true, :link => false
  end

  #--- actions 
  
  # shows all current users invitations 
  def index
    @title = "Unanswered Invitations".t
    case params[:kind]
    when /accepted/
      @invitations = do_search(
        @person.sent_invitations.after(Time.now.utc - 6.months).registered.accepted,
        nil,
        :partial => 'invitations/list_item_content',
        :locals => { :items => @invitations },
        :sort_display => false,
        :url => hash_for_invitations_path,
        :with_render => true
      )
      return
    when /declined/
      @invitations = do_search(
        @person.sent_invitations.after(Time.now.utc - 6.months).registered.declined,
        nil,
        :partial => 'invitations/list_item_content',
        :locals => { :items => @invitations },
        :sort_display => false,
        :url => hash_for_invitations_path,
        :with_render => true
      )
      return
    else
      @invitations = do_search(
        @person.sent_invitations.after(Time.now.utc - 6.months).registered.pending, 
        nil,
        :partial => 'invitations/list_item_content',
        :sort_display => false,
        :url => hash_for_invitations_path
      )
    end
  end
  
  def new
    @invitation = Invitation.new(:invitor => @person, :invitee => @invitee)
  end
 
  def create
    @invitation = @person.create_invitation(params[:invitation] || {})
    if @invitation.valid?
      respond_to do |format|
        format.js {
          flash[:notice] = "Invitation sent to %{name}".t % {:name => "<b>#{@invitation.to_invitee.name_or_email}</b>"}
          render :update do |page|
            page.replace dom_class(Invitation), :partial => "invitations/complete"
          end
          return
        }
        format.html {
          self.current_invitation = @invitation
          redirect_to complete_invitations_url
          return
        }
      end
    else
      # handle errors
      respond_to do |format|
        format.js {
          render :update do |page|
            page.replace dom_class(Invitation), :partial => "invitations/new"
          end
        }
        format.html {render :template => "invitations/new"}
      end
    end
  end
  
  # 2nd step of invitiation wizard
  def complete
  end
  
  # updates the message text in the invitation of the message box
  #
  # Params:
  #   :value => 'en' || 'de' || other
  #   :invitor_name => 'Hans Zimmer'
  #   :invitee_name => 'Morona Miller'
  #   :html_id => 'invitation_message'  element which will be updated
  def update_message
    if request.xhr?
      message = Invitation.default_message(
        :language => params[:value],
        :invitor_name => params[:invitor_name],
        :invitee_name => params[:invitee_name]
      )
      render :update do |page|
        page[dom_class(Invitation, :text)].value = message
      end
    end
  end
  
  # accepts an invitation request
  def accept
    if request.xhr?
      if @invitation = Invitation.find(params[:id])
        if @invitation.accept! == true
          render :partial => 'invitations/list_item_accepted', :object => @invitation
        else
          flash[:error] = "Invitation request from #{@invitation.invitor.name} was not accepted."
          render :text => form_flash_messages, :status => 444
        end
      end
    end
  end
  
  # declines (ignores) an invitation request
  def decline
    if request.xhr?
      if @invitation = Invitation.find(params[:id])
        if @invitation.decline! == true
          render :partial => 'invitations/list_item_declined', :object => @invitation
        else
          flash[:error] = "Invitation request from #{@invitation.invitor.name} was not ignored."
          render :text => form_flash_messages, :status => 444
        end
      end
    end
  end

  # remind an resend invitation once
  def remind
    if request.xhr?
      if @invitation = Invitation.find(params[:id])
        if @invitation.remind
          render :partial => 'invitations/list_item_reminded', :object => @invitation
        else
          flash[:error] = "Invitation request from #{@invitation.invitor.name} was not ignored."
          render :text => form_flash_messages, :status => 444
        end
      end
    end
  end
  
  # expands or retracts each list item using the (+) and (x) icons
  def list_item_expander
    if request.xhr?
      @invitation = Invitation.find(params[:id])
      render :partial => 'invitations/list_item_content', :object => @invitation, :locals => {
        :expanded => params[:expanded].to_s.index(/1/) ? false : true
      }
    end
  end
  
  # used for invitations to new or existing invitees.
  # stores the invitation (passed by uuid :id) in the session/cookie and redirects to /user/new
  def confirm
    if params[:id] && (@invitation = Invitation.find_by_uuid(params[:id]))
      # new invitees
      if @invitation.delivered?
        # invitee has registered in the meantime?
        if (invitee = Person.find_by_email(@invitation.email)) && invitee.active?
          @invitation.invitee = invitee
          if @invitation.open!
            redirect_to invitations_path  # NOTE: invitation_path(@invitation) one we have a show action!
            return
          end
        end
        # otherwise...invitee will be redirected and kindly asked to signup
        @invitation.signup!
        self.current_invitation =  @invitation
        flash[:notice] = [
          "%{name} has invited you to become a contact.".t % {:name => @invitation.invitor.name},
          (@invitation.with_voucher? ? "%{name} is nice and included a %{voucher}.".t % {
            :name => @invitation.invitor.casualize_name,
            :voucher => @invitation.voucher.class.human_name.titleize
          } : ''),
          "To accept the invitation you must complete the registration process.".t
        ].join(' ') if @invitation
        redirect_to new_user_path
        return
      elsif @invitation.pending? && @invitation.invitee == @person
        @invitation.accept!
        flash[:notice] = "You have accepted the invitation of %{name}.".t % {:name => @invitation.invitor}
        redirect_to person_path(@person)
        return
      end
    end
    # otherwise, fall back have the user invite someone...
    redirect_to new_invitation_path
    return
  end

  protected

  # used when routes /profile/xxx/invitations/new in before_filter is loaded
  def load_invitee
    if params[:person_id]
      if @invitee = Person.find_by_permalink(params[:person_id])
        params[:invitation].merge!(:invitee => @invitee) if params[:invitation]
      end
    end
  end
  
  # used as before filter to load invitation for complete wizard step
  def load_current_invitation_or_redirect
    unless @invitation = current_invitation 
      redirect_to new_invitation_path
      return false
    end
    true
  end
  
  # removes current invitation from session/cookie
  def clear_current_invitation
    self.current_invitation = nil
  end
  
  private
  
  # Helper to choose a layout based on criteria
  def choose_layout
    request.xhr? ? 'modal' : 'front'
  end
  
end
