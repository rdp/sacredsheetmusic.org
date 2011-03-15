require_dependency RAILS_ROOT + "/vendor/plugins/substruct/app/models/product"

class Product < Item
  has_many :comments, :dependent => :destroy
  
  has_many :images,
    :through => :product_images, :order => "-product_images.rank DESC",
    :dependent => :destroy
    
  def composer_contact
     owner = self.tags.select{|t| t.parent && t.parent.name =~ /composer/i }[0]
     cc = (owner && owner.composer_contact.present? ) ? owner.composer_contact : nil
     cc = "mailto:" + cc if cc =~ /.@./
     cc
  end
  
end
