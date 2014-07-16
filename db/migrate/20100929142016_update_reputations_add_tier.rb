class UpdateReputationsAddTier < ActiveRecord::Migration
  def self.up
    add_column :reputations, :tier_id, :integer
    add_index :reputations, :tier_id
  end

  def self.down
    remove_column :reputations, :tier_id
  end
end
