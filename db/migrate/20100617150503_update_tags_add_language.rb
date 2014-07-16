class UpdateTagsAddLanguage < ActiveRecord::Migration
  def self.up
    add_column :tags, :language_code, :string, :limit => 2
    add_index :tags, :language_code
  end

  def self.down
    remove_column :tags, :language_code
  end
end
