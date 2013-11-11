class SongAddLyrics < ActiveRecord::Migration
  def self.up
    add_column :items, :lyrics, :longtext, :default => nil 
  end
 
  def self.down
    remove_column :items, :lyrics
  end
end
