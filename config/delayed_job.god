#--- setup
puts "*  setup delayed_job.god"
rails_env = ENV['RAILS_ENV'] || 'development'
puts "** rails_env = #{rails_env}"

rails_root = ENV['RAILS_ROOT'] || case rails_env
  when /production/, /staging/ then "/var/www/apps/probono/current"
  else "~/work/probono"
end
puts "** rails_root = #{rails_root}"

user_id = ENV['USER'] || case rails_env
  when /production/, /staging/ then "deploy"
  else "probono"
end
puts "** user_id = #{user_id}"

group_id = case rails_env
  when /production/, /staging/ then "app_probono"
  when /development/ then "staff"
  else "probono"
end
puts "** group_id = #{group_id}"


#--- script
20.times do |num|
  God.watch do |w|
    w.name     = "dj-#{num}"
    w.group    = 'dj'
    w.interval = 30.seconds
    w.start    = "rake -f #{rails_root}/Rakefile #{rails_env} jobs:work"
 
    w.uid = user_id
    w.gid = group_id
 
    # retart if memory gets too high
    w.transition(:up, :restart) do |on|
      on.condition(:memory_usage) do |c|
        c.above = 300.megabytes
        c.times = 2
      end
    end
 
    # determine the state on startup
    w.transition(:init, { true => :up, false => :start }) do |on|
      on.condition(:process_running) do |c|
        c.running = true
      end
    end
  
    # determine when process has finished starting
    w.transition([:start, :restart], :up) do |on|
      on.condition(:process_running) do |c|
        c.running = true
        c.interval = 5.seconds
      end
    
      # failsafe
      on.condition(:tries) do |c|
        c.times = 5
        c.transition = :start
        c.interval = 5.seconds
      end
    end
  
    # start if process is not running
    w.transition(:up, :start) do |on|
      on.condition(:process_running) do |c|
        c.running = false
      end
    end
  end
end
