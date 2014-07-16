class Admin::BonusRewardsController < Admin::AdminApplicationController
  
  #--- active scaffold
  active_scaffold :bonus_reward do |config|
    #--- columns
    standard_columns = [
      :id,
      :tier,
      :source_class,
      :beneficiary_type,
      :action,
      :cents,
      :percent,
      :max_events_per_month,
      :funding_source,
      :created_at,
      :updated_at
    ]
    crud_columns = [
      :source_class,
      :beneficiary_type,
      :action,
      :cents,
      :percent,
      :max_events_per_month,
      :funding_source,
    ]
    config.columns = standard_columns
    config.create.columns = crud_columns
    config.update.columns = crud_columns
    config.show.columns = crud_columns
    config.list.columns = [:source_class, :beneficiary_type, :action, :cents]
  end
  
end
