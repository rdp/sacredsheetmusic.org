#require_dependency RAILS_ROOT + "/vendor/plugins/substruct/app/models/download"

# just in case...
require 'tempfile'

class Tempfile
  def size
    if @tmpfile
      @tmpfile.fsync
      @tmpfile.flush
      @tmpfile.stat.size
    else
      0
    end
  end
end

class Download < UserUpload # user_uploads table...

  MAX_SIZE = 120.megabyte

  def relative_path_to_web_server
    full_filename.gsub(RAILS_ROOT + "/public", "")
  end
  def full_absolute_path
    full_filename
  end

  def self.super_sum
    all.inject(0) {|sum, dl| sum += dl.count; sum}
  end

  has_attachment(
    :storage => :file_system,
    :max_size => MAX_SIZE,
    :thumbnails => { :thumb => '50x50>', :small => '200x200' }, # only applies to images anyway, so we're good there
    :processor => 'MiniMagick',
    :path_prefix => 'public/system/'
  )
  
  has_many :product_downloads, :dependent => :destroy
  has_one :product, :through => :product_downloads
  
  # avoid validates_as_attachment, which forces it to be an attachment
  # huh? what?
end
