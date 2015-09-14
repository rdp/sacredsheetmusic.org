class ProductDownloadConstraints < ActiveRecord::Migration
  # this is the annoying thing where they could get out of sync/whack and have a "nil" download for one of a song's downloads. yikes.

  def self.up
    execute <<-SQL
  ALTER TABLE product_downloads
    ADD CONSTRAINT fk_product_downloads_to_download
    FOREIGN KEY (download_id)
    REFERENCES user_uploads(id)
SQL
  end

  def self.down
    raise "unimplemented"
  end
  
end
