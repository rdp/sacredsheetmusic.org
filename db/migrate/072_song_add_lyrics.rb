class SongAddLyrics < ActiveRecord::Migration
  def self.up
    add_column :product, :lyrics, :string_value, :longtext, :default => nil 
  end
 
  def self.down
    remove_column :product, :lyrics
  end
end
