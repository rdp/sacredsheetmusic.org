echo 'clearing just session, not cache'
ruby script/runner -e production " Session.all.each{|s| s.delete unless s.wishlist_items.count > 0}"
