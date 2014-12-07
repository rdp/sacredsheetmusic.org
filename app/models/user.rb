require_dependency RAILS_ROOT + "/vendor/plugins/substruct/app/models/user"

class User
  belongs_to :tag # has a reference to a tag
end
