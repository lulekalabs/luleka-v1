class Admin::ResponsesController < Admin::AdminApplicationController

  #--- active scaffold
  active_scaffold :responses do |config|
    #--- columns
    standard_columns = [
      :id,
      :person,
      :kase,
      :description,
      :language_code,
      :status,
      :comments,
      :created_at,
      :updated_at
    ]
    crud_columns = [:description, :language_code, :comments]
    config.columns = standard_columns
    config.show.columns = crud_columns
    config.list.columns = [:person, :status, :description]
    config.subform.columns = [:person, :description, :language_code]
    
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
