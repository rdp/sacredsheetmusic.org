echo 'clearing just session, not cache, this takes quite awhile, and locks the site'
ruby script/runner -e production " 
good_ids = {}
WishlistItem.all.each{|wli| good_ids[wli.session_id] = 1}

# delete_all loads nothing into memory
# unfortunately this does appear to lock the whole sessions table, but at least its only for awhile :|
# TODO iterate over each of them? gah...
p Session.delete_all([\"id not in (?)\", good_ids.keys])
p good_ids.size, 'sessions retained'
"
