require_dependency RAILS_ROOT + "/vendor/plugins/substruct/app/models/download"

class Download < UserUpload

  MAX_SIZE = 120.megabyte

  def relative_path_to_web_server
    full_filename.gsub(RAILS_ROOT + "/public", "")
  end

  has_attachment(
    :storage => :file_system,
    :max_size => MAX_SIZE,
    :thumbnails => { :thumb => '50x50>', :small => '200x200' }, # only applies to images anyway, so we're good there
    :processor => 'MiniMagick',
    :path_prefix => 'public/system/'
  )

end