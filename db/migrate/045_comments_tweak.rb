class CommentsTweak < ActiveRecord::Migration

  def self.up		
		add_column :comments, :user_name, :string
		add_column :comments, :user_email, :string
		add_column :comments, :user_url, :string
		add_column :comments, :overall_rating, :integer
		add_column :comments, :difficulty_rating, :integer
  end

  def self.down
    remove_column :comments, :user_name
    remove_column :comments, :user_email
    remove_column :comments, :user_url
    remove_column :comments, :overall_rating
    remove_column :comments, :difficulty_rating
  end
  
end
