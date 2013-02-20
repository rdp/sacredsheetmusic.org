echo 'clearing just cache, not sessions'
rm public/cache/*
ruby script/runner -e production "p Cache.clear!;" # just in case :P
rm public/cache/*
echo 'please run kill now'

