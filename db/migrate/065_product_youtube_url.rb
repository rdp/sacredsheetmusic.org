class ProductYoutubeUrl < ActiveRecord::Migration

  def self.up
    add_column :items, :youtube_video_id, :string, :default => nil
  end

  def self.down
    remove_column :items, :youtube_video_id
  end
  
end
