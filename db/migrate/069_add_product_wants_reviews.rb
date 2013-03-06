class AddProductWantsReviews < ActiveRecord::Migration

  def self.up
    add_column :items, :wants_reviews, :boolean, :default => false
  end

  def self.down
    remove_column :items, :wants_reviews
  end
  
end
