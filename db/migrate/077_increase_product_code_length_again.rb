# Make product / item codes longer. 100 chars is not enough
class IncreaseProductCodeLengthAgain < ActiveRecord::Migration
  def self.up
    change_column :items, :code, :string, :limit => 1000, :default => '', :null => false
  end
  
  def self.down
    change_column :items, :code, :string, :limit => 100, :default => '', :null => false
  end
end
