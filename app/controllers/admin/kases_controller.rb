# Kase scaffolds
class Admin::KasesController < Admin::AdminApplicationController
  helper 'kases'

  @@standard_columns = [
    :id,
    :person_id,
    :title,
    :description,
    :language_code,
    :price_cents,
    :fixed_price_cents,
    :max_rice_cents,
    :current_bid_cents,
    :currency,
    :lat,
    :lng,
    :status,
    :visits_count,
    :happened_at,
    :created_at,
    :started_at,
    :updated_at,
    :expires_at,
    :time_to_solve,
    :opened_at,
    :auctioned_at,
    :resolved_at,
    :closed_at,
    :comments_count,
    :type,
    :permalink,
    :suspended_at,
    :deleted_at,
    :featured,
    :template,
    :comments,
    :responses,
    # fake columns
    :avatar_url,
    # associations
    :person,
    # :tiers,
    :topics,
  ]
  @@crud_columns = [
    :title,
    :description,
    :language_code,
    :price_cents,
    :currency,
    :happened_at,
    :featured,
    :template,
    # columns
    # associations,
    # :tiers,
    :topics,
    :person, 
    :responses,
    :comments
  ]
  @@show_columns = @@crud_columns + [:status]
  @@list_columns = [:avatar_url, :title, :status, :type, :language_code, :created_at]

  # activate
  @@activate_link = ActiveScaffold::DataStructures::ActionLink.new 'Activate', 
    :action => 'activate', :type => :record, :crud_type => :update,
    :position => false, :inline => true,
    :method => :post, :security_method => :activate_authorized?,
    :confirm => "Are you sure you want to activate?"
  def @@activate_link.label
    return "[Activate]" if record.next_state_for_event(:activate)
    ''
  end
  
  # erase
  @@erase_link = ActiveScaffold::DataStructures::ActionLink.new 'Erase', 
    :action => 'erase', :type => :record, :crud_type => :update,
    :position => false, :inline => true,
    :method => :post, :security_method => :erase_authorized?,
    :confirm => "Are you sure you want to erase?"
  def @@erase_link.label
    return "[Erase]" if record.next_state_for_event(:delete)
    ''
  end
  
  # suspend
  @@toggle_suspend_link = ActiveScaffold::DataStructures::ActionLink.new 'Suspend', 
    :action => 'toggle_suspend', :type => :record, :crud_type => :update,
    :position => false, :inline => true,
    :method => :post, :security_method => :toggle_suspend_authorized?,
    :confirm => "Are you sure you want to suspend or reactivate?"
  def @@toggle_suspend_link.label
    return "[Suspend]" if record.next_state_for_event(:suspend)
    return "[Reactivate]" if record.next_state_for_event(:unsuspend)
    ''
  end
  
  #--- active scaffold
  active_scaffold :kase do |config|
    #--- columns
    config.columns = @@standard_columns
    config.create.columns = @@crud_columns
    config.update.columns = @@crud_columns
    config.show.columns = @@show_columns
    config.list.columns = @@list_columns
    
    #--- action links

    config.action_links.add @@activate_link
    config.action_links.add @@erase_link
    config.action_links.add @@toggle_suspend_link
    
    #--- labels
    columns[:avatar_url].label = "Owner"
    columns[:language_code].label = "Language"
    
    config.columns[:featured].form_ui = :checkbox
    config.columns[:template].form_ui = :checkbox
    
    config.create.columns.add_subgroup "Recommendations" do |group|
      group.add :responses
    end

    config.update.columns.add_subgroup "Recommendations" do |group|
      group.add :responses
    end

    config.create.columns.add_subgroup "Comments" do |group|
      group.add :comments
    end

    config.update.columns.add_subgroup "Comments" do |group|
      group.add :comments
    end
  end  
  
  #--- actions

  def index
    render :template => 'admin/topics/index'
  end

  def activate
    do_list_action(:activate!)
  end

  def erase
    do_list_action(:delete!)
  end

  def toggle_suspend
    @record = active_scaffold_config.model.find_by_id params[:id]
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
  end

  # workaround for STI problem
  # we save the record manually, then all works fine
  def before_update_save(record)
    record.save if record && record.valid?
  end

  def activate_authorized?
    true
  end

  def erase_authorized?
    true
  end

  def toggle_suspend_authorized?
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
