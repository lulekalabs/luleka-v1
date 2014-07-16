class UpdateUsersAddFb < ActiveRecord::Migration
  def self.up
    add_column :users, :fb_user_id, :integer
    add_column :users, :fb_email_hash, :string
    execute("ALTER TABLE users MODIFY fb_user_id bigint")
  end

  def self.down
    remove_column :users, :fb_user_id
    remove_column :users, :fb_email_hash
  end
end
