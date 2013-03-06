echo 'clearing just session, not cache'
ruby script/runner -e production " Session.all(:include => :wishlist_items).each{|s| s.delete unless s.wishlist_items.count > 0}"
