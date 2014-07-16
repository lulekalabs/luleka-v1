class CreateRewardRates < ActiveRecord::Migration
  def self.up
    create_table :reward_rates do |t|
      t.integer :tier_id
      t.string :source_class  # "Response"
      t.string :beneficiary_type # "sender" or "receiver"
      t.string :action  # "vote_up"
      t.integer :cents
      t.integer :points
      t.float :percent
      t.integer :max_events_per_month
      t.integer :funding_source_id
      t.string :type
      t.timestamps
    end
    add_index :reward_rates, :source_class
    add_index :reward_rates, :tier_id
    add_index :reward_rates, :funding_source_id
    add_index :reward_rates, :type
  end

  def self.down
    drop_table :reward_rates
  end
end
