echo 'clearing just session, not cache'
ruby script/runner -e production " 
good_ids = {}
WishlistItem.all.each{|wli| good_ids[wli.session_id] = 1}

p Session.delete_all([\"id not in (?)\", good_ids.keys])
p good_ids.size, 'sessions retained'
"
