class CreateRewards < ActiveRecord::Migration
  def self.up
    create_table :rewards do |t|
      t.integer :kase_id
      t.integer :sender_id
      t.integer :receiver_id

      t.string :status, :default => "created", :limit => 40
      t.integer :cents
      t.string :currency, :limit => 3
      
      t.datetime :expires_at
      t.datetime :activated_at
      t.datetime :paid_at
      t.datetime :closed_at
      t.timestamps
    end
    add_index :rewards, :kase_id
    add_index :rewards, :sender_id
    add_index :rewards, :receiver_id
    add_index :rewards, :status
  end

  def self.down
    drop_table :rewards
  end
end
