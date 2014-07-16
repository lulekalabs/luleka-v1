namespace :data do
  
  namespace :import do

    ST = [{
      :kind => 'company', 
      :super_type => 'Organization',
      :name => 'Company', 
      :name_de => 'Firma',
      :name_es => 'Empresa'
    }, {
      :kind => 'government',
      :super_type => 'Organization',
      :name => 'Government',
      :name_de => 'Regierung',
      :name_es => 'Gobierno'
    }, {
      :kind => 'professional_group',
      :super_type => 'Group',
      :name => 'Professional Group',
      :name_de => 'Gruppe von Fachkräften',
      :name_es => 'Grupo profesional'
    }, {
      :kind => 'corporate_group',
      :super_type => 'Group',
      :name => 'Corporate Group',
      :name_de => 'Unternehmensgruppe',
      :name_es => 'Grupo corporativo'
    }
    ]
    
    desc "create tier categories"
    task :tier_categories => :environment do 
      puts 'importing tier categories...'
      
      ST.each do |attributes|
        unless TierCategory.find_by_name(attributes[:name])
          st = TierCategory.create(attributes)
          if st.valid?
           puts "'#{st.name}' created."
          else
           puts "'#{st.name}' errors '#{st.errors.full_messages.join(', ')}'."
          end
        end
      end

      puts 'done.'
    end
    
  end
  
  namespace :purge do

    desc "purges tier categories"
    task :tier_categories => :environment do 
      puts 'purging tier categories...'
      ST.each do |attributes|
        if st = TierCategory.find_by_name(attributes[:name])
          st.destroy
          puts "'#{st.name}' destroyed."
        end
      end
      puts 'done.'
    end

  end
  
end