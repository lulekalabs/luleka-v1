# Superclass for editing all topic scaffold
class Admin::TopicsController < Admin::AdminApplicationController

  @@standard_columns = [
    :id,
    :name,
    :name_de,
    :description,
    :description_de,
    :unit,
    :pieces,
    :taxable,
    :sku_type,
    :sku_id,
    :sku_variant_id,
    :language_code,
    :country_code,
    :tier_id,
    :created_at,
    :updated_at,
    :status,
    :activated_at,
    :internal,
    :permalink,
    :site_url,
    :type,
    :created_by_id,
    :activation_code,
    :deleted_at,
    :image_file_name,
    :image_content_type,
    :image_file_size,
    :image_updated_at,
    :featured,
    # columns
    :image,
    :image_url,
    # associations
    :tier,
    :address,
    :created_by
  ]
  @@crud_columns = [
    :name,
    :description,
    :image,
    :unit,
    :pieces,
    :taxable,
    :sku_type,
    :sku_id,
    :sku_variant_id,
    :language_code,
    :country_code,
    :internal,
    :permalink,
    :site_url,
    :featured,
    # associations
    :tier,
    :created_by
  ]
  @@show_columns = @@crud_columns + [:status]
  @@list_columns = [:image_url, :name, :status, :language_code, :country_code, :updated_at]

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
  active_scaffold :topic do |config|
    #--- columns
    config.columns = @@standard_columns
    config.create.columns = @@crud_columns
    config.update.columns = @@crud_columns
    config.show.columns = @@show_columns
    config.list.columns = @@list_columns

    config.create.multipart = true
    config.update.multipart = true
    
    #--- action links

    config.action_links.add @@activate_link
    config.action_links.add @@erase_link
    config.action_links.add @@toggle_suspend_link
    
    #--- labels
    columns[:image_url].label = "Image"
    columns[:country_code].label = "Country"
    columns[:language_code].label = "Language"
    
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
