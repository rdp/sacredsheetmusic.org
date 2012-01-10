class TagAddIndexName < ActiveRecord::Migration

  def self.up
    add_column :tags, :name_in_nav, :string
  end

  def self.down
    remove_column :tags, :name_in_nav
  end
  
end
