class <%= class_name %> < ActiveRecord::Migration  # >
  def self.up
    create_table :visits do |t|
      t.column :visitor_id, :integer 
      t.column :visited_id, :integer
      t.column :visited_type, :string
      t.column :created_at, :datetime
    end
    add_index :visits, :visitor_id
    remove_index :visits, :column => [:visited_id, :visited_type]
  end

  def self.down
    drop_table :visits
  end
end
