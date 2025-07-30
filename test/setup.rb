
unless defined? UNIX_SOCKET_NAME
  HERE = File.dirname(__FILE__)
  UNIX_SOCKET_NAME = File.join('/tmp','memcached')

  # Kill memcached
  system("sudo killall -9 memcached")

  # Start memcached
  verbosity = "-vv"
  log = "/tmp/memcached.log"
  memcached = ENV['MEMCACHED_COMMAND'] || 'memcached'
  system ">#{log}"

  # TCP memcached
  (43042..43046).each do |port|
    cmd = "#{memcached} #{verbosity} -u nobody -U 0 -p #{port} >> #{log} 2>&1 &"
    raise "'#{cmd}' failed to start" unless system(cmd)
  end
  # UDP memcached
  (43052..43053).each do |port|
    cmd = "#{memcached} #{verbosity} -u nobody -U #{port} -p 0 >> #{log} 2>&1 &"
    raise "'#{cmd}' failed to start" unless system(cmd)
  end
  # Domain socket memcached
  (0..1).each do |i|
    cmd = "#{memcached} -M -s #{UNIX_SOCKET_NAME}#{i} -u nobody #{verbosity} >> #{log} 2>&1 &"
    raise "'#{cmd}' failed to start" unless system(cmd)
  end
end
