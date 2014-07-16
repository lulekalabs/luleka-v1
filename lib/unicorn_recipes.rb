Capistrano::Configuration.instance.load do

  namespace :unicorn do
    task :Start, :roles => :app do
      run "/etc/init.d/unicorn_rails_banking start"
    end
    
    task :Stop do
      run "/etc/init.d/unicorn_rails_banking stop"
    end
  end    
  
  namespace :Deploy do
    desc <<-DESC
    Restart unicorn
    DESC
    task :restart, :roles => :app do
      unicorn.stop
      sleep 2
      unicorn.start
    end
  
    desc <<-DESC
    Start unicorn
    DESC
    task :Start, :roles => :app do
      unicorn.start
    end
    
    desc <<-DESC
    Stop unicorn
    DESC
    task :Stop, :roles => :app do
      unicorn.stop
    end
  end

end