namespace :data do
  #--- import
  namespace :import do

    desc "import probono organizations and products"
    task :probono => :environment do 
      Rake::Task['data:import:probono:organizations'].invoke
      Rake::Task['data:import:probono:products'].invoke
    end
    
    namespace :probono do

      PROBONO_ORGANIZATIONS = [{
        #--- luleka intl.
        :kind => :company,
        :site_name => 'luleka',
        :site_url => 'http://www.luleka.net',
        :name => 'Luleka',
        :name_de => nil,
        :image => File.new("#{RAILS_ROOT}/public/images/logos/organizations/luleka.jpg"),
        :tagline => 'In any case',
        :tax_code => nil,
        :country_code => nil,
        :address_attributes => {
          :street => '101 Rousseau St.',
          :city => 'San Francisco',
          :postal_code => '94112',
          :province_code => 'CA',
          :country_code => 'US',
          :phone => '+1 (415) 308-5782',
          :mobile => '+1 (415) 308-5783',
          :fax => '+1 (415) 308-5784'
        },
        :description => 'Luleka is an online community that intends to improve customer satisfaction through customer conversations. It allows users seek specific responses to personal cases about organizations, products or locations.',
        :description_de => 'Luleka ist ein soziales Netzwerk mit dem Ziel Kundenzufriedenheit durch Kundengespräche zu verbessern. Es erlaubt seinen Benutzern gezielte Stellungnahmen auf persönliche Fälle zu erhalten.'
      }, {
        #--- luleka us
        :kind => :company,
        :site_name => 'luleka',
        :site_url => 'http://www.luleka.com',
        :name => 'Luleka LLC',
        :name_de => nil,
        :image => File.new("#{RAILS_ROOT}/public/images/logos/organizations/luleka.jpg"),
        :tagline => 'In any case',
        :tax_code => '23-4527456',
        :country_code => 'US',
        :address_attributes => {
          :street => '101 Rousseau St.',
          :city => 'San Francisco',
          :postal_code => '94112',
          :province_code => 'CA',
          :country_code => 'US',
          :phone => '+1 (415) 308-5782',
          :mobile => '+1 (415) 308-5783',
          :fax => '+1 (415) 308-5784'
        },
        :description => 'Luleka is an online community that intends to improve customer satisfaction through customer conversations. It allows users seek specific responses to personal cases about organizations, products or locations.',
        :description_de => 'Luleka ist ein soziales Netzwerk mit dem Ziel Kundenzufriedenheit durch Kundengespräche zu verbessern. Es erlaubt seinen Benutzern gezielte Stellungnahmen auf persönliche Fälle zu erhalten.'
      }, {
        #--- luleka de
        :kind => :company,
        :site_name => 'luleka',
        :site_url => 'http://www.luleka.de',
        :name => 'Luleka GmbH',
        :name_de => nil,
        :image => File.new("#{RAILS_ROOT}/public/images/logos/organizations/luleka.jpg"),
        :tagline => 'Auf jeden Fall',
        :tax_code => 'DE176893842',
        :country_code => 'DE',
        :address_attributes => {
          :street => 'Annette-Kolb-Anger 4',
          :city => 'München',
          :postal_code => '81737',
          :province_code => 'BY',
          :country_code => 'DE',
          :phone => '+49 (89) 1234567',
          :mobile => '+49 (89) 123456',
          :fax => '+49 (89) 123458'
        },
        :description => 'Luleka is an online community that intends to improve customer satisfaction through customer conversations. It allows users seek specific responses to personal cases about organizations, products or locations.',
        :description_de => 'Luleka ist ein soziales Netzwerk mit dem Ziel Kundenzufriedenheit durch Kundengespräche zu verbessern. Es erlaubt seinen Benutzern gezielte Stellungnahmen auf persönliche Fälle zu erhalten.'
      }]

      desc "create probono organizations data"
      task :organizations => :environment do
        puts 'importing probono organizations...'

        PROBONO_ORGANIZATIONS.select {|o| o[:site_name] == 'luleka'}.each do |attributes|
          root = Organization.find_root_by_permalink_and_active(attributes[:site_name])
          attributes.merge!(:parent_id => root ? root.id : nil)
          type = attributes.delete(:kind)
          org = Tier.new(attributes.merge(:type => type))

          if org.save
            org.register!
            org.activate!
            puts "'#{org.name}' created."
          else
            puts "'#{org.name}' error #{org.errors.full_messages.join(', ')}."
          end
        end

        puts 'done.'
      end
      
      desc "create probono products data"
      task :products => :environment do 
        puts 'importing probono products...'

        probono_us = Organization.find_by_permalink_and_region_and_active('luleka', 'US')
        probono_de = Organization.find_by_permalink_and_region_and_active('luleka', 'DE')
        
        break unless probono_us || probono_de

        #--- setup prices

        # us dollars
        usd_membership = ProductPrice.create(
          :currency => 'USD',
          :cents => 495 # 995
        )
        usd_3m_membership = ProductPrice.create(
          :currency => 'USD',
          :cents => 1485 # 2985
        )
        usd_6m_membership = ProductPrice.create(
          :currency => 'USD',
          :cents => 2890 # ???
        )
        usd_1y_membership = ProductPrice.create(
          :currency => 'USD',
          :cents => 4995 # 9995
        )
        usd_2y_membership = ProductPrice.create(
          :currency => 'USD',
          :cents => 8995 # 18995
        )
        usd_listing_fee = ProductPrice.create(
          :currency => 'USD',
          :cents => 25
        )
        usd_service_fee = ProductPrice.create(
          :currency => 'USD',
          :cents => 50,
          :percentage => 20
        )
        usd_credit = ProductPrice.create(
          :currency => 'USD',
          :cents => 100
        )
        usd_5_credit  = ProductPrice.create(
          :currency => 'USD',
          :cents => 500
        )
        usd_25_credit  = ProductPrice.create(
          :currency => 'USD',
          :cents => 2500
        )

        # euros                                          
        eur_membership = ProductPrice.create(
          :currency => 'EUR',
          :cents => 495
        )
        eur_3m_membership = ProductPrice.create(
          :currency => 'EUR',
          :cents => 1485
        )
        eur_6m_membership = ProductPrice.create(
          :currency => 'EUR',
          :cents => 2890
        )
        eur_1y_membership = ProductPrice.create(
          :currency => 'EUR',
          :cents => 4995
        )
        eur_2y_membership = ProductPrice.create(
          :currency => 'EUR',
          :cents => 8995
        )
        eur_listing_fee = ProductPrice.create(
          :currency => 'EUR',
          :cents => 25
        )
        eur_service_fee = ProductPrice.create(
          :currency => 'EUR',
          :cents => 20,
          :percentage => 20
        )
        eur_credit = ProductPrice.create(
          :currency => 'EUR',
          :cents => 100
        )
        eur_5_credit = ProductPrice.create(
          :currency => 'EUR',
          :cents => 500
        )
        eur_25_credit = ProductPrice.create(
          :currency => 'EUR',
          :cents => 2500
        )

        #--- US products

        # 1 month membership fee
        expert_membership = Service.find_or_build(
          :organization => probono_us,
          :sku => 'SU00100EN-US',
          :name => 'One-Month Partner Membership',
          :name_de => 'Ein Monat Partner Mitgliedschaft',
          :unit => 'month',
          :pieces => 1,
          :internal => true,
          :description => "One month Luleka Partner Membership for %{price}",
          :description_de => "Ein Monat Luleka Partner Mitgliedschaft für %{price}"
        )
        if expert_membership.new_record?
          expert_membership.save(false)
          expert_membership.prices << usd_membership
          expert_membership.prices << eur_membership
          expert_membership.save
          expert_membership.register!
  #        expert_membership.activate!
          puts "'#{expert_membership.name}' added."
        end

        # 3 months membership fee
        expert_membership = Service.find_or_build(
          :organization => probono_us,
          :sku => 'SU00101EN-US',
          :name => "Three-Month Partner Membership",
          :name_de => "Vierteljährliche Partner Mitgliedschaft",
          :unit => 'month',
          :pieces => 3,
          :internal => true,
          :description => "%{unit} Luleka Partner Membership for %{price}",
          :description_de => "%{unit} Luleka Partner Mitgliedschaft für %{price}"
        )
        if expert_membership.new_record?
          expert_membership.save(false)
          expert_membership.prices << usd_3m_membership
          expert_membership.prices << eur_3m_membership
          expert_membership.save
          expert_membership.register!
          expert_membership.activate!
          puts "'#{expert_membership.name}' added."
        end

        # 6 months membership fee
        expert_membership = Service.find_or_build(
          :organization => probono_us,
          :sku => 'SU00102EN-US',
          :name => "Six-Month Partner Membership",
          :name_de => "Halbjährliche Partner Mitgliedschaft",
          :unit => 'month',
          :pieces => 6,
          :internal => true,
          :description => "%{unit} Luleka Partner Membership for %{price}",
          :description => "%{unit} Luleka Partner Mitgliedschaft für %{price}"
        )
        if expert_membership.new_record?
          expert_membership.save(false)
          expert_membership.prices << usd_6m_membership
          expert_membership.prices << eur_6m_membership
          expert_membership.save
          expert_membership.register!
  #        expert_membership.activate!
          puts "'#{expert_membership.name}' added."
        end

        # 1 year membership fee
        expert_membership = Service.find_or_build(
          :organization => probono_us,
          :sku => 'SU00103EN-US',
          :name => "One-Year Partner Membership",
          :name_de => "Einjährige Partner Mitgliedschaft",
          :unit => 'month',
          :pieces => 12,
          :internal => true,
          :description => "%{unit} Luleka Partner Membership for %{price}",
          :description_de => "%{unit} Luleka Partner Mitgliedschaft für %{price}"
        )
        if expert_membership.new_record?
          expert_membership.save(false)
          expert_membership.prices << usd_1y_membership
          expert_membership.prices << eur_1y_membership
          expert_membership.save
          expert_membership.register!
          expert_membership.activate!
          puts "'#{expert_membership.name}' added."
        end

        # 2 year membership fee
        expert_membership = Service.find_or_build(
          :organization => probono_us,
          :sku => 'SU00104EN-US',
          :name => "Two-Year Partner Membership",
          :name_de => "Zweijährige Partner Mitgliedschaft",
          :unit => 'month',
          :pieces => 24,
          :internal => true,
          :description => "%{unit} Luleka Partner Membership for %{price}",
          :description_de => "%{unit} Luleka Partner Mitgliedschaft für %{price}"
        )
        if expert_membership.new_record?
          expert_membership.save(false)
          expert_membership.prices << usd_2y_membership
          expert_membership.prices << eur_2y_membership
          expert_membership.save
          expert_membership.register!
          expert_membership.activate!
          puts "'#{expert_membership.name}' added."
        end

        # listing fee                                       
        listing_fee = Product.find_or_build(
          :organization => probono_us,
          :sku => 'PR00200EN-US',
          :name => "Listing Fee",
          :name_de => "Einstellgebühr",
          :unit => 'piece',
          :pieces => 1,
          :internal => true,
          :description => "Listing fee",
          :description_de => "Einmalige Einstellgebühr"
        )
        if listing_fee.new_record?
          listing_fee.save(false)
          listing_fee.prices << usd_listing_fee
          listing_fee.prices << eur_listing_fee
          listing_fee.save                     
          listing_fee.register!
    #      listing_fee.activate!
          puts "'#{listing_fee.name}' added."
        end

        # service fee                                       
        service_fee = Product.find_or_build(
          :organization => probono_us,
          :sku => 'PR00300EN-US',
          :name => "Service Fee",
          :name_de => "Bearbeitungsgebühr",
          :unit => 'piece',
          :pieces => 1,
          :internal => true,
          :description => "%{percentage}% service fee on %{dependent_price} of '%{dependent_name}'",
          :description_de => "%{percentage}% Bearbeitungsgeb\xC3\xBChr auf den Betrag von %{dependent_price} von '%{dependent_name}'"
        )
        if service_fee.new_record?
          service_fee.save(false)
          service_fee.prices << usd_service_fee
          service_fee.prices << eur_service_fee
          service_fee.save                                       
          service_fee.register!
          service_fee.activate!
          puts "'#{service_fee.name}' added."
        end

        # 5 purchasing credit
        credit_5 = Product.find_or_build(
          :organization => probono_us,
          :sku => 'PC00401EN-US',
          :name => "FIVE Purchasing Credit",
          :name_de => "Kaufguthaben FIVE",
          :unit => 'piece',
          :pieces => 1,
          :taxable => false,
          :internal => true,
          :description => "%{unit_price} purchasing credit",
          :description_de => "Kaufguthaben über %{unit_price}"
        )
        if credit_5.new_record?
          credit_5.save(false)
          credit_5.prices << usd_5_credit
          credit_5.prices << eur_5_credit
          credit_5.save                                       
          credit_5.register!
          credit_5.activate!
          puts "'#{credit_5.name}' added."
        end

        # 25 purchasing credit
        credit_25 = Product.find_or_build(
          :organization => probono_us,
          :sku => 'PC00402EN-US',
          :name => "TWENTYFIVE Purchasing Credit",
          :name_de => "Kaufguthaben TWENTYFIVE",
          :unit => 'piece',
          :pieces => 1,
          :taxable => false,
          :internal => true,
          :description => "%{unit_price} purchasing credit",
          :description_de => "Kaufguthaben über %{unit_price}"
        )
        if credit_25.new_record?
          credit_25.save(false)
          credit_25.prices << usd_25_credit
          credit_25.prices << eur_25_credit
          credit_25.save                                       
          credit_25.register!
          credit_25.activate!
          puts "'#{credit_25.name}' added."
        end

        #--- DE products

        # 1 monat mietgliedschaft
        experten_mitgliedschaft = Service.find_or_build(
          :organization => probono_de,
          :sku => 'SU00100DE-DE',
          :name => 'One-Month Partner Membership',
          :name_de => 'Ein Monat Partner Mitgliedschaft',
          :unit => 'month',
          :pieces => 1,
          :internal => true,
          :description => "One month Luleka Partner Membership for %{price}",
          :description_de => "Ein Monat Luleka Partner Mitgliedschaft für %{price}"
        )
        if experten_mitgliedschaft.new_record?
          experten_mitgliedschaft.save(false)
          experten_mitgliedschaft.prices << usd_membership
          experten_mitgliedschaft.prices << eur_membership
          experten_mitgliedschaft.save
          experten_mitgliedschaft.register!
    #      experten_mitgliedschaft.activate!
          puts "'#{experten_mitgliedschaft.name}' added."
        end

        # 3 monate mitgliedschaft
        experten_mitgliedschaft = Service.find_or_build(
          :organization => probono_de,
          :sku => 'SU00101DE-DE',
          :name => "Three-Month Partner Membership",
          :name_de => "Vierteljährliche Partner Mitgliedschaft",
          :unit => 'month',
          :pieces => 3,
          :internal => true,
          :description => "%{unit} Luleka Partner Membership for %{price}",
          :description_de => "%{unit} Luleka Partner Mitgliedschaft für %{price}"
        )
        if experten_mitgliedschaft.new_record?
          experten_mitgliedschaft.save(false)
          experten_mitgliedschaft.prices << usd_3m_membership
          experten_mitgliedschaft.prices << eur_3m_membership
          experten_mitgliedschaft.save
          experten_mitgliedschaft.register!
          experten_mitgliedschaft.activate!
          puts "'#{experten_mitgliedschaft.name}' added."
        end

        # 6 monate mitgliedschaft
        experten_mitgliedschaft = Service.find_or_build(
          :organization => probono_de,
          :sku => 'SU00102DE-DE',
          :name => "Six-Month Partner Membership",
          :name_de => "Halbjährliche Partner Mitgliedschaft",
          :unit => 'month',
          :pieces => 6,
          :internal => true,
          :description => "%{unit} Luleka Partner Membership for %{price}",
          :description => "%{unit} Luleka Partner Mitgliedschaft für %{price}"
        )
        if experten_mitgliedschaft.new_record?
          experten_mitgliedschaft.save(false)
          experten_mitgliedschaft.prices << usd_6m_membership
          experten_mitgliedschaft.prices << eur_6m_membership
          experten_mitgliedschaft.save
          experten_mitgliedschaft.register!
  #        experten_mitgliedschaft.activate!
          puts "'#{experten_mitgliedschaft.name}' added."
        end

        # 1 jahr mitgliedschaft
        experten_mitgliedschaft = Service.find_or_build(
          :organization => probono_de,
          :sku => 'SU00103DE-DE',
          :name => "One-Year Partner Membership",
          :name_de => "Einjährige Partner Mitgliedschaft",
          :unit => 'month',
          :pieces => 12,
          :internal => true,
          :description => "%{unit} Luleka Partner Membership for %{price}",
          :description_de => "%{unit} Luleka Partner Mitgliedschaft für %{price}"
        )
        if experten_mitgliedschaft.new_record?
          experten_mitgliedschaft.save(false)
          experten_mitgliedschaft.prices << usd_1y_membership
          experten_mitgliedschaft.prices << eur_1y_membership
          experten_mitgliedschaft.save
          experten_mitgliedschaft.register!
          experten_mitgliedschaft.activate!
          puts "'#{experten_mitgliedschaft.name}' added."
        end

        # 2 jahre mitgliedschaft
        experten_mitgliedschaft = Service.find_or_build(
          :organization => probono_de,
          :sku => 'SU00104DE-DE',
          :name => "Two-Year Partner Membership",
          :name_de => "Zweijährige Partner Mitgliedschaft",
          :unit => 'month',
          :pieces => 24,
          :internal => true,
          :description => "%{unit} Luleka Partner Membership for %{price}",
          :description_de => "%{unit} Luleka Partner Mitgliedschaft für %{price}"
        )
        if experten_mitgliedschaft.new_record?
          experten_mitgliedschaft.save(false)
          experten_mitgliedschaft.prices << usd_2y_membership
          experten_mitgliedschaft.prices << eur_2y_membership
          experten_mitgliedschaft.save
          experten_mitgliedschaft.register!
          experten_mitgliedschaft.activate!
          puts "'#{experten_mitgliedschaft.name}' added."
        end

        # einstellgebühr
        einstellgebuehr = Product.find_or_build( 
          :organization => probono_de,
          :sku => 'PR00200DE-DE',
          :name => "Listing Fee",
          :name_de => "Einstellgebühr",
          :unit => 'piece',
          :pieces => 1,
          :internal => true,
          :description => "Listing fee",
          :description_de => "Einmalige Einstellgebühr"
        )
        if einstellgebuehr.new_record?
          einstellgebuehr.save(false)
          einstellgebuehr.prices << usd_listing_fee
          einstellgebuehr.prices << eur_listing_fee
          einstellgebuehr.save                                       
          einstellgebuehr.register!
    #      einstellgebuehr.activate!
          puts "'#{einstellgebuehr.name}' added."
        end

        # service fee
        bearbeitungsgebuehr = Product.find_or_build(
          :organization => probono_de,
          :sku => 'PR00300DE-DE',
          :name => "Service Fee",
          :name_de => "Bearbeitungsgebühr",
          :unit => 'piece',
          :pieces => 1,
          :internal => true,
          :description => "%{percentage}% Bearbeitungsgeb\xC3\xBChr auf den Betrag von %{dependent_price} von '%{dependent_name}'"
        )
        if bearbeitungsgebuehr.new_record?
          bearbeitungsgebuehr.save(false)
          bearbeitungsgebuehr.prices << usd_service_fee
          bearbeitungsgebuehr.prices << eur_service_fee
          bearbeitungsgebuehr.save                                       
          bearbeitungsgebuehr.register!
          bearbeitungsgebuehr.activate!
          puts "'#{bearbeitungsgebuehr.name}' added."
        end

        # 5 kaufguthaben
        guthaben_5 = Product.find_or_build(
          :organization => probono_de,
          :sku => 'PC00401DE-DE',
          :name => "FIVE Purchasing Credit",
          :name_de => "Kaufguthaben FIVE",
          :unit => 'piece',
          :pieces => 1,
          :taxable => false,
          :internal => true,
          :description => "%{unit_price} purchasing credit",
          :description_de => "Kaufguthaben über %{unit_price}"
        )
        if guthaben_5.new_record?
          guthaben_5.save(false)
          guthaben_5.prices << usd_5_credit
          guthaben_5.prices << eur_5_credit
          guthaben_5.save                                       
          guthaben_5.register!
          guthaben_5.activate!
          puts "'#{guthaben_5.name}' added."
        end

        # 25 kaufguthaben
        guthaben_25 = Product.find_or_build(
          :organization => probono_de,
          :sku => 'PC00402DE-DE',
          :name => "TWENTYFIVE Purchasing Credit",
          :name_de => "Kaufguthaben TWENTYFIVE",
          :unit => 'piece',
          :pieces => 1,
          :taxable => false,
          :internal => true,
          :description => "%{unit_price} purchasing credit",
          :description_de => "Kaufguthaben über %{unit_price}"
        )
        if guthaben_25.new_record?
          guthaben_25.save(false)
          guthaben_25.prices << usd_25_credit
          guthaben_25.prices << eur_25_credit
          guthaben_25.save           
          guthaben_25.register!
          guthaben_25.activate!
          puts "'#{guthaben_25.name}' added."
        end

        puts 'done.'
      end
      
    end

  end

  #--- purge
  namespace :purge do

    desc "import probono organizations and products"
    task :probono => :environment do 
      Rake::Task['data:purge:probono:products'].invoke
      Rake::Task['data:purge:probono:organizations'].invoke
    end
    
    namespace :probono do 
      
      desc "purges probono organizations data"
      task :organizations => :environment do 
        puts 'purging probono organizations...'

        if root = Organization.find_root_by_permalink_and_active("luleka")
          root.children.each do |found|
            found.destroy
            puts "'#{found.name}' destroyed."
          end
          root.destroy
          puts "'#{root.name}' destroyed."
        end
        
        puts 'done.'
      end

      desc "purges probono products data"
      task :products => :environment do 
        puts 'purging probono products...'
        
        root = Organization.find_root_by_permalink_and_active("luleka")
        (root.children + [root]).each do |found|
          found.products.each do |product|
            product.destroy
            puts "'#{product.name}' product destroyed."
          end
        end
        
        puts "'#{root.name}' products destroyed."
      end
      
    end

  end
  
end