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

  def next_image_rank_to_use
     max = self.product_images.select{|pi| pi.rank}.map{|pi| pi.rank}.max
     next_rank = max ? max + 1 : 0 # accomodate for no rank before
  end

  private
  def reset_html_cache
    FileUtils.rm_rf thumbnail_filename
  end

  def thumbnail_filename
    RAILS_ROOT + "/public/cache_song_square/#{self.id}"
  end
  public

  def get_or_generate_thumbnail_cache # takes a block
    # TODO reload here, in case a different process already beat us to it? how do I profile test this hmm...
    if !File.exist? thumbnail_filename
      File.write(thumbnail_filename, yield)
    end
    File.read(thumbnail_filename)
  end

  def sync_all_parent_tags # check parent tags that should also be checked but weren't -- this is not topic syncing!
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

  def available?
    date_available < Time.now
  end

  def persisted?
    !new_record?
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

  def is_original?
    original_tag # nil if not there...
  end 

  def voicing_tags
    self.tags.select{|t| t.is_voicing? }
  end

  def composer_generic_contact_url 
    composer_tag.andand.get_composer_contact_url
  end
  
  # my own version :P
  def tag_ids=(list)
    tags.clear
    for id in list
      if !id.to_s.empty?
        tags << Tag.find(id)
      end
    end
  end

  def remove_tag_id id # guess there's also a tags= method but...hmm...using ruby-like Arrays to manage this stuff is a bit scary...
    raise unless id.is_a? Fixnum
    self.tag_ids=self.tag_ids.select{|id2| id2 != id}
  end

  # Inserts code from product name if not entered.
  # Makes code safe for URL usage.
  # called via a before_save :clean_code in some substruct code
  def clean_code
    if self.youtube_video_id.present?
      if self.youtube_video_id =~ /(http|https):\/\//
        if self.youtube_video_id =~ /=/
          # https://www.youtube.com/watch?v=rwWNkTVRN8Y&feature=you.tube -> rwWNkTVRN8Y
          self.youtube_video_id = self.youtube_video_id.split('=')[1].split("&")[0]
        elsif self.youtube_video_id =~ /youtu\.be/
          # https://youtu.be/dNAIQtajBNQ
          self.youtube_video_id = self.youtube_video_id.split("/")[-1]
        else
          raise "unknown youtube url try using a more standard one like https://www.youtube.com/watch?v=rwWNkTVRN8Y"
        end
      else
        # assume it's already an ID...
      end
    end

    if self.code.blank? || self.code == "auto_refresh_me_dupe"
      if self.composer_tag 
        if self.voicing_tags.size > 0 && self.name.present?
          # auto assign a code, all the pieces are there
          voicing_name = self.voicing_tags[0].name # don't use more than one in case they accidentally initially tag it as SATB SAB though for instrumental it might be nice to have "violin and cello" gah...maybe we should do more here, like auto-recode them at save time [?]
          if voicing_name.contain?('/')
            parts = voicing_name.split('/')
            if parts[0].split(' ')[0] == parts[1].split(' ')[0]
              voicing_name = parts[0].split(' ')[0] # prefer violin to violin duet, given violin duet/ensemble
            else
              voicing_name = parts[0] # prefer "violin" to "violin/violin-obbligatto-as-accompaniment"
            end
          end
          voicing_name = voicing_name.split(/ or /i)[0] # prefer "Youth Choir" from "youth choir or..."
          self.code = self.name.clone + ' ' + voicing_name + ' by ' + self.composer_tag.name
        else
          if self.voicing_tags.size == 0
            raise 'please check some voicing options first (like "vocal solo" or SATB, or an instrument--use back button on browser to proceed) (if no voicing options match, please tell us!)'
          end
          if !self.name.present?
            # only possible if they forgot to enter a name, or forgot to tag it with an arrangement checkbox
            raise "If this song is an original, please use the back arrow in your browser and enter a song name.  If it is an arrangement, please hit the back arrow in your browser and check a checkbox next to the name of that song it is an arrangement of (make sure you're entering it as a new arrangement song...)"
          else
            raise "we should never get here"
          end
        end
      else
        raise 'please select a composer first (use back button on browser)--no composer selected!'
      end
