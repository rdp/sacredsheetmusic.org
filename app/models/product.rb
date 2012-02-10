require_dependency RAILS_ROOT + "/vendor/plugins/substruct/app/models/product"

class Product < Item
  has_many :comments, :dependent => :destroy
  has_and_belongs_to_many :tags, :order => :name
  
  # different ranking...
  has_many :images,
    :through => :product_images, :order => "-product_images.rank DESC",
    :dependent => :destroy

  def sync_all_parent_tags # check parent tags that should be checked but weren't
    tags = self.tags + self.tags.select{|t| t.parent}.map{|t| t.parent}
     tags.each{|t|
      if t.parent && t.parent.products.count > 0 && !t.parent.id.in?(self.tag_ids)
        self.tags << t.parent
      end
    }
  end

  def composer_tag
   composer_tags[0]
  end

  def composer_tags
   self.tags.select{|t| t.is_composer_tag? }
  end
  
  def hymn_tag
   self.tags.select{|t| t.is_hymn_tag? }[0]
  end

  def original_tag
   self.tags.select{|t| t.is_original_tag? }[0]
  end 

  def composer_contact_url
     composer = composer_tag
     cc = (composer && composer.composer_contact.present? ) ? composer.composer_contact : nil
     cc = "mailto:" + cc if cc =~ /.@./
     cc
  end
  
  # my own version :P
  def tag_ids=(list)
    tags.clear
    for id in list
      if !id.to_s.empty?
        tags << Tag.find(id) if !id.to_s.empty?
      end
    end
  end

  # Inserts code from product name if not entered.
  # Makes code safe for URL usage.
  # called via a before_save :clean_code
  def clean_code
    if self.code.blank?
      if self.composer_tag
        self.code = self.name.clone + '-by-' + self.composer_tag.name
      else
        self.code = self.name.clone
      end
    end
#    self.code.upcase!
    self.code.gsub!(/[^[:alnum:]']/,'-') # non alnum => -, except ' s
    self.code.gsub!(/-{2,}/,'-') # -- => -
    self.code.gsub!(/^[-]+/,'') # beginning dash
    self.code.gsub!(/[-]+$/,'') # ending dash
    self.code.strip!
    return true
  end

  def topic_tags
    tags.select{|t| t.is_topic_tag?}
  end

  def hymn_tags
    tags.select{|t| t.is_hymn_tag?}
  end

  def self.super_sum
    count = 0; all.each{|dl| count += dl.view_count}; count
  end

  def pdf_download_count
    sum = 0;downloads.each{|d| sum += d.count if d.name =~ /\.pdf$/i}
    sum
  end

  def clear_my_cache
    Cache.delete_all(:parent_id => self.id) # can't even do this in an after_save {} because of view_count being incremented so frequently...well I guess I could...
  end

  after_save { Cache.delete_by_type('group_products') } # can't do clear_my_cache, guess this is singleton...

  def is_five_star?
   if self.comments.map(&:overall_rating).select{|rating| rating > -1}.ave >= 4.5
     true
   else
     false
   end
  end

  def cached_find_problems
    out = Cache.get_or_set_int(self.id, 'probs', 'probs') {
      find_problems
    }
    if out =~ /---/
     YAML.load out # rails' auto-yaml'ing is a bit odd here...
    else
     out
    end
  end

  def duplicate_download_md5s
    downloads.map{|dl| `md5sum #{dl.full_absolute_path}`.split[0]}.dups
  end

  def duplicate_download_lengths
    downloads.map{|dl| 
      if File.exist? dl.full_absolute_path
        File.size dl.full_absolute_path
      else
        -1
      end
    }.dups
  end

  def find_problems
      problems = []
      if duplicate_download_lengths.length > 0
        if duplicate_download_md5s.length > 0
            problems << "possibly has duplicate downloads accidentally"
        end
      end
      if self.topic_tags.length == 0
        problems << "no topics associated with song yet."
      end

      # disallow SAB and SATB
      distinct_voicing_tags = self.tags.select{|t| (t.parent && t.parent.name =~ /choir|ensemble/i) || (t.name =~ /solo/i && t.children.length == 0)}.reject{|t| t.name =~ /choir.*instrument/}.reject{|t| t.name =~ /obbligato|with choir|choir and/i}
      if distinct_voicing_tags.length > 1
        problems << "has dual voicing (#{distinct_voicing_tags.map(&:name).join(',')}), possibly needs to be split?"
      end
      if !self.hymn_tag && !self.tags.detect{|t| t.name =~ /original/i}
        problems <<  "no hymn or 'original' tag for this song yet."
      end
      if self.downloads.size == 0 && !self.original_url.present?
        problems << "song has no original_url nor pdf uploads! Not expected I don't think..."
      end
      if self.original_url.present? && !self.original_url.start_with?("http")
        problems << "original url should start with http://"
      end
      if self.original_url =~ /\.(pdf|mp3|mid|midi)/
        problems << "original url looks like its a pdf but should be htmlish"
      end
      if !self.tags.detect{|t| t.is_voicing}
        problems << "Warning: no voicing [youth, SATB, piano solo, etc.] seemingly found"
      end
      if self.composer_tag && self.composer_tag.composer_contact !~ /@/
        problems << "Possibly lacking an original_url?" unless self.original_url.present?
      end
      if self.composer_tag && self.composer_tag.composer_url.present? && self.composer_tag.composer_contact !~ /http/
         problems << "composer probably needs to not use an email address for contact info"
      end
      if (count = Product.count(:conditions => {:code => self.code})) != 1
        problems << "probably not a unique product code please update #{count}"
      end
      if self.hymn_tag && self.name != self.hymn_tag.name && (self.hymn_tags.length == 1) && self.name !~ /original version/i && self.hymn_tag.name !~ /theme/i
         problems << "possibly mispelled [doesnt match hymn--might be expected/capitalization]--#{self.hymn_tag.name}"
      end
      unless self.composer_tag
         problems << "song has no composer tag?"
      end
      if (piano = self.tags.detect{|t| t.name =~ /piano/i && (t.children.size==0) && t.name !~ /accompaniment/}) && (choir = self.tags.detect{|t| t.name =~ /choir/i})
         problems << "song has BOTH piano #{piano.name} and choir #{choir.name} tags--probably not expected"
      end
      if self.composer_tag && !self.composer_tag.composer_contact.present?
         problems << "composer associated with this song has not contact info?"
      elsif self.composer_tag && (self.composer_tag.composer_contact !~ /@/ && !self.composer_tag.composer_contact.start_with?('http'))
         problems << "composer associated with this song might have bad url, should start with http?"
      end
      if !self.hymn_tag && (t = Tag.find_by_name(self.name) )
         unless t.id.in? self.tag_ids
           problems << "song probably should be tagged with hymn name, or topic [there is a tag that matches its title #{self.name}]"
         end
      end
      for download in downloads
        if download.filename !~ /\.(pdf|mid|midi|mp3|wav|wave|mscz|wma|mus|m4a)$/i
          problems << "might have bad download file #{download.filename}, unknown extension"
        end 
      end
      for tag in self.tags
        if tag.children.length > 0
          if (tag.child_ids - self.tag_ids).length == tag.child_ids.length
            problems << "might need a child tag beneath #{tag.name}, or for that tag to be removed possibly"
          end
        end
      end
      problems.map{|p| "warning:" + p}
  end

  def linkable_tags user
    if user
      tags # all :)
    else
      tags.select{|t| !t.is_hymn_tag?}.reject{|t| (t.child_ids - self.tag_ids) != t.child_ids}.reject{|t| t.is_original_tag?}
     end
  end

end
