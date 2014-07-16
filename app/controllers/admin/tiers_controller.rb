# Scaffold for all tiers saffolds
class Admin::TiersController < Admin::AdminApplicationController
  helper "admin/reward_rates"
  
  #--- columns
  @@standard_columns = [
    :id,
    :parent_id,
    :name,
    :name_de,
    :tagline,
    :site_url,
    :tax_code,
    :lat,
    :lng,
    :created_at,
    :updated_at,
    :type,
    :site_name,
    :status,
    :country_code,
    :language_code,
    :description,
    :summary,
    :description_de,
    :activated_at,
    :permalink,
    :created_by_id,
    :activation_code,
    :deleted_at,
    :image_file_name,
    :image_content_type,
    :image_file_size,
    :image_updated_at,
    :featured,
    # fake columns
    :image,
    :image_url,
    # associations
    :tag_list,
    :parent,
#    :address,
    :created_by,
    :category_id,
    :bonus_rewards,
    :reputation_rewards,
    :reputation_thresholds
  ]

  @@reputation_columns = [
    :accept_person_total_reputation_points,
    :accept_default_reputation_threshold,
    :accept_default_reputation_points,
    :reputation_rewards,
    :reputation_thresholds
  ]
  @@standard_columns += @@reputation_columns

  @@crud_columns = [
    :name,
    :description,
    :summary,
    :country_code,
    :language_code,
#    :type,
    :category_id,
    :image,
    :tagline,
#    :tag_list,
    :site_url,
    :tax_code,
    :site_name,
    :featured,
    :bonus_rewards,
#    :permalink,
    # associations
#    :parent,
#    :address,
#    :created_by
  ]
  @@show_columns = @@crud_columns + [:status]
  @@list_columns = [:image_url, :name, :status, :country_code, :type, :updated_at]

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
  
  #--- active scaffold
  active_scaffold :tier do |config|
    #--- columns
    standard_columns = @@standard_columns
    crud_columns = @@crud_columns
    config.columns = @@standard_columns
    config.create.columns = @@crud_columns
    config.update.columns = @@crud_columns
    config.show.columns = @@show_columns
    config.list.columns = @@list_columns

    config.create.multipart = true
    config.update.multipart = true

    #--- action links
    config.action_links.add @@activate_link
    config.action_links.add @@toggle_suspend_link
    config.action_links.add @@erase_link
    
    #--- labels
    columns[:image_url].label = "Image"
    columns[:country_code].label = "Country"
    columns[:language_code].label = "Language"
    
    config.columns[:featured].form_ui = :checkbox

    columns[:accept_person_total_reputation_points].label = "Use person's total reputation"
    columns[:accept_person_total_reputation_points].description = "Toggle whether to accept earned reputation from this community only or also accept globally earned reputation when it comes to 'allowing' user to do something."
    columns[:accept_default_reputation_threshold].label = "Use site default reputation threshold"
    columns[:accept_default_reputation_threshold].description = "Toggle whether to use minimum reputation points necessary defined in this community or use the site's default threshold settings"
    columns[:accept_default_reputation_points].label = "Use site default reputation points"
    columns[:accept_default_reputation_points].description = "Toggle whether to give reputation points (as rewards) strictly defined for this community or use the community default reputation points."

    config.create.columns.add_subgroup "Reputation Config" do |group|
      group.add @@reputation_columns
    end

    config.update.columns.add_subgroup "Reputation Config" do |group|
      group.add @@reputation_columns
    end

  end  

  #--- actions

  def index
    render :template => 'admin/tiers/index'
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
  
  def after_update_save(record)
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
