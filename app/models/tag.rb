require_dependency RAILS_ROOT + "/vendor/plugins/substruct/app/models/tag"

class Tag

  after_save { Cache.delete_all }

  # sync all hymns amongst themselves
  def self.sync_all_topics_with_warnings
    hymns_parent = Tag.all.select{|t| t.name =~ /^hymn/i}[0]
    return '' unless hymns_parent # for the other unit tests.and running  adev server..guess I could use fixtures after all :P
    hymns = hymns_parent.children
    raise unless hymns.length > 0
    errors = []
    for hymn in hymns
      error_message = share_tags_among_hymns_products(hymn)
      errors << error_message if error_message.length > 0
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
    raise unless topics
    for product in hymn_tag.products
      hymn_tags = product.tags.select{|t| t.is_hymn_tag?}
      next if hymn_tags.length > 0 # that would be an ambiguous one...
      raise count.to_s unless count == 1
      for tag in product.tags
        all_topic_ids[tag.id] = true if tag.parent.id == topics.id
      end
    end

    for product in hymn_tag.products
      product.tag_ids = product.tag_ids | all_topic_ids.keys # union of the two arrays of ints
    end
    
    if all_topic_ids.length > 0
      ''
    else
      hymn_tag.name # it's a failure hymn!
    end
  end

  def is_hymn_tag?
    self.parent && (self.parent.name =~ /^Hymn/i || self.parent.name =~ /arrangements$/i)
  end

  def is_composer_tag?
    self.parent && (self.parent.name =~ /^composer/i)
  end
end
