class Admin::ReputationRewardsController < Admin::AdminApplicationController
  
  #--- active scaffold
  active_scaffold :reputation_reward do |config|
    #--- columns
    standard_columns = [
      :id,
      :tier,
      :source_class,
      :beneficiary_type,
      :action,
      :points,
      :funding_source,
      :created_at,
      :updated_at
    ]
    crud_columns = [
      :source_class,
      :beneficiary_type,
      :action,
      :points
    ]
    config.columns = standard_columns
    config.create.columns = crud_columns
    config.update.columns = crud_columns
    config.show.columns = crud_columns
    config.list.columns = [:source_class, :beneficiary_type, :action, :points]
  end
  
end
