namespace :data do
  
  namespace :import do

    SEVERITIES = [{
      :name => 'trivial', :name_de => 'unwesentlich',
      :feeling => 'happy', :feeling_de => 'glücklich',
      :weight => 1, :kind => :trivial
    }, {
      :name => 'minor', :name_de => 'gering',
      :feeling => 'silly', :feeling_de => 'albern',
      :weight => 25, :kind => :minor
    }, {
      :name => 'normal', :name_de => 'normal',
      :feeling => 'indifferent', :feeling_de => 'gleichgültig',
      :weight => 50, :kind => :normal
    }, {
      :name => 'major', :name_de => 'wichtig',
      :feeling => 'sad', :feeling_de => 'traurig',
      :weight => 75, :kind => :major
    }, {
      :name => 'critical', :name_de => 'kritisch',
      :feeling => 'annoyed', :feeling_de => 'verärgert',
      :weight => 99, :kind => :critical, 
    }]

    desc "create severities data"
    task :severities => :environment do 
      puts 'importing severities...'
      SEVERITIES.each do |attributes|
        unless Severity.find_by_name(attributes[:name])
          sv = Severity.create(attributes)
          if sv.valid?
           puts "'#{sv.name}' created."
          else
           puts "'#{sv.name}' errors '#{sv.errors.full_messages.join(', ')}'."
          end
        end
      end
      puts 'done.'
    end
    
  end
  
  namespace :purge do

    desc "purges severities data"
    task :severities => :environment do 
      puts 'purging severities...'
      SEVERITIES.each do |attributes|
        if sv = Severity.find_by_name(attributes[:name])
          sv.destroy
          puts "'#{sv.name}' destroyed."
        end
      end
      puts 'done.'
    end

  end
  
end