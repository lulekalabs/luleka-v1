class UpdatePeopleAddShowName < ActiveRecord::Migration
  def self.up
    add_column :people, :show_name, :boolean, :default => true
  end

  def self.down
    remove_column :people, :show_name
  end
end
