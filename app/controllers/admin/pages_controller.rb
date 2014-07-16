# Controller manages all static Web content
class Admin::PagesController < Admin::AdminApplicationController
  cache_sweeper :pages_sweeper

  #--- active scaffold
  active_scaffold :pages do |config|
    #--- columns
    standard_columns = [
      :id,
      :title,
      :title_de,
      :title_es,
      :permalink,
      :content,
      :layout,
      :dom_id,
      :dom_class,
      :markdown,
      :textile
    ]
    crud_columns = [
      :title,
      :permalink,
      :content,
      :layout,
      :dom_id,
      :dom_class,
      :markdown,
      :textile
    ]
    config.columns = standard_columns
    config.create.columns = crud_columns
    config.update.columns = crud_columns
    config.show.columns = crud_columns
    config.list.columns = [:title, :permalink, :layout]

    config.columns[:markdown].form_ui = :checkbox
    config.columns[:textile].form_ui = :checkbox
    
    #--- labels
    config.columns[:dom_id].label        = "DOM id"
    config.columns[:dom_class].label     = "DOM class"
    
  end

  protected
  
  def before_create_save(record)
    record.attributes = params[:record]
  end
  
  def before_update_save(record)
    record.attributes = params[:record]
  end

  def list_authorized?
    current_user && current_user.has_role?(:copywriter)
  end

  def create_authorized?
    current_user && current_user.has_role?(:copywriter)
  end

  def update_authorized?
    current_user && current_user.has_role?(:copywriter)
  end

  def delete_authorized?
    current_user && current_user.has_role?(:copywriter)
  end
  
end
