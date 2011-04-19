class ProductCount < ActiveRecord::Migration

  def self.up
    add_column :items, :view_count, :int, :default => 1
  end

  def self.down
    remove_column :items, :count
  end
  
end
