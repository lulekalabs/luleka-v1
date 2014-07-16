set :application, "luleka"
set :repository, "https://luleka.svn.beanstalkapp.com/luleka/trunk"

task :staging do
  role :app, "deploy@staging.luleka.net"
  role :web, "deploy@staging.luleka.net"
  role :db,  "deploy@staging.luleka.net", :primary => true
  
  set :user, "deploy"
  set :stage, :staging
  set :rails_env, :staging
  set :deploy_to, "/var/www/apps/#{application}"
  set :domain, "staging.luleka.net"
end

task :production do
  role :app, "deploy@luleka.com"
  role :web, "deploy@luleka.com"
  role :db,  "deploy@luleka.com", :primary => true
  
  set :user, "deploy"
  set :stage, :production
  set :rails_env, :production
  set :deploy_to, "/var/www/apps/#{application}"
  set :domain, "luleka.com"
end

#############################################################
# Settings
#############################################################

ssh_options[:port] = 8666
default_run_options[:pty] = true
set :use_sudo, true


namespace :deploy do
  task :restart, :roles => :app, :except => {:no_release => true} do
    unicorn.restart
#    passenger.restart
  end
end

task :after_update_code, :roles => [:app] do
  symlink_database_yml
  symlink_amazon_yml
  symlink_paypal_yml
  build_assets
end


#############################################################
# Unicorn
#############################################################

namespace :unicorn do
  desc "Restart Unicorn Application"
  task :restart, :roles => :app do
    run "kill -s USR2 `cat #{current_path}/tmp/pids/unicorn.pid`"
  end
end


#############################################################
# Passenger
#############################################################

namespace :passenger do
  desc "Restart Passenger Application"
  task :restart, :roles => :app do
    run "touch #{current_path}/tmp/restart.txt"
  end
end

#############################################################
# Symlink database.yml
#############################################################
desc "link in the database.yml"
task :symlink_database_yml, :roles => :app do
  run "rm -f #{current_path}/config/database.yml"
  run "ln -nfs #{deploy_to}/#{shared_dir}/config/database.yml #{release_path}/config/database.yml"
end

#############################################################
# Symlink amazon_s3.yml
#############################################################
desc "link in the amazon_s3.yml"
task :symlink_amazon_yml, :roles => :app do
  run "rm -f #{current_path}/config/amazon_s3.yml"
  run "ln -nfs #{deploy_to}/#{shared_dir}/config/amazon_s3.yml #{release_path}/config/amazon_s3.yml"
end

desc "generate the amazon_s3.yml"
task :generate_amazon_s3_yml, :roles => :app do
  
  set(:bucket_name) { Capistrano::CLI.ui.ask("Enter s3 bucket name (e.g. site-production)") }
  set(:access_key_id) { Capistrano::CLI.ui.ask("Enter s3 access key id") }
  set(:secret_access_key) { Capistrano::CLI.ui.ask("Enter s3 secret access key") }

  amazon_s3_configuration = <<-EOF 
#{rails_env}:
  bucket_name: #{bucket_name}
  access_key_id: #{access_key_id}
  secret_access_key: #{secret_access_key}
EOF
  run "mkdir -p #{deploy_to}/#{shared_dir}/config"
  put amazon_s3_configuration, "#{deploy_to}/#{shared_dir}/config/amazon_s3.yml"
  sudo "chown #{user}:#{app_group} #{deploy_to}/#{shared_dir}/config/amazon_s3.yml"
end

#############################################################
# Symlink paypal.yml
#############################################################
desc "Link in the paypal.yml"
task :symlink_paypal_yml, :roles => :app do
  run "rm -f #{current_path}/config/paypal.yml"
  run "ln -nfs #{deploy_to}/#{shared_dir}/config/paypal.yml #{release_path}/config/paypal.yml"
end

desc "generate the paypal.yml"
task :generate_paypal_yml, :roles => :app do
  set(:api_username) { Capistrano::CLI.ui.ask('Enter Paypal API Username') }
  set(:api_password) { Capistrano::CLI.ui.ask('Enter Paypal API Password') }
  set(:signature) { Capistrano::CLI.ui.ask('Enter Paypal Signature') }
  set(:mode) { Capistrano::CLI.ui.ask('Enter Paypal mode (test|production)') }
  paypal_configuration = <<-EOF
#{rails_env}:
  api_username: #{api_username}
  api_password: #{api_password}
  signature: #{signature}
  mode: #{mode}
EOF
  run "mkdir -p #{deploy_to}/#{shared_dir}/config"
  put paypal_configuration, "#{deploy_to}/#{shared_dir}/config/paypal.yml"
  sudo "chown #{user}:#{app_group} #{deploy_to}/#{shared_dir}/config/paypal.yml"
end

#############################################################
# Symlink authorize_net.yml
#############################################################
desc "Link in the authorize_net.yml"
task :symlink_authorize_net_yml, :roles => :app do
  run "rm -f #{current_path}/config/authorize_net.yml"
  run "ln -nfs #{deploy_to}/#{shared_dir}/config/authorize_net.yml #{release_path}/config/authorize_net.yml"
end

desc "generate the authorize_net.yml"
task :generate_authorize_net_yml, :roles => :app do
  set(:login_id) { Capistrano::CLI.ui.ask('Enter Authorize.net login id') }
  set(:transaction_key) { Capistrano::CLI.ui.ask('Enter Authorize.net transaction key') }
  set(:mode) { Capistrano::CLI.ui.ask('Enter Authorize.net mode (test|production)') }
  authorize_net_configuration = <<-EOF
#{rails_env}:
  login_id: #{login_id}
  transaction_key: #{transaction_key}
  mode: #{mode}
EOF
  run "mkdir -p #{deploy_to}/#{shared_dir}/config"
  put authorize_net_configuration, "#{deploy_to}/#{shared_dir}/config/authorize_net.yml"
  sudo "chown #{user}:#{app_group} #{deploy_to}/#{shared_dir}/config/authorize_net.yml"
end

#############################################################
# Asset Packager
#############################################################

desc 'creates the compressed javscript and css files'
task :build_assets, :roles => [:app] do
  run <<-EOF
    cd #{current_release} && rake RAILS_ENV=#{rails_env} asset:packager:build_all
  EOF
end

#############################################################
# Delayed Job
#############################################################

after "deploy:stop",        "delayed_job:stop"
after "deploy:start",       "delayed_job:start"
after "deploy:restart",     "delayed_job:restart"
after "deploy:update_code", "delayed_job:stop"

namespace :delayed_job do
  def rails_env
    fetch(:rails_env, false) ? "RAILS_ENV=#{fetch(:rails_env)}" : ''
  end
  
  desc "Stop the delayed_job process"
  task :stop, :roles => :app do
    run "cd #{current_path};#{rails_env} script/delayed_job stop"
  end

  desc "Start the delayed_job process"
  task :start, :roles => :app do
    run "cd #{current_path};#{rails_env} script/delayed_job start"
  end

  desc "Restart the delayed_job process"
  task :restart, :roles => :app do
    # delayed job restart requirs the worker running.. so better use stop and restart
    #run "cd #{current_path};#{rails_env} script/delayed_job restart"
    run "cd #{current_path};#{rails_env} script/delayed_job stop; #{rails_env} script/delayed_job start"
  end
end
