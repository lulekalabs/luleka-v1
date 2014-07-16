class CreateAdminRoles < ActiveRecord::Migration
  def self.up
    create_table :admin_roles do |t|
      t.column "kind", :string, :null => false
      t.column "name", :string
      t.column "description", :string
      t.timestamps
    end
    add_index :admin_roles, :kind
    add_index :admin_roles, :name
    
    create_table :admin_roles_admin_users, :id => false, :force => true do |t|
      t.column "admin_role_id", :integer
      t.column "admin_user_id", :integer
    end
    add_index :admin_roles_admin_users, [:admin_role_id, :admin_user_id]
    
  end

  def self.down
    drop_table :admin_roles
    drop_table :admin_roles_admin_users
  end
end
