class UpdateKasesRemoveOfferRelated < ActiveRecord::Migration
  def self.up
    remove_column :kases, :assigned_at
    remove_column :kases, :assigned_person_id
    remove_column :kases, :time_to_solve
    remove_column :kases, :started_at
    remove_column :kases, :auctioned_at
    remove_column :kases, :offer_type_id
    remove_column :kases, :offer_audience_type_id
    remove_column :kases, :discussion_type_id
    remove_column :kases, :current_bid_cents
    remove_column :kases, :max_price_cents
    remove_column :kases, :fixed_price_cents
    remove_column :kases, :category_id
  end

  def self.down
    add_column :kases, :assigned_at, :datetime
    add_column :kases, :assigned_person_id, :integer
    add_column :kases, :time_to_solve, :integer
    add_column :kases, :started_at, :datetime
    add_column :kases, :auctioned_at, :datetime
    add_column :kases, :offer_type_id, :integer
    add_column :kases, :offer_audience_type_id, :integer
    add_column :kases, :discussion_type_id, :integer
    add_column :kases, :current_bid_cents, :integer
    add_column :kases, :max_price_cents, :integer
    add_column :kases, :fixed_price_cents, :integer
    add_column :kases, :category_id, :integer
  end
end
