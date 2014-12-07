class AdminUserAddComposerTag < ActiveRecord::Migration

  def self.up
    add_column :users, :tag_id, :int, :default => false
  end

  def self.down
    remove_column :users, :tag_id
  end
  
end
