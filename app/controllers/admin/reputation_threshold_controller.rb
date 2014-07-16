class Admin::ReputationThresholdController < Admin::AdminApplicationController

  cache_sweeper :reward_rates_sweeper
  
  #--- active scaffold
  active_scaffold :reputation_threshold do |config|
    #--- columns
    standard_columns = [
      :id,
      :tier,
      :source_class,
      :action,
      :points,
      :funding_source,
      :created_at,
      :updated_at
    ]
    crud_columns = [
      :action,
      :points,
    ]
    config.columns = standard_columns
    config.create.columns = crud_columns
    config.update.columns = crud_columns
    config.show.columns = crud_columns
    config.list.columns = [:action, :points]
  end
  
end
