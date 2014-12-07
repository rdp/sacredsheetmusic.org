require_dependency RAILS_ROOT + "/vendor/plugins/substruct/app/models/user"

class User
  belongs_to :composer_tag, :class_name => 'Tag' # has a reference to a tag
end
