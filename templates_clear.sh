echo 'this is if the products have stayed the same, just the layout is different'
rm `find public/cache*/* | grep -v git`
./restart.sh
rm `find public/cache*/* | grep -v git`
echo 'done [one of the warnings above is expectedish]'
