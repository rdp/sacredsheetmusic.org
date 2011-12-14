require_dependency RAILS_ROOT + "/vendor/plugins/substruct/app/models/tag"

class Tag

  #after_save { Cache.clear! } # we don't list it with the songs anymore...

  def all_products_hits
    sum = 0
    self.products.each{|p| sum += p.view_count}
    sum
  end

  # sync all hymns amongst themselves
  def self.sync_all_topics_with_all_hymns
    hymns_parent = Tag.all.select{|t| t.name =~ /^hymn/i}
    raise if hymns_parent.size > 1
    return '' unless hymns_parent.size == 1 # for the other unit tests.and running  adev server..guess I could use fixtures after all :P
    hymns_parent = hymns_parent[0]
    hymns = hymns_parent.children
    raise unless hymns.length > 0
    errors = []
    for hymn in hymns
      success = share_tags_among_hymns_products(hymn)
      errors << hymn.name unless success
    end
    if errors.length > 0
      "Warning: no topics associated with any hymns for:" + errors.join(', ')
    else
      ''
    end
  end
  
  def self.share_tags_among_hymns_products hymn_tag
    all_topic_ids = {}
    topics = Tag.find_by_name("Topics")
    raise 'thats impossible' unless topics
    products = hymn_tag.products
    for product in products
      hymn_tags = product.tags.select{|t| t.is_hymn_tag?}
      if hymn_tags.length > 1 
        next
      end
      for tag in product.tags
        all_topic_ids[tag.id] = true if tag.parent.id == topics.id
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

  def is_hymn_tag?
    self.parent && (self.parent.name =~ /^Hymn/i || self.parent.name =~ /arrangements$/i)
  end

  def is_composer_tag?
    self.parent && (self.parent.name =~ /^composer/i)
  end

  def is_topic_tag?
    self.parent && (self.parent.name =~ /^topic/i)
  end

  def is_original_tag?
    self.name =~ /original/i
  end
end
