# Academic titles editing
class Admin::AcademicTitlesController < Admin::AdminApplicationController
  
  #--- active scaffold
  active_scaffold :academic_title do |config|
    #--- columns
    standard_columns = [
      :id,
      :name
    ]
    crud_columns = [
      :name
    ]
    config.columns = standard_columns
    config.create.columns = crud_columns
    config.update.columns = crud_columns
    config.show.columns = crud_columns
    config.list.columns = [:name]
  end

  def index
    render :template => 'admin/spoken_languages/index'
  end
  
end
