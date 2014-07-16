class UpdateKasesAddRewardsCount < ActiveRecord::Migration
  def self.up
    add_column :kases, :rewards_count, :integer, :default => 0
  end

  def self.down
    remove_column :kases, :rewards_count
  end
end
