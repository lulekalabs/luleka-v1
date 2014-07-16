class Admin::SeveritiesController < Admin::AdminApplicationController
  
  #--- active scaffold
  active_scaffold :severity do |config|
    #--- columns
    standard_columns = [
      :id,
      :weight,
      :kind,
      :name,
      :feeling,
      :created_at,
      :updated_at,
    ]
    crud_columns = [
      :kind,
      :name,
      :feeling,
      :weight
    ]
    config.columns = standard_columns
    config.create.columns = crud_columns
    config.update.columns = crud_columns
    config.show.columns = crud_columns
    config.list.columns = [:kind, :name, :feeling]
  end
  
  def index
    render :template => 'admin/spoken_languages/index'
  end
  
end
