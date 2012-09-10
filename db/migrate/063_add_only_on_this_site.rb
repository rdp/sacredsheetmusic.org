class AddOnlyOnThisSite < ActiveRecord::Migration

  def self.up
    add_column :tags, :only_on_this_site, :boolean, :default => false
  end

  def self.down
    remove_column :tags, :only_on_this_site
  end
  
end
