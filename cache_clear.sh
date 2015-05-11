echo 'clearing cache and public/cache/* [whole kit and kaboodle], not clearing sessions'
echo 'dont do this with session clear too close... (locks table?)'
rm public/cache/*
ruby script/runner -e production 'p Cache.clear!;' # just in case, also clear internal html caches
rm public/cache/*
./restart.sh
