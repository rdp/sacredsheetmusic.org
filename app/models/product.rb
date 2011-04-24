require_dependency RAILS_ROOT + "/vendor/plugins/substruct/app/models/product"

class Product < Item
  has_many :comments, :dependent => :destroy
  
  # different ranking...
  has_many :images,
    :through => :product_images, :order => "-product_images.rank DESC",
    :dependent => :destroy
  
  # the arranger tag for this product...if there is one...
  def composer_tag
   self.tags.select{|t| t.parent && t.parent.name =~ /^composer/i }[0]
  end
  
  def hymn_tag
   self.tags.select{|t| t.parent && t.parent.name == 'Hymns' }[0]
  end
  
  def composer_contact
     owner = composer_tag
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
      if self.composer_tag
        self.code = self.name.clone + '-' + self.composer_tag.name # do we want the composer full name?
      else
        self.code = self.name.clone
      end
    end
#    self.code.upcase!
    self.code = self.code.gsub(/[^[:alnum:]]/,'-').gsub(/-{2,}/,'-')
    self.code = self.code.gsub(/^[-]/,'').gsub(/[-]$/,'')
    self.code.strip!
    return true
  end

  def topic_tags
    tags.select{|t| t.parent && t.parent.name == "Topics"}
  end

  # for manual use, currently...
  def self.all_songs_without_topics
    self.all.select{|p| p.topic_tags.length == 0}
  end

  def self.super_sum
    count = 0; all.each{|dl| count += dl.view_count}; count
  end
end
