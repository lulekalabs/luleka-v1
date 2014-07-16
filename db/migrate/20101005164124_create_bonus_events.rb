class CreateBonusEvents < ActiveRecord::Migration
  def self.up
    create_table :bonus_events do |t|
      t.integer :source_id
      t.string :source_type
      t.integer :receiver_id
      t.string :receiver_type
      t.integer :sender_id
      t.string :sender_type
      t.string :action
      t.string :type
      t.string :status, :default => "created"
      t.integer :tier_id
      t.string :description
      t.datetime :cashed_at
      t.datetime :closed_at
      t.timestamps
    end
    add_index :bonus_events, [:source_id, :source_type]
    add_index :bonus_events, [:receiver_id, :receiver_type]
    add_index :bonus_events, [:sender_id, :sender_type]
    add_index :bonus_events, :tier_id
  end

  def self.down
    drop_table :bonus_events
  end
end
