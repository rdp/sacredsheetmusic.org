class AdminUserAddComposerTag < ActiveRecord::Migration

  def self.up
    add_column :users, :composer_tag_id, :int, :default => nil
  end

  def self.down
    remove_column :users, :composer_tag_id
  end
  
end
