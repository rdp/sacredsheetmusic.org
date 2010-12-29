out = `ps -ef | grep ruby | grep wilkboar | grep dispatch`
for line in out
  # line === wilkboar 13785 25295  0 13:13 ?        00:00:01 /usr/bin/ruby dispatch.fcgi
  bad_pid = line.split(' ')[1]
  death_command = "kill #{bad_pid}"
  print death_command.inspect, "\n"
  system(death_command)
end

