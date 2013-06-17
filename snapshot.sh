echo "snapshotting production [broke]"
./sessions_clear.sh
#./cache_clear.sh
#rm log/* # we don't zip files anymore FWIW...
echo old password was m4m
A=`date`
B=`echo $A | tr -d \\n`
mysqldump -uwilkboar_m4m wilkboar_m4m -p > "snap$B.sql"
gzip "snap$B.sql"
echo "not snapping pub files..."
