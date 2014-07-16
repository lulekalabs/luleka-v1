class Admin::SpokenLanguagesController < Admin::AdminApplicationController
  
  #--- active scaffold
  active_scaffold :spoken_language do |config|
    #--- columns
    standard_columns = [
      :id,
      :code,
      :name,
      :native_name
    ]
    crud_columns = [
      :code,
      :name,
      :native_name
    ]
    config.columns = standard_columns
    config.create.columns = crud_columns
    config.update.columns = crud_columns
    config.show.columns = crud_columns
    config.list.columns = [:code, :name, :native_name]
  end
  
  #--- actions
  
  def index
  end
  
end
