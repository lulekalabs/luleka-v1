class UpdatePeopleChangeColumnShowName < ActiveRecord::Migration
  def self.up
    change_column :people, :show_name, :boolean, :default => false
  end

  def self.down
    change_column :people, :show_name, :boolean, :default => true
  end
end
