class Admin::ClaimingsController < Admin::AdminApplicationController

  #--- active scaffold
  active_scaffold :claiming do |config|
    #--- columns
    standard_columns = [
      :id,
      :type,
      :sender_id,
      :receiver_id,
      :description,
      :email,
      :phone,
      :role,
      :accepted_at,
      :declined_at,
      # associations
      :person,
      :organization
    ]
    crud_columns = [
      :id,
      :email,
      :phone,
      :description,
      :role,
      # associations
      :person,
      :organization
    ]
    config.columns = standard_columns
    config.create.columns = crud_columns
    config.update.columns = crud_columns
    config.show.columns = crud_columns + [:status]
    config.list.columns = [:name, :email, :phone, :organization, :status]
    
    #--- scaffold actions
    config.actions.exclude :create
    config.actions.exclude :delete
    config.actions.exclude :show

    #--- action links

    # accept
    accept_link = ActiveScaffold::DataStructures::ActionLink.new 'Accept', 
      :action => 'accept', :type => :record, :crud_type => :update,
      :position => false, :inline => true,
      :method => :post, :security_method => :accept_authorized?,
      :confirm => "Are you sure you want to accept?"
    def accept_link.label
      return "[Accept]" if record.next_state_for_event(:accept)
      ''
    end
    config.action_links.add accept_link
    
    # decline
    decline_link = ActiveScaffold::DataStructures::ActionLink.new 'Decline', 
      :action => 'decline', :type => :record, :crud_type => :update,
      :position => false, :inline => true,
      :method => :post, :security_method => :decline_authorized?,
      :confirm => "Are you sure you want to decline?"
    def decline_link.label
      return "[Decline]" if record.next_state_for_event(:decline)
      ''
    end
    config.action_links.add decline_link
  end  

  #--- actions
  
  def accept
    do_list_action(:accept!)
  end

  def decline
    do_list_action(:decline!)
  end

  protected
  
  def conditions_for_collection
    'messages.parent_id IS NULL'
  end

  def accept_authorized?
    true
  end

  def decline_authorized?
    true
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
