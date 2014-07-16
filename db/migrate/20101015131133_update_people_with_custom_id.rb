class UpdatePeopleWithCustomId < ActiveRecord::Migration
  def self.up
    add_column :people, :custom_id, :string
  end

  def self.down
    remove_column :people, :custom_id
  end
end
