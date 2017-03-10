require_dependency RAILS_ROOT + "/vendor/plugins/substruct/app/models/tag"

class Tag
  has_one :admin_user, :class_name => 'User', :foreign_key => :composer_tag_id # User has one of these [composer login]

  validate :no_underscores
  def no_underscores
    if self.name =~ /_/
     errors.add(:name, "has _")
    end
  end

  def all_products_hits
    sum = 0
    self.products.each{|p| sum += p.view_count}
    sum
  end

  def all_products_redirects
    sum = 0
    self.products.each{|p| sum += p.redirect_count}
    sum
  end

  def remove_other_tag_from_all_my_children offending_tag
    self.products.each{|p| p.remove_tag_id offending_tag.id}
  end

  def all_products_pdf_downloads
    sum = 0
    self.products.each{|p| sum += p.pdf_download_count}
    sum
  end

  def songs
    products
  end

  def super_children_tags
    if self.children.length > 0
      [self, self.children.map{|c| c.super_children_tags}].flatten
    else
     self
    end
  end

  def super_children_products_with_dups
    super_children_tags.map{|t| t.products}.flatten
  end

  # sync all hymns amongst themselves
  def self.sync_all_topics_with_all_hymns
    hymns_children = Tag.all.select{|t| t.is_hymn_tag?}
    hymns_parents = hymns_children.map{|t| t.parent}.uniq
    return '' if hymns_parents.size == 0 # for the other unit tests.and running  adev server..guess I could use fixtures after all :P
    errors = []
    for hymns_parent in hymns_parents
      hymns = hymns_parent.children
      unless hymns.length > 0
        raise
      end
      for hymn in hymns
        success = share_tags_among_hymns_products(hymn)
        errors << hymn.name unless success
      end
    end
    if errors.length > 0
      "Warning: no topics associated with any hymns for [please report this to us! :" + errors.join(', ')
    else
      ''
    end
  end
  
  def self.share_tags_among_hymns_products hymn_tag
    all_topic_ids = {}
    topics = Tag.find_by_name("Topics")
    raise unless topics
    products = hymn_tag.products
    for product in products
      hymn_tags = product.hymn_tags
      if hymn_tags.length > 1 
        next
      end
      for tag in product.topic_tags
        all_topic_ids[tag.id] = true
      end
    end

    for product in products
      product.tag_ids = product.tag_ids | all_topic_ids.keys # union of the two arrays of ints
    end
    
    if all_topic_ids.length > 0
      true
    else
      false
    end
  end

  def is_hymn_tag? # accomodate primary, too
    self.parent && (self.parent.name =~ /^hymn/i || self.parent.name =~ /arrangements/i)
  end

  def valid_products
   self.products.select{|p| p.date_available < Time.now}
  end

  def is_composer_tag?
    self.parent && (self.parent.name =~ /^composer/i)
  end

  def is_topic_tag?
    self.parent && (self.parent.name =~ /^topic/i)
  end

  def is_original_tag?
    self.name =~ /^original/i
  end

  def get_composer_contact_generic_url
     if composer_contact_url.present? 
       composer_contact_url
     elsif composer_email_if_contacted.present?
       "mailto:" + composer_email_if_contacted
     else
       nil # I'm not a composer tag...
     end
  end

  after_destroy :clear_my_cache_and_associated
  after_update :clear_my_cache_and_associated 
  after_create :clear_my_cache_and_associated # clear for parent :)

  def clear_my_cache_and_associated
    Rails.logger.info "clearing for tag and parent with all songs [!] #{self.name}"
    clear_cache_self
    clear_cache_songs
  end 

  def clear_cache_self
    clear_public_cached
    parent.andand.clear_public_cached # in case it needs to add one to its children now...
    Cache.delete_by_type 'tags'# cached left side is messed now -- this also clears all local caches, restarts
  end

  def clear_cache_songs
    products.each{|p|  
      # hopefully no...infinite recursion here since the product just calls back to tags.clear_public_cached...   
      p.clear_my_cache
    }
  end


  def clear_public_cached
    files = Dir[RAILS_ROOT + '/public/cache/' + self.name.gsub('/', '_').gsub(' ', '_') + '*'] # SATB causes SATBB clear too but...
    files += Dir[RAILS_ROOT + '/public/cache/all_songs*'] # this one too :)
    Rails.logger.info "clearing files=#{files.inspect} #{self.name}"
    files.each{|f| File.delete f}
    files
  end

  # Finds ordered parent tags by rank.
  def self.find_ordered_parents
    find(
      :all,
      :conditions => "parent_id IS NULL OR parent_id = 0",
#      :include => [:parent, :children], # we don't want *all* children though...that seems kind of wasteful, esp. since we cache output anyway now
      :order => "-rank DESC"
    )
  end

  # i.e. one with ellipses, that shows both sides of slashes, etc.
  def abbreviated_name
             name_sans_commas = self.name.gsub(',', '')
             words = name_sans_commas.split(/[ \/]/)
             # don't say "a" for a capella
             # also don't do word ... when you could fit "word word2" :)
             # also don't do 2... for "2 part choir"
             # also don't do friend... for friend/friendship [too long]
             # 2 part choir -> 2 part choir, not 2 part ...
             # comfort/strength/courage -> comfort... (comfort/strength too big)
             # home/family => home...
             if (words.size > 2) || name_sans_commas.length > 20
               splitter_loc = (name_sans_commas =~ /[ \/]/) # split on spaces or slashes
               first_two_words = words[0..1]
               # don't write organ/organ
               if first_two_words[0] == first_two_words[1]
                 first_two_words.pop # off the last one
               end
               # also don't write harp solo for harp solo/harp optional accompaniment
               split_by_slashes = name_sans_commas.split('/')
               if split_by_slashes.size > 1 && split_by_slashes[0].split[0] == split_by_slashes[1].split[0]
                 first_two_words = [split_by_slashes[0].split[0]] # harp solo/harp accompaniment -> "harp" since otherwise it looks like it's a solo...
               end
               first_part_of_name_rejoined = first_two_words.join(name_sans_commas[splitter_loc..splitter_loc]) # preserve that slash :)
               name_to_use = first_part_of_name_rejoined
               if name_to_use.contain? '/'
                 # home/family -> home
                 name_to_use = name_to_use.split('/')[0] # TODO clean up this logic!
               end
               if name_to_use != name_sans_commas
                 name_to_use += "&hellip;"
               else
                 # things like a/b that retained the whole thing need no ellipses
               end
             else
               name_to_use = name_sans_commas
             end
             name_to_use
  end

  def alphabetize_children!
    children = self.children
    children = children.sort_by{|t| t.name.gsub("'", "").upcase}
    children.each_with_index{|tag, idx|
      # tag.rank = idx; tag.save # too slow
      Tag.update_all({:rank => idx}, {:id => tag.id}) # skip callbacks
    }
 end

end
