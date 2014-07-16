namespace :data do
  
  desc "creates all app data..."
  task :import => :environment do 
    Rake::Task['data:import:academic_titles'].invoke
    Rake::Task['data:import:personal_statuses'].invoke
    Rake::Task['data:import:severities'].invoke
    Rake::Task['data:import:spoken_languages'].invoke
    Rake::Task['data:import:categories'].invoke

    Rake::Task['data:import:probono'].invoke

    Rake::Task['data:import:tiers'].invoke
    Rake::Task['data:import:topics'].invoke
    
    Rake::Task['data:import:users'].invoke
  end
  
  desc "purges all app data..."
  task :purge do
    Rake::Task['data:purge:users'].invoke

    Rake::Task['data:purge:topics'].invoke
    Rake::Task['data:purge:tiers'].invoke

    Rake::Task['data:purge:probono'].invoke

    Rake::Task['data:purge:categories'].invoke
    Rake::Task['data:purge:spoken_languages'].invoke
    Rake::Task['data:purge:severities'].invoke
    Rake::Task['data:purge:personal_statuses'].invoke
    Rake::Task['data:purge:academic_titles'].invoke
  end
  
end