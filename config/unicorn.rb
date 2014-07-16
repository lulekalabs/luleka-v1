# unicorn_rails -c /var/www/apps/probono/current/config/unicorn.rb -E production -D
# http://blog.darmasoft.net/2010/02/01/from-mongrels-to-unicorns
rails_env = ENV['RAILS_ENV'] || 'production'

# Timeout, workers, etc. for different environments
case rails_env
when /production/
  timeout 30
  worker_processes 2
  listen '/var/www/apps/luleka/shared/sockets/unicorn.sock', :backlog => 2048
  pid '/var/www/apps/luleka/current/tmp/pids/unicorn.pid'
when /staging/
  timeout 30
  worker_processes 1
  listen '/var/www/apps/luleka/shared/sockets/unicorn.sock', :backlog => 2048
  pid '/var/www/apps/luleka/current/tmp/pids/unicorn.pid'
else
  # development
  timeout 360
  worker_processes 1
  listen '127.0.0.1:3000'
  pid '/var/tmp/unicorn.pid'
end
 
# Load rails+github.git into the master before forking workers
# for super-fast worker spawn times
preload_app true
 
##
# REE
 
# http://www.rubyenterpriseedition.com/faq.html#adapt_apps_for_cow
if GC.respond_to?(:copy_on_write_friendly=)
  GC.copy_on_write_friendly = true
end
 
 
before_fork do |server, worker|
  ##
  # When sent a USR2, Unicorn will suffix its pidfile with .oldbin and
  # immediately start loading up a new version of itself (loaded with a new
  # version of our app). When this new Unicorn is completely loaded
  # it will begin spawning workers. The first worker spawned will check to
  # see if an .oldbin pidfile exists. If so, this means we've just booted up
  # a new Unicorn and need to tell the old one that it can now die. To do so
  # we send it a QUIT.
  #
  # Using this method we get 0 downtime deploys.
 
  old_pid = RAILS_ROOT + '/tmp/pids/unicorn.pid.oldbin'
  if File.exists?(old_pid) && server.pid != old_pid
    begin
      Process.kill("QUIT", File.read(old_pid).to_i)
    rescue Errno::ENOENT, Errno::ESRCH
      # someone else did our job for us
    end
  end
end
 
 
after_fork do |server, worker|
  ##
  # Unicorn master loads the app then forks off workers - because of the way
  # Unix forking works, we need to make sure we aren't using any of the parent's
  # sockets, e.g. db connection
 
  ActiveRecord::Base.establish_connection
  # Redis and Memcached would go here but their connections are established
  # on demand, so the master never opens a socket
 
 
  ##
  # Unicorn master is started as root, which is fine, but let's
  # drop the workers to deploy:deploy
 
  begin
    uid, gid = Process.euid, Process.egid
    user, group = 'deploy', 'deploy'
    target_uid = Etc.getpwnam(user).uid
    target_gid = Etc.getgrnam(group).gid
    worker.tmp.chown(target_uid, target_gid)
    if uid != target_uid || gid != target_gid
      Process.initgroups(user, target_gid)
      Process::GID.change_privilege(target_gid)
      Process::UID.change_privilege(target_uid)
    end
  rescue => e
    if RAILS_ENV == 'development'
      STDERR.puts "couldn't change user, oh well"
    else
      raise e
    end
  end
end