#      self.code.upcase! # too ugly!
      self.code.gsub!(/[^[:alnum:]']/, '_') # non alnum => _, except ' s
      self.code.gsub!("'", '') # judea-s => judeas
      self.code.gsub!(/[\x80-\xff]/, '') # take care of freaky unicode apostrophe's etc.
      self.code.gsub!(/_{2,}/, '_') # __ => _ (2 to 1)
      self.code.gsub!(/^[_]+/, '') # strip beginning dashes
      self.code.gsub!(/[_]+$/, '') # strip ending dashes
      self.code = self.code.strip
      if Product.find_by_code(self.code)
        Rails.logger.info "whoa, re-using a code? #{self.code} assigning it a numeric, this may be bad..." # I'm pretty sure composers use this though, hopefully helpful anyway....
        (1..100).each do |n|
          next_attempt = self.code + '_' + n.to_s
          if !Product.find_by_code(next_attempt)
            self.code = next_attempt
            break
          end
        end
      end
    end
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
    sum = 0
    pdf_downloads.each{|d| sum += d.count }
    sum
  end

  def clear_my_cache
    Cache.delete_all(:parent_id => self.id)
    #Product.delete_group_caches # ??
    Cache.clear_local_caches_restart_all_apps! # so we don't get an old warning box on some re-edits, but not others [yikes!]
    reset_html_cache
    clear_tag_caches = true # this is pretty heavy still [TODO why?]! default = true...
    if clear_tag_caches
      for tag in self.tags
        tag.clear_public_cached # since the name for this one has changed...is this enough even? if new songs were added, this will be enough...though orphan some cache entries assuming we still group cache... :|
        if tag.songs.count == 1 # just has this song
          tag.clear_cache_self # in case this is its first
          # product ever and, previous to this, it wasn't even shown on 
          # lists at all since it was empty... :|
        end
      end
    else
      Rails.logger.info "NOT clearing local cache fiels for this product, some things could get out of date..."
    end
  end
  
  after_save { |p| 
    p.clear_my_cache
  } 

  before_destroy { |p| # make deletes cleanup too
    p.clear_my_cache
  }

  def self.delete_group_caches
    Cache.delete_by_type('group_products') 
    Cache.delete_by_type('tags') # if date_available has changed, we're changed here to...
  end

  def total_valid_competition_points 
    competition_valid_reviews.map(&:overall_rating).sum
  end

  def competition_valid_reviews
    end_time = Preference.competition_end_time
    self.comments.select{|c| c.overall_rating > -1}.select{|c| c.is_competition? }.select{|c| c.created_at < end_time}
  end


  def peer_reviews
    competition_valid_reviews.select{|c| c.comment.size > 100 || c.created_admin_user} # blah XXXX
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
    downloads_no_nils.map{|dl| `md5sum #{dl.full_absolute_path}`.split[0]}.dups
  end

  def editable_by? user
    if user
      return user.is_admin? || (user.composer_tag && composer_tags.contain?(user.composer_tag))
    end
    false
  end

  def downloads_no_nils
    self.downloads.compact # <sigh> that this is the one necessary...database foreign key constraints for the win!
  end

  def pdf_downloads
    downloads_no_nils.select{|d| d.name =~ /\.pdf$/i }
  end

  def duplicate_download_lengths
    downloads_no_nils.map{|dl2| 
      if File.exist? dl2.full_absolute_path
        File.size dl2.full_absolute_path
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
        problems << "no topics associated with song yet. Under the \"topics\" section, below, please check mark any topics that apply to this song."
      end
      if self.is_original? && self.hymn_tag
        problems << "is tagged with both original and hymn? possibly wants to be just hymn tag" unless self.description =~ /original/i
      end

      if !self.original_url.present? && !self.composer_tags.detect{|t| t.only_on_this_site}
        problems << "this song may be lacking a website url to your website? please add one."
      end

      bad_whitespace_reg = /^\s|\s$/
      for string in [self.name, self.original_url, self.code]
        if string.present? && string =~ bad_whitespace_reg
          problems << "[#{string}] has some extra beginning or trailing whitespace? please remove any extra spaces"
        end
      end

      for tag in self.tags
        if tag.copyright_warning_message.present?
          problems << "WARNING: we have received a notice from a copyright holder in times past regarding arrangements of #{tag.name}.  You may need permission before you can publish it here:" + tag.copyright_warning_message
        end
        if tag.name =~ bad_whitespace_reg
          problems << "tag has beginning or trailing whitespace? [#{tag.name}] please remove extra spaces"
        end
        if tag.composer_contact_url.present? && tag.composer_contact_url =~ bad_whitespace_reg
          problems << "tag composer contact url has beginning or trailing whitespace?" + tag.name
        end

      end
      
      # disallow SAB and SATB on same song...bit confusing...[to me, people didn't like them split though...]
      # distinct_voicing_tags = self.tags.select{|t| t.is_voicing?}
      # cello and viola is ok though...XXXX better distinguish here!??

      #if distinct_voicing_tags.length > 1 && !self.tags.detect{|t| t.name =~ /cantata/i} # cantata's really can be SATB and SAB...
        # people didn't like this...TODO more
        #problems << "has multiple voicings (#{distinct_voicing_tags.map(&:name).join(',')}), if a song has various voicing options [ex: SATB or SAB], please add it multiple times, one for each voicing, for instance, one SATB, a different ont SAB (or in this case #{distinct_voicing_tags[0].name}, and another one #{distinct_voicing_tags[1].name}) if applicable."
      #end

      if self.tags.select{|t| t.is_hymn_tag?}.size > 1 && !self.tags.detect{|t| t.name =~ /medley/i}
        problems << "might want the the medley tag (under song attributes), please check it if so"
      end

      for download in self.downloads_no_nils
        problems << "has empty download?" + download.filename unless download.size > 0
        if download.filename =~ /\.wav$/i
          problems << "usually mp3 files are preferred over .wav files, please convert it to .mp3, upload it, and delete the .wav file"
        end
        if download.filename =~ /\.(mid|midi)$/i
          problems << "Usually mp3 files are preferred over .mid files, please convert it to .mp3 [http://solmire.com  has an auto conversion process you could use] and delete the .mid file"
        end
        if download.filename !~ /\.(pdf|mid|midi|mp3|wav|wave|mscz|wma|mus|m4a)$/i
          problems << "might have bad download file #{download.filename}, unknown extension"
        end
        if !File.exist? download.full_absolute_path
          problems << "might have corrupted download [file doesn't exist on server anymore?] " + download.filename
        else
          if File.size(download.full_absolute_path) != download.size
            problems << "has mismatch size with size on disk?" + download.filename
          end
        end
      end

      if !self.hymn_tag && !self.tags.detect{|t| t.is_original_tag? }
        problems <<  "no hymn or 'original' tag for this song yet."
      end

      if self.downloads.size == 0 && !self.original_url.present?
        problems << "song has no website url nor pdf uploads! Not expected I don't think..."
      end

      if self.original_url.present? 
        if !self.original_url.start_with?("http")
          problems << "website url may be malformed--should look like http://... (currently is \"#{self.original_url}\")"
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
              problems << "song website url (#{self.original_url}) does not seem to be correct-please make sure it is the right url by testing it in your browser! (error message was: #{e.to_s[0..200]}...)" # try not to repeat uri twice, too confusing, it may be in error message...
            end
           end
        end
      end

      if !self.hymn_tag && (t = Tag.find_by_name(self.name) )
         unless t.id.in? self.tag_ids
           unless self.description =~ /original/i
             if t.is_hymn_tag?
               problems << "song matches a hymn/song name #{self.name} perhaps it should be re-entered as an arrangement piece instead of an original?"
             else
               problems << "song matches a tag #{self.name}--possibly should tag it with that?"
             end
           end
         end
      end

      #topic_tags = Tag.find_by_name("Topics", :include => :children).children
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
              problems << "might want the \"#{topic_tag.name}\" tag added, since its name \"#{topic_tag_name}\" is included in the title or description"
            end
          end 
        end
      end
      
      for product in Product.find_all_by_name(self.name)
        next if product.id == self.id
        if product.tags.map(&:id).sort == self.tags.map(&:id).sort
          problems << "this song is possibly a duplicate of another song-id #{product.id}"
        end
      end
      
      if self.original_url =~ /\.(pdf|mp3|mid|midi)/i 
        problems << "original url looks like its non htmlish" unless self.original_url =~ /lds.org/ # some pdf ok on church site [that one book]
      end
      if self.voicing_tags.length == 0
        problems << "Warning: no voicing [youth, SATB, piano solo, etc.] seemingly found"
      end
      if self.composer_tag && self.composer_tag.composer_contact_url.present?
        problems << "Possibly lacking song URL website address?" unless self.original_url.present?
      end
      if (count = Product.count(:conditions => {:code => self.code})) != 1
        problems << "probably not a unique product code please update #{count}"
      end
      if self.hymn_tag && self.name != self.hymn_tag.name && (self.hymn_tags.length == 1) && self.name !~ /original/i && self.hymn_tag.name !~ /theme/i && !self.name.contain?(hymn_tag.name)
         if !self.hymn_tag.name.include?('/') && !self.hymn_tag.name.include?('(') && (self.hymn_tags.length == 1) && !self.description.include?(self.hymn_tag.name)
           problems << "possibly mispelled [doesnt match hymn- -might be expected/capitalization]- -#{self.hymn_tag.name}"
         end
      end
      unless self.composer_tag
         problems << "song has no composer tag?"
      end
      if (piano = self.tags.detect{|t| t.name =~ /piano/i && (t.children.size==0) && t.name !~ /accompaniment/}) && (choir = self.tags.detect{|t| t.name =~ /choir/i})
         problems << "song has BOTH piano #{piano.name} and choir #{choir.name} tags- -probably not expected"
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
          problems << "composer has a url but not contact url? they probably want one set, unless their web site does not have any contact information for them...-please report this to us!"
        end

        if composer_tag.composer_email_if_contacted.andand.contain?("mailto:")
          problems << "composer tag email_if_contacted should not contain mailto in it!"
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
      if self.code =~ /-\d+$/
        problems << "this song might have been a duplicate of another like it, since it code ends in a number #{self.code} might be worth double checking if it's an accidental duplicate or not"
      end

      problems.map{|p| "song advice:" + p}
  end

  def linkable_tags logged_in_user
    if logged_in_user
      tags.reject{|t| t.is_topic_tag?} # don't care as much about those...more voicing, etc, and show everything...
    else
      tags.select{|t| !t.is_hymn_tag?}.reject{ |t| 
        (t.child_ids - self.tag_ids) != t.child_ids # reject it if we have a child also linked
      }.reject{|t| 
        t.is_original_tag?
      }.sort_by { |t| 
         if( t.is_voicing? || t.name =~ /vocal solo/i )
           if t.name =~ /^[A-Z]+$/
            [0, t.name] # SATB is more important
           else
            [1, t.name] # Harmonica
           end
         elsif t.is_composer_tag?
           [2, t.name]
         elsif t.is_topic_tag?
           [3, t.name]
         else # song attribute [?]
           [4, t.name]
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

  # this is called in a before save
  def set_date_available
    self.date_available = Time.now if !self.date_available # use precise time for ordering sanity
  end

  def self.find_by_tag_id(tag_id, order_by = 'items.name ASC')
    tag = Tag.find(tag_id, :include => :products, :order => order_by) # including products.tags here is like 0.2s -> 2s
    tag.songs
  end

end

Song = Product # so I can say Song.find_by_name LOL
