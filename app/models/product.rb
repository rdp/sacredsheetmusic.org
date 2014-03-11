require_dependency RAILS_ROOT + "/vendor/plugins/substruct/app/models/product"

class Product < Item
  has_many :comments, :dependent => :destroy
  has_and_belongs_to_many :tags, :order => :name

  CONDITIONS_AVAILABLE = %Q/
      CURRENT_DATE() >= DATE(items.date_available)
      AND items.price = 0.0
      AND items.is_discontinued = 0
      OR (items.is_discontinued = 1 AND (items.quantity > 0 OR items.variation_quantity > 0))
  /  

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

  # Is this product new?
  def is_new?
    weeks_new = Preference.get_value('product_is_new_week_range')
    weeks_new ||= 1
    self.date_available >= (weeks_new.to_i).weeks.ago
  end

  def composer_tag
    composer_tags[0]
  end

  def composer_tags
    self.tags.select{|t| t.is_composer_tag? }.sort_by{|t| t.name =~ /church pub/i ? 1 : 0 }
  end
  
  def hymn_tag
    self.tags.select{|t| t.is_hymn_tag? }[0]
  end

  def original_tag
    self.tags.select{|t| t.is_original_tag? }[0]
  end 

  def voicing_tags
    self.tags.select{|t| t.is_voicing? }
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

  def composer_generic_contact_url 
    composer_tag.andand.get_composer_contact_url
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
    if self.code.blank? || self.code == "auto_refresh_me_dupe"
      if self.composer_tag 
        if voicing = self.voicing_tags[0]
          voicing_name = voicing.name
          voicing_name = voicing_name.split('/')[0] # prefer "violin" of "violin/violin-obbligatto-as-accompaniment"
          voicing_name = voicing_name.split(/ or /i)[0] # prefer "Youth Choir" from "youth choir or..."
          self.code = self.name.clone + '-' + voicing_name + '-by-' + self.composer_tag.name
        else
          raise 'please setup voicing tags first (use back button on browser) or manually enter a product code for it'
        end
      else
        raise 'please setup a composer first (use back button on browser) or manually enter a product code for it'
      end
    end
