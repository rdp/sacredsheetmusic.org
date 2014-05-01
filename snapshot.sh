echo "snapshotting production"
./sessions_clear.sh
#./cache_clear.sh
# partial clear instead, except it zips so well, who cares?
ruby script/runner -e production "p Cache.clear!" 
#rm log/* # we don't zip files anymore FWIW...
cat config/database.yml
echo old password was m4m, but enter new, above
A=`date`
B=`echo $A | tr -d \\n`
mysqldump -uprod_lds flds_production -p > "snap$B.sql"
gzip "snap$B.sql"
echo "not snapping pub files..."
