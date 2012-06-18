ruby script/runner -e production "Cache.clear!; Session.all.each{|s| s.delete unless s.wishlist_items.count > 0}"
#rm log/*
echo m4m
A=`date`
B=`echo $A | tr -d \\n`
mysqldump -uwilkboar_m4m wilkboar_m4m -p > "snap$B.sql"
gzip "snap$B.sql"
