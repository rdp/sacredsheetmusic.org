require_dependency RAILS_ROOT + "/vendor/plugins/substruct/app/models/download"

class Download < UserUpload

  def relative_path_to_web_server
    full_filename.gsub(RAILS_ROOT + "/public", "")
  end

end