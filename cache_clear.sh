echo 'clearing cache and public/cache/* [whole kit and kaboodle], not clearing sessions'
sleep 2
rm public/cache/*
ruby script/runner -e production 'p Cache.clear!;' # just in case :P
rm public/cache/*
./restart.sh
