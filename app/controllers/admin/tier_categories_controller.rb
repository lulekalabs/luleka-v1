# Tier categories scaffold, for editing Tier sub types, e.g. Company, Government, etc.
class Admin::TierCategoriesController < Admin::AdminApplicationController

  #--- active scaffold
  active_scaffold :tier_category do |config|
    #--- columns
    standard_columns = [
      :id,
      :kind,
      :super_type,
      :name
    ]
    crud_columns = [
      :super_type,
      :kind,
      :name
    ]
    config.columns = standard_columns
    config.create.columns = crud_columns
    config.update.columns = crud_columns
    config.show.columns = crud_columns
    config.list.columns = [:kind, :name, :super_type]
  end

  def index
    render :template => 'admin/spoken_languages/index'
  end

end
