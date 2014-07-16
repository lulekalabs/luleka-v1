class DropDiscussionTypes < ActiveRecord::Migration
  def self.up
    drop_table :discussion_types
  end

  def self.down
    create_table "discussion_types", :force => true do |t|
      t.string   "kind",       :limit => 25, :null => false
      t.string   "name",       :limit => 65, :null => false
      t.string   "name_de",    :limit => 65
      t.datetime "created_at"
      t.datetime "updated_at"
      t.string   "name_es",    :limit => 65
    end
  end
end
