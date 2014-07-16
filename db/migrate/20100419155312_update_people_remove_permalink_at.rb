class UpdatePeopleRemovePermalinkAt < ActiveRecord::Migration
  def self.up
    remove_column :people, :permalink_at
  end

  def self.down
    add_column :people, :permalink_at, :datetime
  end
end
