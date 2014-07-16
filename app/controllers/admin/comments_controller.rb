class Admin::CommentsController < Admin::AdminApplicationController
=begin
  #--- active scaffold
  active_scaffold :comments do |config|
    #--- columns
    standard_columns = [
      :id,
      :person,
      :message,
      :language_code,
      :status,
      :commentable,
      :created_at,
      :updated_at
    ]
    crud_columns = [:message, :language_code]
    config.columns = standard_columns
    config.show.columns = crud_columns
    config.list.columns = [:status, :description]
    config.subform.columns = [:person, :message, :language_code]    
    
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
=end  
end
