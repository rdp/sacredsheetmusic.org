class AllowNilPriceForItems < ActiveRecord::Migration
  def self.up
    change_column :items, :price, :float, :null => true
  end

  def self.down
    change_column :items, :price, :float, :default => 0.0, :null => false
  end
end