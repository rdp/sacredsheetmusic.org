class ProductRedirectCount < ActiveRecord::Migration

  def self.up
    add_column :items, :redirect_count, :int, :default => 0
  end

  def self.down
    remove_column :items, :redirect_count
  end
  
end
