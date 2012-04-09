echo 'clearing just session, not cache'
ruby script/runner -e production "p Session.clear!;"
