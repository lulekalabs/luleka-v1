namespace :data do
  
  namespace :import do

    PS = [{
      :name => 'Entrepreneur', 
      :name_de => 'Unternehmer'
    }, {
      :name => 'Employee', 
      :name_de => 'Angestellter'
    }, {
      :name => 'Civil Servant', 
      :name_de => 'Beamter'
    }, {
      :name => 'Freelance', 
      :name_de => 'Freiberuflich'
    }, {
      :name => 'Student', 
      :name_de => 'Student'
    }, {
      :name => 'Executive', 
      :name_de => 'Geschäftsführer'
    }, {
      :name => 'Seeking employment', 
      :name_de => 'Arbeitsuchend'
    }]
    
    desc "create personal statuses data"
    task :personal_statuses => :environment do 
      puts 'importing personal statuses...'
      
      PS.each do |attributes|
        unless PersonalStatus.find_by_name(attributes[:name])
          ps = PersonalStatus.create(attributes)
          if ps.valid?
           puts "'#{ps.name}' created."
          else
           puts "'#{ps.name}' errors '#{ps.errors.full_messages.join(', ')}'."
          end
        end
      end

      puts 'done.'
    end
    
  end
  
  namespace :purge do

    desc "purges personal statuses data"
    task :personal_statuses => :environment do 
      puts 'purging personal statuses...'
      PS.each do |attributes|
        if ps = PersonalStatus.find_by_name(attributes[:name])
          ps.destroy
          puts "'#{ps.name}' destroyed."
        end
      end
      puts 'done.'
    end

  end
  
end