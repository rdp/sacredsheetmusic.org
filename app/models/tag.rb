require_dependency RAILS_ROOT + "/vendor/plugins/substruct/app/models/tag"

class Tag

  def self.sync_topics
    hymns = Tag.find_by_name("Hymns")
    raise unless hymns.children.length > 0
    for hymn in hymns.children
      share_tags_among_hymns_products hymn
    end
  end
  
  
  def self.share_tags_among_hymns_products hymn
    all_tag_ids = {}
    for product in hymn.products
      for tag in product.tags
        all_tag_ids[tag.id.to_s] = true # need to_s for the call to #tag_ids= to work
      end
    end
    raise unless all_tag_ids.length > 0
    for product in hymn.products
      product.tag_ids = all_tag_ids.keys   
    end
  end
end
