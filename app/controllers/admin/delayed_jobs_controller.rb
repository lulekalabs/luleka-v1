class Admin::DelayedJobsController < Admin::AdminApplicationController

  #--- active scaffold
  active_scaffold "Delayed::Job" do |config|
    #--- columns
    standard_columns = [
      :id,
      :priority,
      :attempts,
      :handler,
      :last_error,
      :run_at,
      :schedule,
      :period,
      :locked_at,
      :failed_at,
      :locked_by,
      :created_at,
      :updated_at
    ]
    crud_columns = []
    config.columns = standard_columns
    config.show.columns = crud_columns
    config.list.columns = [
      :priority,
      :attempts,
      :handler,
      :last_error,
      :run_at,
      :schedule,
      :period,
      :locked_by,
      :locked_at,
      :failed_at,
      :created_at,
      :updated_at
    ]
    
    #--- scaffold actions
    config.actions.exclude :create
    config.actions.exclude :update
    config.actions.exclude :show
    
    config.label = "Job Schedule"
  end  
  
  protected
  
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
