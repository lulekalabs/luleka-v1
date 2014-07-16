class UpdateKasesAddAnonymous < ActiveRecord::Migration
  def self.up
    add_column :kases, :anonymous, :boolean, :default => false
    add_index :kases, :anonymous
  end

  def self.down
    remove_column :kases, :anonymous
  end
end
