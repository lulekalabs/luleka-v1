class UpdateTiersWithIndices < ActiveRecord::Migration
  def self.up
    add_index :tiers, :name
    add_index :tiers, :name_es
    add_index :tiers, :status
    add_index :tiers, :permalink
    add_index :tiers, :kases_count
    add_index :tiers, :members_count
    add_index :tiers, :topics_count
    add_index :tiers, :people_count
    add_index :tiers, :uuid
  end

  def self.down
    remove_index :tiers, :name
    remove_index :tiers, :name_es
    remove_index :tiers, :status
    remove_index :tiers, :permalink
    remove_index :tiers, :kases_count
    remove_index :tiers, :members_count
    remove_index :tiers, :topics_count
    remove_index :tiers, :people_count
    remove_index :tiers, :uuid
  end
end
