 puts Time.now;  count = `ps -ef | egrep wilkboar.*dispatch.fcgi | wc -l`.to_i-2; puts count
