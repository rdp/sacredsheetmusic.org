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
   self.tags.select{|t| t.parent && (t.parent.name =~ /^Hymn/i || t.parent.name =~ /arrangements$/i) }[0]
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
 # too strong!after_save { Cache.delete_all }
  def find_problems
      problems = []
      if self.topic_tags.length == 0
        problems << "Warning: no topics associated with song yet."
      end
      if !self.hymn_tag && !self.tags.detect{|t| t.name =~ /original/i}
        problems <<  "Warning: no hymn or 'original' tag for this song yet."
      end
      if self.downloads.length == 0 && !self.original_url.present?
        problems << "Warning: song has no original_url nor uploads! Not expected I don't think..."
      end
      if self.original_url.present? && !self.original_url.start_with?("http")
        problems << "original url should start with http://"
      end
      if self.original_url =~ /\.(pdf|mp3|mid|midi)/
        problems << "original url looks like its a pdf but should be htmlish"
      end
      if !self.tags.detect{|t| t.is_voicing}
        problems << "Warning: no voicing [youth, SATB, etc.] seemingly found"
      end
      if self.composer_tag && self.composer_tag.composer_contact !~ /@/
        problems << "Possibly lacking an original_url?" unless self.original_url.present?
      end
      if self.hymn_tag && self.name != self.hymn_tag.name
         problems << "possibly mispelled [doesnt match hymn--might be expected/capitalization]"
      end
      if self.composer_tag && !self.composer_tag.composer_contact.present?
         problems << "composer associated with this song has not contact info?"
      end
      problems
  end

end
