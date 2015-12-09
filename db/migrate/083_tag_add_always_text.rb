class TagAddAlwaysText < ActiveRecord::Migration

  def self.up
    add_column :tags, :text_for_every_song_for_composer, :string
  end

  def self.down
    remove_column :tags, :text_for_every_song_for_composer
  end
  
end
