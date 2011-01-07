require_dependency RAILS_ROOT + "/vendor/plugins/substruct/app/models/product"

class Product < Item
  has_many :comments, :dependent => :destroy
  has_many :images,
    :through => :product_images, :order => "-product_images.rank DESC",
    :dependent => :destroy
end
