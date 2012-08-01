echo 'clearing just cache, not sessions'
echo 'run kill first!'
kill
rm db/sqlite3.production
ruby script/runner -e production db/migrate/dis.053_create_sqlite3_cache.rb 
#ruby script/runner -e production "p Cache.clear!;" # just in case :P
echo 'please run kill now'

