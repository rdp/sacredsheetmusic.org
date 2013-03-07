class ResetDefaults < ActiveRecord::Migration

  def self.up
    change_column :comments, :overall_rating, :int, :default => -1
  end

  def self.down
    raise 'huh'
  end
  
end
