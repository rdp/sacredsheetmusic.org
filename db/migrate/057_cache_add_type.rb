class CacheAddType < ActiveRecord::Migration
  def self.up
    add_column :cache, :cache_type, :string
    Cache.clear!
  end
 
  def self.down
    remove_column :cache, :cache_type
  end
end
