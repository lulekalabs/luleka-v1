class UpdateTiersWithGroups < ActiveRecord::Migration
  def self.up
    add_column :tiers, :owner_email, :string
    add_column :tiers, :access_type, :string, :default => "open", :null => false
    add_column :tiers, :allow_display_in_directory, :boolean, :default => true, :null => false
    add_column :tiers, :allow_display_logo_in_profile, :boolean, :default => true, :null => false
    add_column :tiers, :allow_member_invites, :boolean, :default => false, :null => false
    
    add_index :tiers, :access_type
    add_index :tiers, :owner_email
    add_index :tiers, :allow_display_in_directory
    add_index :tiers, :allow_display_logo_in_profile
  end

  def self.down
    remove_column :tiers, :owner_email
    remove_column :tiers, :access_type
    remove_column :tiers, :allow_display_in_directory
    remove_column :tiers, :allow_display_logo_in_profile
    remove_column :tiers, :allow_member_invites
  end
end
