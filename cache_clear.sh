echo 'clearing just cache, not sessions'
echo 'run kill first!'
kill
ruby script/runner -e production "p Cache.clear!;" # just in case :P
echo 'please run kill now'