#    self.code.upcase! # too ugly!
    self.code.gsub!("'", '')
    self.code.gsub!(/[\x80-\xff]/, '') # take care of freaky apostrophe's etc.
    self.code.gsub!(/[^[:alnum:]']/,'-') # non alnum => -, except ' s
    self.code.gsub!(/-{2,}/,'-') # -- => -
    self.code.gsub!(/^[-]+/,'') # strip beginning dashes
    self.code.gsub!(/[-]+$/,'') # strip ending dashes
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
    Cache.delete_all(:parent_id => self.id) # could do this in an after_save {} now, except it's a singleton method? <sigh>
    #Product.delete_group_caches # ??
    Cache.clear_local_caches! # it has some old junk in it too, like saved product boxes...clear it for everybody
    Rails.logger.info "NOT clearing local cache fiels for this..."
    for tag in self.tags
      #tag.clear_public_cached
    end
  end
  
  after_save { |p| 
    p.clear_my_cache
    # Rails.logger.info "NOT clearing cache for this!"
  } 

  def self.delete_group_caches
    Cache.delete_by_type('group_products') 
    Cache.delete_by_type('tags') # if date_available has changed, we're changed here to...
  end

  def total_competition_points
    self.comments.select{|c| c.overall_rating > -1}.select{|c| c.is_competition? }.map(&:overall_rating).sum
  end

  def total_valid_competition_points 
    end_time = Preference.competition_end_time
    self.comments.select{|c| c.overall_rating > -1}.select{|c| c.is_competition? }.select{|c| c.created_at < end_time}.map(&:overall_rating).sum
  end

  def peer_reviews
    self.comments.select{|c| c.is_competition? && c.overall_rating > -1 && (c.comment.size > 100 || (c.created_session == "e28b3a0a6a48843c9e476c34a117980d"))}
  end

  def competition_peer_review_average
    comments = peer_reviews
    if comments.size > 0
      comments.map{|c| c.overall_rating}.ave
    else
      0 # avoid returning NaN for the average of an empty array :)
    end
  end

  def is_five_star?
   if self.comments.select{|c| !c.is_competition?}.map(&:overall_rating).select{|rating| rating > -1}.ave >= 4.5
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
        if !composer_tag.composer_contact_url.present?
          if !composer_tag.only_on_this_site
            problems << "since its composer has no contact web page, composer tag probably wants the only_on_this_site attribute"
          end
          # no web page...
        end
      end

      if self.original_url.present? && self.composer_tags.detect{|t| t.only_on_this_site}
        problems << "one of its composers may be marked as only on this site in vain?"
      end

      if !self.original_url.present? && !self.composer_tags.detect{|t| t.only_on_this_site}
        problems << "may want its composer tag to be marked only on this site, since this song lacks an original url"
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
        if tag.composer_contact_url.present? && tag.composer_contact_url =~ bad_whitespace_reg
          problems << "tag composer contact url has beginning or trailing whitespace?" + tag.name
        end

      end
      
      # disallow SAB and SATB on same song
      distinct_voicing_tags = self.tags.select{|t| (t.parent && t.parent.name =~ /^choir|ensemble/i) || (t.name =~ /solo/i && t.name !~ /choir/i && t.children.length == 0)}.reject{|t| t.name =~ /choir.*instrument/}.reject{|t| t.name =~ /obbligato|with choir|choir and|song type|accompan/i}
      if distinct_voicing_tags.length > 1 && !self.tags.detect{|t| t.name =~ /cantata/i}
        problems << "has dual voicing (#{distinct_voicing_tags.map(&:name).join(',')}), possibly needs to be split?"
      end

      if self.tags.select{|t| t.is_hymn_tag?}.size > 1 && !self.tags.detect{|t| t.name =~ /medley/i}
        problems << "might be lacking the medley tag"
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
          if true
            require 'open-uri' # like calling out to curl/wget kind of...
            begin
              # doesn't work within BH?
              a = open(self.original_url)
              got = a.read
              a.close
              raise OpenURI::HTTPError.new("hello", "k?") if got =~ /Not Found/ # lindy kerby uses 302 redirs yikes
            rescue Exception => e
              problems << "original url is bad? #{e} #{self.original_url}"
            end
           end
        end
      end

      #topic_tags = Tag.find_by_name( "Topics", :include => :children).children
      #instrument_tags = Tag.find_by_name("Instrumental", :include => :children).children
      for topic_tag in Tag.all#topic_tags + instrument_tags
        next if topic_tag.name.in? ['Choir', 'ST', 'SA', 'Christ', 'Work', 'Music', 'Piano', 'Original'] # too common false positives :)
        for topic_tag_name in topic_tag.name.split('/')
          topic_tag_name.strip!
          next if topic_tag_name.downcase == 'accompaniment' # don't want to match violin/accompaniment with anything that mentions accompaniment
          bare_name_reg = Regexp.new(Regexp.escape(topic_tag_name), Regexp::IGNORECASE)
          name_reg =  Regexp.new("\\W" + Regexp.escape(topic_tag_name) + "\\W", Regexp::IGNORECASE)
          if (self.name =~ bare_name_reg) || (self.description.andand.gsub('font-family', '') =~ name_reg)
            if !self.tags.detect{|t| t.id == topic_tag.id}
              problems << "might want the #{topic_tag.name} tag, since its name #{topic_tag_name} is included in the title or description"
            end
          end 
        end
      end
      
      for product in Product.find_all_by_name(self.name)
        next if product.id == self.id
        if product.tags.map(&:id).sort == self.tags.map(&:id).sort
          problems << "this song is possibly a duplicate of another song--id #{product.id}"
        end
      end
      
      if self.original_url =~ /\.(pdf|mp3|mid|midi)/i 
        problems << "original url looks like its non htmlish" unless self.original_url =~ /lds.org/ # some pdf ok
      end
      if self.voicing_tags.length == 0
        problems << "Warning: no voicing [youth, SATB, piano solo, etc.] seemingly found"
      end
      if self.composer_tag && self.composer_tag.composer_contact_url.present?
        problems << "Possibly lacking an original_url?" unless self.original_url.present?
      end
      if (count = Product.count(:conditions => {:code => self.code})) != 1
        problems << "probably not a unique product code please update #{count}"
      end
      if self.hymn_tag && self.name != self.hymn_tag.name && (self.hymn_tags.length == 1) && self.name !~ /original/i && self.hymn_tag.name !~ /theme/i && !self.name.contain?(hymn_tag.name)
         if !self.hymn_tag.name.include?('/') && !self.hymn_tag.name.include?('(') && (self.hymn_tags.length == 1) && !self.description.include?(self.hymn_tag.name)
           problems << "possibly mispelled [doesnt match hymn--might be expected/capitalization]--#{self.hymn_tag.name}"
         end
      end
      unless self.composer_tag
         problems << "song has no composer tag?"
      end
      if (piano = self.tags.detect{|t| t.name =~ /piano/i && (t.children.size==0) && t.name !~ /accompaniment/}) && (choir = self.tags.detect{|t| t.name =~ /choir/i})
         problems << "song has BOTH piano #{piano.name} and choir #{choir.name} tags--probably not expected"
      end

      if composer_tag = self.composer_tag

        if !composer_tag.composer_contact_url.present? && !composer_tag.composer_email_if_contacted.present?
          problems << "composer tag associated with this song has not contact info?"
        elsif composer_tag.composer_contact_url.present? && !composer_tag.composer_contact_url.start_with?('http')
           problems << "composer tag associated with this song might have bad url, should start with http?"
        elsif composer_tag.composer_url.present? && !composer_tag.composer_url.start_with?('http')
          problems << "composer_url probably wants to start with http?"
        end

        if composer_tag.composer_url.present? && !composer_tag.composer_contact_url.present?
          problems << "composer has a url but not contact url? they probably want one set..."
        end

        if composer_tag.composer_email_if_contacted.andand.contain?("mailto:")
          problems << "composer tag email_if_contacted should not contain mailto in it!"
        end
        
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
            if tag.name !~ /original|solo/i
              problems << "might need a child tag beneath #{tag.name}, or for that tag to be removed possibly"
            end
          end
        end
      end
      problems.map{|p| "warning:" + p}
  end

  def linkable_tags user
    if user
      tags.reject{|t| t.is_topic_tag?} # don't care as much about those...more voicing...
    else
      tags.select{|t| !t.is_hymn_tag?}.reject{|t| (t.child_ids - self.tag_ids) != t.child_ids}.reject{|t| t.is_original_tag?}.sort_by{|t| 
         if t.is_voicing?
           if t.name =~ /^[A-Z]+$/
            0 # SATB
           else
            1 # Harmonica
           end
         elsif t.is_composer_tag?
           2
         elsif t.is_topic_tag?
           3
         else
           4
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
