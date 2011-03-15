require_dependency RAILS_ROOT + "/vendor/plugins/substruct/app/models/tag"

class Tag

  def self.sync_topics
    hymns = Tag.find_by_name("Hymns")
    for hymn in hymns.products
      share_tags_among_hymns_products hymn
    end
  end
  
  
  def self.share_tags_among_hymns_products hymn
    all_tag_ids = {}
    for product in hymn.products
      for tag in product.tags
        all_tag_ids[tag.id] = true
      end
    end
    
    for product in hymn.products
      product.tag_ids = all_tag_ids.keys   
    end
  end
end
