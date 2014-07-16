class CreateReputations < ActiveRecord::Migration
  def self.up
    create_table :reputations do |t|
      t.integer :reputable_id
      t.string :reputable_type
      t.integer :sender_id
      t.integer :receiver_id
      t.string :action
      t.integer :points, :default => 0
      t.string :status, :default => "created", :limit => 40
      t.datetime :activated_at
      t.datetime :closed_at
      t.timestamps
    end
    add_index :reputations, [:reputable_id, :reputable_type]
    add_index :reputations, :sender_id
    add_index :reputations, :receiver_id
  end

  def self.down
    drop_table :reputations
  end
end
