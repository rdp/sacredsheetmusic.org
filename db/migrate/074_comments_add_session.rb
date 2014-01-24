class CommentsAddSession < ActiveRecord::Migration

  def self.up
    add_column :comments, :created_session, :string
  end

  def self.down
    remove_column :comments, :created_session
  end
  
end
