class UpdateKasesWithIndices < ActiveRecord::Migration
  def self.up
    add_index :kases, :person_id
    add_index :kases, :title
    add_index :kases, :status
    add_index :kases, :visits_count
    add_index :kases, :comments_count
    add_index :kases, :happened_at
    add_index :kases, :votes_count
    add_index :kases, :up_votes_count
    add_index :kases, :down_votes_count
    add_index :kases, :votes_sum
    add_index :kases, :views_count
    add_index :kases, :responses_count
    add_index :kases, :followers_count
    add_index :kases, :rewards_count
  end

  def self.down
    remove_index :kases, :person_id
    remove_index :kases, :title
    remove_index :kases, :status
    remove_index :kases, :visits_count
    remove_index :kases, :comments_count
    remove_index :kases, :happened_at
    remove_index :kases, :votes_count
    remove_index :kases, :up_votes_count
    remove_index :kases, :down_votes_count
    remove_index :kases, :votes_sum
    remove_index :kases, :views_count
    remove_index :kases, :responses_count
    remove_index :kases, :followers_count
    remove_index :kases, :rewards_count
  end
end
