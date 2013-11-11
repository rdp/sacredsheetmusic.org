class CreateCache < ActiveRecord::Migration
  def self.up
    add_index  :cache, :parent_id
  end
 
  def self.down
    remove_index :cache, :parent_id
  end
end
