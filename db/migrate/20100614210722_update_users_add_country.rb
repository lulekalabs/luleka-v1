class UpdateUsersAddCountry < ActiveRecord::Migration
  def self.up
    add_column :users, :country, :string, :limit => 2
    add_index :users, :country
    
    #--- update country information
    User.all.each do |user|
      user.update_attribute(:country, user.person ? user.person.default_country : "US")
    end
  end

  def self.down
    remove_column :users, :country
  end
end
