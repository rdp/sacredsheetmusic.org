class CommentsRatingToFloat < ActiveRecord::Migration

  def self.up
    change_column :comments, :overall_rating, :float 
  end

  def self.down
    raise "Unimplemented"
  end
  
end
