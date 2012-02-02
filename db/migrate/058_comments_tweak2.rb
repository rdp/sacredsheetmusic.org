class CommentsTweak2 < ActiveRecord::Migration
  def self.up
    change_column :comments, :comment, :text
  end

  def self.down
    change_column :comments, :comment, :string
  end
  
end
