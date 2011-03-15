require_dependency RAILS_ROOT + "/vendor/plugins/substruct/app/models/tag"

class Tag

  def self.sync_topics_with_warnings
    hymns_parent = Tag.find_by_name("Hymns")
    return unless hymns_parent # for the other unit tests...guess I could use fixtures after all :P
    hymns = hymns_parent.children
    raise unless hymns.length > 0
    errors = ''
    for hymn in hymns
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
        all_topic_ids[tag.id] = true if tag.parent.id == topics.id
      end
    end
    for product in hymn.products
      product.tag_ids = product.tag_ids | all_topic_ids.keys # union of the two arrays of ints
    end
    
    if all_topic_ids.length > 0
      ''
    else
      " warning: no topics associated with hymn #{hymn.name}"
    end
  end
end
