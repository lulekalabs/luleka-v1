class UpdateUsersWithResetCode < ActiveRecord::Migration
  def self.up
    add_column :users, :reset_code, :string
    add_index :users, :reset_code
  end

  def self.down
    remove_column :users, :reset_code
  end
end
