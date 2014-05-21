class ProductAddThumbnailHtml < ActiveRecord::Migration

  def self.up
    add_column :items, :thumbnail_html_cache, :longtext, :default => nil
  end

  def self.down
    remove_column :items, :thumbnail_html_cache
  end
  
end
