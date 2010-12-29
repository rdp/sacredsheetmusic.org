require_dependency RAILS_ROOT + "/vendor/plugins/substruct/app/models/product"

class Product < Item
  has_many :comments, :dependent => :destroy
end
