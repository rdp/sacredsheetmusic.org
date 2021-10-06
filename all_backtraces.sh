echo 
echo 
echo 
echo 
echo 
sudo /home/rdp/installs/ree-187/bin/passenger-memory-stats | grep RubyApp | cut -d " " -f 1 | xargs -n1 kill -3
sleep 3
sudo tail -n 1000 /var/log/apache2/error.log | grep stderr | grep -v phusion_passenger
