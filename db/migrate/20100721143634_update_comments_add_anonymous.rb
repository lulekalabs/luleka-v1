class UpdateCommentsAddAnonymous < ActiveRecord::Migration
  def self.up
    add_column :comments, :anonymous, :boolean, :default => false
    add_index :comments, :anonymous
  end

  def self.down
    remove_column :comments, :anonymous
  end
end
