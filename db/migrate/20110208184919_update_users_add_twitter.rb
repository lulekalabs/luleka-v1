class UpdateUsersAddTwitter < ActiveRecord::Migration
  def self.up
    add_column :users, :twitter_id, :integer
    add_column :users, :twitter_access_token, :string
    add_column :users, :twitter_access_secret, :string
    add_column :users, :twitter_profile_image_url, :string
    add_index :users, :twitter_id
    add_index :users, :twitter_access_token
    add_index :users, :twitter_access_secret
  end

  def self.down
    remove_column :users, :twitter_id
    remove_column :users, :twitter_access_token
    remove_column :users, :twitter_access_secret
    remove_column :users, :twitter_profile_image_url
  end
end
