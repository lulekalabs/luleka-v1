class ActsAsAddressableMigration < ActiveRecord::Migration
  def self.up
    create_table :addresses, :force => true do |t|
      t.column :addressable_id, :integer, :null => false
      t.column :addressable_type, :string, :null => false
      t.column :type, :string
      t.column :gender, :string
      t.column :street, :text
      t.column :city, :string
      t.column :postal_code, :string
      t.column :province, :string
      t.column :province_code, :string
      t.column :country, :string
      t.column :country_code, :string
      t.column :company_name, :string
      t.column :first_name, :string
      t.column :middle_name, :string
      t.column :last_name, :string
      t.column :note, :text
      t.column :phone, :string
      t.column :mobile, :string
      t.column :fax, :string
      # timestamp
      t.column :created_at, :datetime
      t.column :updated_at, :datetime
    end
    add_index :addresses, [:addressable_id, :addressable_type]
    add_index :addresses, :type
    add_index :addresses, :city
    add_index :addresses, :province
    add_index :addresses, :province_code
    add_index :addresses, :country
    add_index :addresses, :country_code
    add_index :addresses, :gender
    add_index :addresses, :first_name
    add_index :addresses, :middle_name
    add_index :addresses, :last_name
    add_index :addresses, :company_name
    add_index :addresses, :phone
    add_index :addresses, :mobile
    add_index :addresses, :fax
  end
  
  def self.down
    drop_table :addresses
  end
end
