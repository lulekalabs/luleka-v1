class UpdateTiersWithReputationColumns < ActiveRecord::Migration
  def self.up
    add_column :tiers, :accept_person_total_reputation_points, :boolean, :null => false, :default => true
    add_column :tiers, :accept_default_reputation_threshold, :boolean, :null => false, :default => false
    add_column :tiers, :accept_default_reputation_points, :boolean, :null => false, :default => false
  end

  def self.down
    remove_column :tiers, :accept_person_total_reputation_points
    remove_column :tiers, :accept_default_reputation_threshold
    remove_column :tiers, :accept_default_reputation_points
  end
end
