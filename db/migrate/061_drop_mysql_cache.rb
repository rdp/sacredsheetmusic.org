class DropMysqlCache < ActiveRecord::Migration
  def self.up
    drop_table :cache
  end
 
  def self.down
    raise 'huh?'
  end
end
