class UpdateTiersWithAcceptDefaultReputationThreshold < ActiveRecord::Migration
  def self.up
    change_column :tiers, :accept_default_reputation_threshold, :boolean, :default => true
    change_column :tiers, :accept_default_reputation_points, :boolean, :default => true
  end

  def self.down
    change_column :tiers, :accept_default_reputation_threshold, :boolean, :default => false
    change_column :tiers, :accept_default_reputation_points, :boolean, :default => false
  end
end
