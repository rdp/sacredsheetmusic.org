#echo "this [also] restarts prod"
#touch "/home/rdp/prod_flds/tmp/restart.txt"
echo "this only restarts the cur dir $(pwd)"
touch ./tmp/restart.txt
