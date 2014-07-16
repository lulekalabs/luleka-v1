class UpdateResponsesAddAnonymous < ActiveRecord::Migration
  def self.up
    add_column :responses, :anonymous, :boolean, :default => false
    add_index :responses, :anonymous
  end

  def self.down
    remove_column :responses, :anonymous
  end
end
