class UpdateTopicsWithIndices < ActiveRecord::Migration
  def self.up
    add_index :topics, :tier_id
    add_index :topics, :uuid
    add_index :topics, :people_count
    add_index :topics, :kases_count
    add_index :topics, :created_by_id
    add_index :topics, :type
    add_index :topics, :permalink
    add_index :topics, :internal
    add_index :topics, :status
    add_index :topics, :country_code
    add_index :topics, :language_code
    add_index :topics, :name
  end

  def self.down
    remove_index :topics, :tier_id
    remove_index :topics, :uuid
    remove_index :topics, :people_count
    remove_index :topics, :kases_count
    remove_index :topics, :created_by_id
    remove_index :topics, :type
    remove_index :topics, :permalink
    remove_index :topics, :internal
    remove_index :topics, :status
    remove_index :topics, :country_code
    remove_index :topics, :language_code
    remove_index :topics, :name
  end
end
