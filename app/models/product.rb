require_dependency RAILS_ROOT + "/vendor/plugins/substruct/app/models/product"

class Product < Item
  has_many :comments, :dependent => :destroy
  
  has_many :images,
    :through => :product_images, :order => "-product_images.rank DESC",
    :dependent => :destroy
  
  #
  # the arranger tag for this product...if there is one...
  def composer
   self.tags.select{|t| t.parent && t.parent.name =~ /composer/i }[0]
  end
  
  def composer_contact
     owner = composer
     cc = (owner && owner.composer_contact.present? ) ? owner.composer_contact : nil
     cc = "mailto:" + cc if cc =~ /.@./
     cc
  end
  
  # my own version :P
  def tag_ids=(list)
    tags.clear
    for id in list
      tags << Tag.find(id) if !id.to_s.empty?
    end
  end

  # Inserts code from product name if not entered.
  # Makes code safe for URL usage.
  def clean_code
    if self.code.blank?
      if self.composer
        self.code = self.composer.name # composer full name?
      else
        self.code = self.name.clone 
      end
    end
    self.code.upcase!
    self.code = self.code.gsub(/[^[:alnum:]]/,'-').gsub(/-{2,}/,'-')
    self.code = self.code.gsub(/^[-]/,'').gsub(/[-]$/,'')
    self.code.strip!
    return true
	end


end
