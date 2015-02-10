class CommentsAddLogin < ActiveRecord::Migration

  def self.up
    add_column :comments, :created_admin_user_id, :int
  end

  def self.down
    remove_column :comments, :created_admin_user_id
  end
  
end
