echo "snapshotting (production) DB..."
echo "not sure this prossibly get too much junk stuff these days... :|"
#./sessions_clear.sh
#./cache_clear.sh
# partial [non file] clear instead, except it zips so well, who cares?
echo "clearing cache table(s) [only, partial cache clear]"
nice ruby script/runner -e production "p Cache.clear!" 
#rm log/* # we don't zip files anymore FWIW, so don't need to remot these...
A=`date`
B=`echo $A | tr -d \\n`
# allow this to lock the tables since it 3s total anyway...
nice mysqldump -uprod_flds prod_flds_database -p > "snap$B.sql" &&  gzip "snap$B.sql" && echo "created snap$B.sql" 
echo "not snapping pub files..."
