class ProductAddUpdated < ActiveRecord::Migration

  def self.up
    add_timestamps(:items)
  end

  def self.down
    raise "unimplemented"
  end
  
end
