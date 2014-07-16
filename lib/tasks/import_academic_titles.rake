namespace :data do
  
  namespace :import do

    AT = [{
      :name => 'Dr.', 
      :name_de => 'Dr.'
    }, {
      :name => 'Prof.', 
      :name_de => 'Prof.'
    }, {
      :name => 'Prof. Dr.', 
      :name_de => 'Prof. Dr.'
    }]
    
    desc "create academic titles data"
    task :academic_titles => :environment do 
      puts 'importing academic titles...'
      
      AT.each do |attributes|
        unless AcademicTitle.find_by_name(attributes[:name])
          at = AcademicTitle.create(attributes)
          if at.valid?
           puts "'#{at.name}' created."
          else
           puts "'#{at.name}' errors '#{at.errors.full_messages.join(', ')}'."
          end
        end
      end

      puts 'done.'
    end
    
  end
  
  namespace :purge do

    desc "purges academic titles data"
    task :academic_titles => :environment do 
      puts 'purging academic titles...'
      AT.each do |attributes|
        if at = AcademicTitle.find_by_name(attributes[:name])
          at.destroy
          puts "'#{at.name}' destroyed."
        end
      end
      puts 'done.'
    end

  end
  
end