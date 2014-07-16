class Admin::FlagsController < Admin::AdminApplicationController

  #--- active scaffold
  active_scaffold :flags do |config|
    #--- columns
    standard_columns = [
      :id,
      :flaggable,
      :flaggable_user,
      :user,
      :reason,
      :description,
      :created_at,
      :updated_at
    ]
    crud_columns = [:reason, :description]
    config.columns = standard_columns
    config.show.columns = crud_columns
    config.list.columns = [:flaggable, :flaggable_user, :user, :reason, :description, :created_at]
    
    #--- scaffold actions
    config.actions.exclude :create
    config.actions.exclude :update
  end  
  
  protected
  
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
