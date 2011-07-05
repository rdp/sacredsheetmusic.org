class AddIsVoicing < ActiveRecord::Migration

  def self.up
    add_column :tags, :is_voicing, :boolean, :default => false
  end

  def self.down
    remove_column :tags, :is_voicing
  end
  
end
