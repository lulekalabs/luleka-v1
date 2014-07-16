class Admin::AdminUsersController < Admin::AdminApplicationController
  #--- active scaffold
  active_scaffold :admin_user do |config|
    #--- columns
    standard_columns = [
      :id,
      :login,
      :login_confirmation,
      :email,
      :state,
      :activated_at,
      :deleted_at,
      :role_ids,
      :roles
    ]
    crud_columns = [
      :login,
      :email,
      :password,
      :password_confirmation,
      :role_ids
    ]
    config.columns = standard_columns
    config.create.columns = crud_columns
    config.update.columns = crud_columns
    config.show.columns = crud_columns
    config.list.columns = [:login, :email, :role_ids, :activated_at]

    columns[:role_ids].label = "Roles"
    
    config.create.columns.add_subgroup "Roles" do |group|
      group.add [:role_ids]
    end

    config.update.columns.add_subgroup "Roles" do |group|
      group.add [:role_ids]
    end
    
    #--- action links
    
    # suspend
    toggle_suspend_link = ActiveScaffold::DataStructures::ActionLink.new 'Suspend', 
      :action => 'toggle_suspend', :type => :record, :crud_type => :update,
      :position => false, :inline => true,
      :method => :post,
      :confirm => "Are you sure you want to suspend or reactivate?",
      :security_method => :update_authorized?
    def toggle_suspend_link.label
      return "[Suspend]" if record.next_state_for_event(:suspend)
      return "[Reactivate]" if record.next_state_for_event(:unsuspend)
      ''
    end
    config.action_links.add toggle_suspend_link
    
  end

  #--- actions

  def toggle_suspend
    @record = AdminUser.find_by_id params[:id]
    raise UserException.new(:record_not_found) if @record.nil?    
    
    if @record.next_state_for_event(:suspend)
      do_list_action(:suspend!)
      return
    elsif @record.next_state_for_event(:unsuspend)
      do_list_action(:unsuspend!) 
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

  def find_user
    @user = AdminUser.find(params[:id])
  end
  
  def list_authorized?
    current_user && current_user.has_role?(:admin)
  end

  def create_authorized?
    current_user && current_user.has_role?(:admin)
  end

  def update_authorized?
    current_user && current_user.has_role?(:admin)
  end

  def delete_authorized?
    current_user && current_user.has_role?(:admin)
  end

end
