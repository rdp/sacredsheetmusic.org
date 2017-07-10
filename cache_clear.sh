echo 'clearing cache and public/cache/* [whole kit and kaboodle], not clearing sessions'
echo 'dont do this with session clear too close... (locks table?) anyway as the cache repopulates is a bad time to do this...'
rm public/cache/*
rm public/song_cache_square/*
ruby script/runner -e production 'p Cache.clear!;' # just in case, also clears internal html caches
rm public/cache/*
rm public/song_cache_square/*
touch public/cache/git_keep_dir
touch public/song_cache_square/git_marker
./restart.sh
