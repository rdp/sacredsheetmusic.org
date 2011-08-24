class CacheAddParent < ActiveRecord::Migration
  def self.up
    add_column :cache, :parent_id, :bigint
  end
 
  def self.down
    remove_column :cache, :parent_id
  end
end
