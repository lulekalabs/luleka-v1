namespace :svn do
  desc "Configure SVN for probono"
  task :configure do
    Rake::Task['svn:ignore:log'].invoke
    Rake::Task['svn:ignore:tmp'].invoke
    Rake::Task['svn:ignore:test_tmp'].invoke
    Rake::Task['svn:ignore:yml'].invoke
  end
  
  namespace :ignore do 
    
    desc "ignores folder name"
    task :folder do
      puts 'Enter folder name (e.g. log/)'
      folder_name = $stdin.gets.chomp
      
      if folder_name
        system "svn propset svn:ignore \"*\" #{folder_name}"
        system "svn update #{folder_name}"
        system "svn commit -m \"ignore folder #{folder_name}\" "
      end
    end

    desc "ignores file name"
    task :file do
      puts 'Enter file name (e.g. config/amazon_s3.yml)'
      file_name = $stdin.gets.chomp
      
      if file_name
        base_name = File.basename(file_name)
        dir_name = File.dirname(file_name)

        system "svn remove #{file_name}"
        system "svn propset svn:ignore \"#{base_name}\" #{dir_name}/"
        system "svn update #{dir_name}/"
        system "svn commit -m \"ignore #{base_name}\""
      end
    end

    desc "ignore storage folder"
    task :storage do
      system 'svn remove storage/*'
      system 'svn propset svn:ignore "*" storage/'
      system 'svn update storage/'
      system 'svn commit -m "ignore storage\/"'
    end

    desc "ignore application/images folder"
    task :images do
      system 'svn remove public/application/*'
      system 'svn propset svn:ignore "*" public/application/'
      system 'svn update public/application/'
      system 'svn commit -m "ignore public\/application\/"'
    end

    desc "ignore application images folder"
    task :images do
      system 'svn remove public/images/application/*'
      system 'svn propset svn:ignore "*" public/images/application/'
      system 'svn update public/images/application/'
      system 'svn commit -m "ignore public/images/application\/"'
    end

    desc "ignore database.yml"
    task :database_yml do
      system 'svn remove config/database.yml'
      system 'svn propset svn:ignore "database.yml" config/'
      system 'svn update config/'
      system 'svn commit -m "ignore database.yml"'
    end

    desc "ignore yml"
    task :yml do
      system 'svn remove config/database.yml'
      system 'svn propset svn:ignore "database.yml" config/'

      system 'svn remove config/paypal.yml'
      system 'svn propset svn:ignore "paypal.yml" config/'

      system 'svn update config/'
      system 'svn commit -m "ignore ymls"'
    end

    desc "ignore paypal.yml"
    task :paypal_yml do
      system 'svn remove config/paypal.yml'
      system 'svn propset svn:ignore "paypal.yml" config/'
      system 'svn update config/'
      system 'svn commit -m "ignore paypal.yml"'
    end

    desc "ignore db/schema.rb"
    task :schema do
      system 'svn remove db/schema.rb'
      system 'svn propset svn:ignore "schema.rb" db/'
      system 'svn update db/'
      system 'svn commit -m "ignore schema.db"'
    end
    
    task :log do
      system 'svn remove log/*'
      system 'svn propset svn:ignore "*.log" log/'
      system 'svn update log/'
      system 'svn commit -m "Ignore all log archives in \/log\/ that match .log"'
    end
    
    task :tmp do 
      system 'svn remove tmp/*'
      system 'svn propset svn:ignore "*" tmp/'
      system 'svn update tmp/'
      system 'svn commit -m "Ignore tmp\/ for now" '
    end
    
    task :test_tmp do 
      system 'svn remove test/tmp/*'
      system 'svn propset svn:ignore "*" test/tmp/'
      system 'svn update test/tmp/'
      system 'svn commit -m "Ignore test/tmp\/ for now" '
    end
    
  end
  
end

