class UpdateKontextsWithIndices < ActiveRecord::Migration
  def self.up
    add_index :kontexts, :tier_id
    add_index :kontexts, :topic_id
  end

  def self.down
    remove_index :kontexts, :tier_id
    remove_index :kontexts, :topic_id
  end
end
