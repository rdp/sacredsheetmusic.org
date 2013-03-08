class CommentRatingDefaultNegativeOne < ActiveRecord::Migration

  def self.up
    change_column :comments, :overall_rating, :int, :default => -1
    Comment.all.select{|c| c.overall_rating == nil}.each{|c| c.overall_rating = -1; c.save}
  end

  def self.down
    raise 'huh'
  end
  
end
