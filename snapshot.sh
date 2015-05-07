echo "snapshotting (production) DB..."
#./sessions_clear.sh
#./cache_clear.sh
# partial clear instead, except it zips so well, who cares?
nice ruby script/runner -e production "p Cache.clear!" 
#rm log/* # we don't zip files anymore FWIW...
cat config/database.yml
echo old password was m4m, but enter new, above
A=`date`
B=`echo $A | tr -d \\n`
# allow this to lock the tables since it 3s total anyway...
nice mysqldump -uprod_lds flds_production -pprod_lds_pass --ignore-table=flds_production.sessions --ignore-table=flds_production.cache > "snap$B.sql"
gzip "snap$B.sql"
echo "created snap$B.sql"
echo "not snapping pub files..."
