class UpdatePeopleWithReputationPoints < ActiveRecord::Migration
  def self.up
    add_column :people, :reputation_points, :integer, :default => 0
    add_index :people, :reputation_points
  end

  def self.down
    remove_column :people, :reputation_points
  end
end
