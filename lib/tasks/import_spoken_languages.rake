namespace :data do
  
  namespace :import do

    SL = [{
      :code => 'en',
      :native_name => 'english',
      :name => 'english',
      :name_de => 'englisch'
    }, {
      :code => 'es',
      :native_name => 'español',
      :name => 'spanish',
      :name_de => 'spanisch'
    }, {
      :code => 'pt',
      :native_name => 'português',
      :name => 'portuguese',
      :name_de => 'portugiesisch'
    }, {
      :code => 'fr',
      :native_name => 'français',
      :name => 'french',
      :name_de => 'französisch'
    }, {
      :code => 'de',
      :native_name => 'deutsch',
      :name => 'german',
      :name_de => 'deutsch'
    }, {
      :code => 'it',
      :native_name => 'italiano',
      :name => 'italian',
      :name_de => 'italienisch'
    }, {
      :code => 'du',
      :native_name => 'nederlands',
      :name => 'dutch',
      :name_de => 'holländisch'
    }, {
      :code => 'da',
      :native_name => 'dansk',
      :name => 'danish',
      :name_de => 'dänisch'
    }, {
      :code => 'sv',
      :native_name => 'svenska',
      :name => 'swedish',
      :name_de => 'schwedisch'
    }, {
      :code => 'cs',
      :native_name => 'čeština',
      :name => 'czech',
      :name_de => 'tschechisch'
    }, {
      :code => 'sl',
      :native_name => 'slovenščina',
      :name => 'slovene',
      :name_de => 'slovenisch'
    }, {
      :code => 'ru',
      :native_name => 'русский язык',
      :name => 'russian',
      :name_de => 'russisch'
    }, {
      :code => 'fi',
      :native_name => 'suomi',
      :name => 'finnish',
      :name_de => 'finnisch'
    }, {
      :code => 'pl',
      :native_name => 'polszczyzna',
      :name => 'polish',
      :name_de => 'polnisch'
    }, {
      :code => 'ja',
      :native_name => '日本語',
      :name => 'japanese',
      :name_de => 'japanisch'
    }, {
      :code => 'zho',
      :native_name => '中文',
      :name => 'chinese',
      :name_de => 'chinesisch'
    }]
    desc "create spoken languages data"
    task :spoken_languages => :environment do 
      puts 'importing spoken languages...'
      
      SL.each do |attributes|
        unless SpokenLanguage.find_by_name(attributes[:name])
          sl = SpokenLanguage.create(attributes)
          if sl.valid?
           puts "'#{sl.native_name}' created."
          else
           puts "'#{sl.native_name}' errors '#{sl.errors.full_messages.join(', ')}'."
          end
        end
      end

      puts 'done.'
    end
    
  end
  
  namespace :purge do

    desc "purges spoken languages data"
    task :spoken_languages => :environment do 
      puts 'purging spoken languages...'
      SL.each do |attributes|
        if sl = SpokenLanguage.find_by_name(attributes[:name])
          sl.destroy
          puts "'#{sl.name}' destroyed."
        end
      end
      puts 'done.'
    end

  end
  
end