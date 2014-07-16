class Admin::UsersController < Admin::AdminApplicationController
  
  #--- active scaffold
  active_scaffold :user do |config|
    #--- columns
    standard_columns = [
      :id,
      :login,
      :login_confirmation,
      :email,
      :email_confirmation,
      :state,
      :language,
      :currency,
      :timezone,
      :activated_at,
      :deleted_at,
      # assocations
      :person
    ]
    crud_columns = [
      :login,
      :password,
      :password_confirmation,
      :language,
      :currency,
      :time_zone,
      :person
    ]
    config.columns = standard_columns
    config.create.columns = crud_columns
    config.update.columns = crud_columns
    config.show.columns = crud_columns + [:state]
    config.list.columns = [:login, :email, :state, :activated_at]
    
    #--- action links
    
    # suspend
    toggle_suspend_link = ActiveScaffold::DataStructures::ActionLink.new 'Suspend', 
      :action => 'toggle_suspend', :type => :record, :crud_type => :update,
      :position => false, :inline => true,
      :method => :post,
      :confirm => "Are you sure you want to change the user's state?"
    def toggle_suspend_link.label
      return "[Suspend]" if record.next_state_for_event(:suspend)
      return "[Reactivate]" if record.next_state_for_event(:unsuspend)
      return "[Accept]" if record.next_state_for_event(:accept)
      ''
    end
    config.action_links.add toggle_suspend_link
  end

  #--- actions

  def toggle_suspend
    @record = User.find_by_id params[:id]
    raise UserException.new(:record_not_found) if @record.nil?    
    
    if @record.next_state_for_event(:suspend)
      do_list_action(:suspend!)
      return
    elsif @record.next_state_for_event(:unsuspend)
      do_list_action(:unsuspend!) 
      return
    elsif @record.current_state == :screening && @record.next_state_for_event(:accept)
      do_list_action(:accept!) 
      return
    end
    render :nothing => true
  end
  
  protected

  def before_create_save(record)
    @record.register! if @record.valid?
    if @record.errors.empty?
      @record.activate!
    end
  end
  
  def list_authorized?
    current_user && current_user.has_role?(:moderator)
  end

  def create_authorized?
    current_user && current_user.has_role?(:moderator)
  end

  def update_authorized?
    current_user && current_user.has_role?(:moderator)
  end

  def delete_authorized?
    current_user && current_user.has_role?(:moderator)
  end

end
