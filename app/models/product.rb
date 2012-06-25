require_dependency RAILS_ROOT + "/vendor/plugins/substruct/app/models/product"

class Product < Item
  has_many :comments, :dependent => :destroy
  has_and_belongs_to_many :tags, :order => :name
  
  # different ranking...
  has_many :images,
    :through => :product_images, :order => "-product_images.rank DESC",
    :dependent => :destroy

  def sync_all_parent_tags # check parent tags that should be checked but weren't
    tags = self.tags + self.tags.select{|t| t.parent}.map{|t| t.parent} # plus parent to go 2 deep here
    tags.each{|t|
      if t.products.size > 0 && t.parent && t.parent.products.size > 0 && !t.parent.id.in?(self.tag_ids)
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

  def self.find_by_tag_ids(tag_ids, find_available=true, order_by="items.name DESC")
                sql = ''
                #sql << "FROM items "
                #sql << "JOIN products_tags on items.id = products_tags.product_id "
                sql << "WHERE products_tags.tag_id IN (#{tag_ids.join(",")}) "
                sql << "AND #{CONDITIONS_AVAILABLE}" if find_available==true
                sql << "GROUP BY items.id HAVING COUNT(*)=#{tag_ids.length} "
                sql << "ORDER BY #{order_by};" # :order => 'items.name ASC'
#                find_by_sql(sql)
     find(:all, :include => [:tags], :conditions => [sql])
  end


   # products = Product.find(:all, :include => [:tags],
   #   :order => 'items.name ASC', :conditions => conds
   # )

  def composer_contact_url 
    composer_tag.get_composer_contact_url
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

  def remove_tag_id id # guess there's also a tags= method but...hmm...using ruby-like Arrays to manage this stuff is a bit scary...
    raise unless id.is_a? Fixnum
    self.tag_ids=self.tag_ids.select{|id2| id2 != id}
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
#    self.code.upcase! # too ugly
    self.code.gsub!("'", '')
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
    Cache.delete_all(:parent_id => self.id) # could do this in an after_save {} now, except it's a singleton method <sigh>
    Product.delete_group_caches
  end

  after_save {  # singleton!
    Product.delete_group_caches
  } 

  def self.delete_group_caches
    Cache.delete_by_type('group_products') 
    Cache.delete_by_type('tags') # if date_available has changed, we're changed here to...
  end

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

  def find_problems expensive=true# true until I can figure out what in the world I am doing wrong here...
      problems = []
      if expensive && duplicate_download_lengths.length > 0
        if duplicate_download_md5s.length > 0
          problems << "possibly has duplicate downloads accidentally"
        end
      end

      if self.topic_tags.length == 0
        problems << "no topics associated with song yet."
      end
      if self.original_tag && self.hymn_tag
        problems << "is tagged with both original and hymn? possibly wants to be just hymn tag" unless self.description =~ /original/i
      end

      for composer_tag in self.composer_tags
        if composer_tag.products.detect{|p| p.tags.detect{|t| t.name =~ /only on this site/i} }
          if !self.tags.detect{|t| t.name =~ /only on this site/i}
             problems << "probably needs the only on this site tag, since its composer has others only on this site"
          end
        end
        if composer_tag.composer_contact !~ /^http/
          if !self.tags.detect{|t| t.name =~ /only on this site/i}
            problems << "probably needs the only on this site tag, since its composer has no web page, or fix the composer tag"
          end
          # no web page...
        end
      end

      if self.tags.detect{|t| t.name =~ /only on this site/i} && self.original_url.present?
         problems << "probably does not want the only on this site tag, since it has an original url"
      end

      bad_whitespace_reg = /^\s|\s$/
      for string in [self.name, self.original_url, self.code]
        if string.present? && string =~ bad_whitespace_reg
          problems << "#{string} has some extra beginning or trailing whitespace?"
        end
      end

      for tag in self.tags
        if tag.name =~ bad_whitespace_reg
          problems << "tag has beginning or trailing whitespace?" + tag.name
        end
        if tag.composer_contact.present? && tag.composer_contact =~ bad_whitespace_reg
          problems << "tag composer contact has beginning or trailing whitespace?" + tag.name
        end

      end
      
      # disallow SAB and SATB on same song
      distinct_voicing_tags = self.tags.select{|t| (t.parent && t.parent.name =~ /^choir|ensemble/i) || (t.name =~ /solo/i && t.name !~ /choir/i && t.children.length == 0)}.reject{|t| t.name =~ /choir.*instrument/}.reject{|t| t.name =~ /obbligato|with choir|choir and|song type/i}
      if distinct_voicing_tags.length > 1
        problems << "has dual voicing (#{distinct_voicing_tags.map(&:name).join(',')}), possibly needs to be split?"
      end
      for download in self.downloads
       problems << "has empty download?" + download.filename unless download.size > 0
      end
      if !self.hymn_tag && !self.tags.detect{|t| t.is_original_tag? }
        problems <<  "no hymn or 'original' tag for this song yet."
      end
      if self.downloads.size == 0 && !self.original_url.present?
        problems << "song has no original_url nor pdf uploads! Not expected I don't think..."
      end
      if self.original_url.present? 
        if !self.original_url.start_with?("http")
          problems << "original url should start with http://"
        else
          if false
            require 'open-uri'
            begin
              # doesn't work within BH?
              a = open(self.original_url)
              got = a.read
              a.close
              raise OpenURI::HTTPError.new("hello", "k?") if got =~ /Not Found/ # lindy kerby uses 302 redirs yikes
            rescue OpenURI::HTTPError
              problems << "original url is now a 404?"
            end
           end
        end
      end

      #topic_tags = Tag.find_by_name( "Topics", :include => :children).children
      #instrument_tags = Tag.find_by_name("Instrumental", :include => :children).children
      for topic_tag in Tag.all#topic_tags + instrument_tags
        next if topic_tag.name.in? ['Christ', 'Work', 'Music', 'Piano', 'Original'] # too common false positives :)
        for topic_tag_name in topic_tag.name.split('/')
          topic_tag_name.strip!
          bare_name_reg = Regexp.new(Regexp.escape(topic_tag_name), Regexp::IGNORECASE)
          name_reg =  Regexp.new("\\W" + Regexp.escape(topic_tag_name) + "\\W", Regexp::IGNORECASE)
          if (self.name =~ bare_name_reg) || (self.description.andand.gsub('font-family', '') =~ name_reg)
            if !self.tags.detect{|t| t.id == topic_tag.id}
              problems << "might want the #{topic_tag.name} tag, since its name is included in the title or description"
            end
          end 
        end
      end
      
      if self.original_url =~ /\.(pdf|mp3|mid|midi)/i 
        problems << "original url looks like its non htmlish" unless self.original_url =~ /lds.org/ # some pdf ok
      end
      if !self.tags.detect{|t| t.is_voicing}
        problems << "Warning: no voicing [youth, SATB, piano solo, etc.] seemingly found"
      end
      if self.composer_tag && self.composer_tag.composer_contact !~ /@/
        problems << "Possibly lacking an original_url?" unless self.original_url.present?
      end
      if self.composer_tag && self.composer_tag.composer_url.present? && self.composer_tag.composer_contact !~ /http/
         problems << "composer probably needs to not use an email address for contact info, since they probably have some contact url they could use instead"
      end
      if (count = Product.count(:conditions => {:code => self.code})) != 1
        problems << "probably not a unique product code please update #{count}"
      end
      if self.hymn_tag && self.name != self.hymn_tag.name && (self.hymn_tags.length == 1) && self.name !~ /original/i && self.hymn_tag.name !~ /theme/i
         if !self.hymn_tag.name.include?('/') && !self.hymn_tag.name.include?('(') && (self.hymn_tags.length == 1)
           problems << "possibly mispelled [doesnt match hymn--might be expected/capitalization]--#{self.hymn_tag.name}"
         end
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
           unless self.description =~ /original/i
             problems << "song probably should be tagged with hymn name, or topic [there is a tag that matches its title #{self.name}]"
           end
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
      tags.select{|t| !t.is_hymn_tag?}.reject{|t| (t.child_ids - self.tag_ids) != t.child_ids}.reject{|t| t.is_original_tag?}.reject{|t| t.name =~ /only on this site/i}.sort_by{|t| 
         if t.is_voicing?
           1
         elsif t.is_composer_tag?
           2
         else
           3
         end
       }
     end
  end

  def add_tag_unless_already_there t
    unless tag_ids.include?(t.id)
      tags << t
    end
    tags
  end

end
