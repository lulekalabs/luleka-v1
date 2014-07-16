class UpdatePeopleKasesCount < ActiveRecord::Migration
  def self.up
    change_column :people, :kases_count, :integer, :default => 0
  end

  def self.down
  end
end
