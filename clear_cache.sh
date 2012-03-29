echo 'clearing jjust cache, not sessions'
ruby script/runner -e production "p Cache.clear!;"
