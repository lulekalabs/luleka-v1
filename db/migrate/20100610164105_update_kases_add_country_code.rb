class UpdateKasesAddCountryCode < ActiveRecord::Migration
  def self.up
    add_column :kases, :country_code, :string
    add_index :kases, :country_code
  end

  def self.down
    remove_column :kases, :country_code
  end
end
