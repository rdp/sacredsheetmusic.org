echo 'clearing just cache and public/cache/*, not sessions'
sleep 2
rm public/cache/*
ruby script/runner -e production "p Cache.clear!;" # just in case :P
rm public/cache/*
echo 'please run kill now'

