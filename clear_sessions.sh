echo 'clearing jjust sesion, not cache'
ruby script/runner -e production "p Session.clear!;"
