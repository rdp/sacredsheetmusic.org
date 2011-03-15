require_dependency RAILS_ROOT + "/vendor/plugins/substruct/app/models/tag"

class Tag

  def self.sync_topics_with_warnings
    hymns = Tag.find_by_name("Hymns")
    return unless hymns # for the other unit tests...
    raise unless hymns.children.length > 0
    errors = ''
    for hymn in hymns.children
      errors += share_tags_among_hymns_products(hymn)
    end
    errors
  end
  
  
  def self.share_tags_among_hymns_products hymn
    all_topic_ids = {}
    topics = Tag.find_by_name("Topics")
    raise unless topics
    for product in hymn.products
      for tag in product.tags
        all_topic_ids[tag.id.to_s] = true if tag.parent.id == topics.id  # need to_s for the call to #tag_ids= to work
      end
    end
    for product in hymn.products
      product.tag_ids = all_topic_ids.keys   
    end
    
    if all_topic_ids.length > 0
      ''
    else
      " warning: no topics associated with hymn #{hymn}"
    end
  end
end
