namespace :data do
  
  namespace :import do

    desc "create groups data"
    task :groups => :environment do 
      puts 'importing groups...'
      
      #--- computers
      g1 = Group.create({
        :name => 'Computers',
        :name_de => 'Computer',
        :name_es => 'Computadoras',
        :site_name => 'computer',
        :summary => "",
        :summary_de => "",
        :summary_es => "",
        :description => "",
        :description_de => "",
        :description_es => "",
        :tags => Tag.tokenize("programming, software, security, hardware, operating systems, internet, mobile", :language_code => "en") +
          Tag.tokenize("Computer, Programmierung, Software, Sicherheit, Hardware, Betriebssysteme, Internet, Mobile", :language_code => "de") +
            Tag.tokenize("computadoras, programación, software, seguridad, hardware, sistemas operativos, internet, móviles", :language_code => "es"),
        :site_url => 'http://computer.luleka.com',
        :language_code => "en",
        :country_code => nil,
        :type => 'Group',
        :image => File.new("#{RAILS_ROOT}/public/images/logos/groups/computer-icon.png"),
        :category => TierCategory.professional_group,
        :created_by => Person.finder("juergen"),
        :owner_email => "juergen@luleka.com",
        :terms_of_service => "1",
        :allow_display_in_directory => true,
        :allow_display_logo_in_profile => true,
        :allow_member_invites => true,
        :accept_person_total_reputation_points => false,
        :accept_default_reputation_threshold => true,
        :accept_default_reputation_points => true
      })
      g1.register!
      g1.activate!
      puts "* '#{g1.name}' group active." if g1.active?

      #--- computers -> programming
      g1t1 = Topic.create({
        :tier => g1,
        :name => "Programming", :name_de => "Programmieren", :name_es => "Programación",
        :site_url => 'http://computers.luleka.com/programming',
        :tags => Tag.tokenize("programming, HTML, CSS, software development, scripting", :language_code => "en") +
          Tag.tokenize("Programmierung, HTML, CSS, Softwareentwicklung, Scripting", :language_code => "de") +
            Tag.tokenize("programación, HTML, CSS, desarrollo de software, scripts", :language_code => "es")
      })
      g1t1.register!
      g1t1.activate!
      puts "- '#{g1t1.name}' topic active." if g1t1.active?

      #--- computers -> software
      g1t2 = Topic.create({
        :tier => g1,
        :name => "Software", :name_de => "Software", :name_es => "Software",
        :site_url => 'http://computers.luleka.com/software',
        :tags => Tag.tokenize("software, standard software", :language_code => "en") +
          Tag.tokenize("Software, Software Pakete, Standardsoftware", :language_code => "de") +
            Tag.tokenize("software, software estándar", :language_code => "es")
      })
      g1t2.register!
      g1t2.activate!
      puts "- '#{g1t2.name}' topic active." if g1t2.active?

      #--- computers -> security
      g1t3 = Topic.create({
        :tier => g1,
        :name => "Security", :name_de => "Security", :name_es => "Seguridad",
        :site_url => 'http://computers.luleka.com/security',
        :tags => Tag.tokenize("security", :language_code => "en") +
          Tag.tokenize("Security", :language_code => "de") +
            Tag.tokenize("seguridad", :language_code => "es")
      })
      g1t3.register!
      g1t3.activate!
      puts "- '#{g1t3.name}' topic active." if g1t3.active?

      #--- computers -> hardware
      g1t4 = Topic.create({
        :tier => g1,
        :name => "Hardware", :name_de => "Hardware", :name_es => "Hardware",
        :site_url => 'http://computers.luleka.com/hardware',
        :tags => Tag.tokenize("hardware", :language_code => "en") +
          Tag.tokenize("hardware", :language_code => "de") +
            Tag.tokenize("hardware", :language_code => "es")
      })
      g1t4.register!
      g1t4.activate!
      puts "- '#{g1t4.name}' topic active." if g1t4.active?

      #--- computers -> hardware
      g1t5 = Topic.create({
        :tier => g1,
        :name => "Operating Systems", :name_de => "Betriebssysteme", :name_es => "Sistema Operativo",
        :site_url => 'http://computers.luleka.com/operating-systems',
        :tags => Tag.tokenize("operating systems, operating system, OS", :language_code => "en") +
          Tag.tokenize("Betriebssysteme, Betriebssystem, OS", :language_code => "de") +
            Tag.tokenize("sistemas operativos, sistema operativo", :language_code => "es")
      })
      g1t5.register!
      g1t5.activate!
      puts "- '#{g1t5.name}' topic active." if g1t5.active?

      #--- computers -> internet
      g1t6 = Topic.create({
        :tier => g1,
        :name => "Internet", :name_de => "Internet", :name_es => "Internet",
        :site_url => 'http://computers.luleka.com/internet',
        :tags => Tag.tokenize("internet, HTML, CSS, JavaScript", :language_code => "en") +
          Tag.tokenize("Internet, HTML, CSS, JavaScript", :language_code => "de") +
            Tag.tokenize("Internet, HTML, CSS, JavaScript", :language_code => "es")
      })
      g1t6.register!
      g1t6.activate!
      puts "- '#{g1t6.name}' topic active." if g1t6.active?

      #--- computers -> mobile
      g1t7 = Topic.create({
        :tier => g1,
        :name => "Mobile", :name_de => "Mobil", :name_es => "Móviles",
        :site_url => 'http://computers.luleka.com/mobile',
        :tags => Tag.tokenize("mobile, wireless", :language_code => "en") +
          Tag.tokenize("Mobilgeräte, Drahtlos", :language_code => "de") +
            Tag.tokenize("móviles, inalámbricas", :language_code => "es")
      })
      g1t7.register!
      g1t7.activate!
      puts "- '#{g1t7.name}' topic active." if g1t7.active?



      #--- biz
      g2 = Group.create({
        :name => 'Business and Money',
        :name_de => 'Business und Finanzen',
        :name_es => 'Negocios y Dinero',
        :site_name => 'money',
        :summary => "",
        :summary_de => "",
        :summary_es => "",
        :description => "",
        :description_de => "",
        :description_es => "",
        :tags => Tag.tokenize("business, money, accounting, finance, small business, employment, advertising, marketing", :language_code => "en") +
          Tag.tokenize("Business, Geld, Rechnungswesen, Finanzen, kleine Unternehmen, Anstellung, Werbung, Marketing", :language_code => "de") +
            Tag.tokenize("negocio, dinero, contabilidad, finanzas, pimes, empleo, publicidad, marketing", :language_code => "es"),
        :site_url => 'http://biz.luleka.com',
        :language_code => "en",
        :country_code => nil,
        :type => 'Group',
        :image => File.new("#{RAILS_ROOT}/public/images/logos/groups/biz-icon.png"),
        :category => TierCategory.professional_group,
        :created_by => Person.finder("juergen"),
        :owner_email => "juergen@luleka.com",
        :terms_of_service => "1",
        :allow_display_in_directory => true,
        :allow_display_logo_in_profile => true,
        :allow_member_invites => true,
        :accept_person_total_reputation_points => false,
        :accept_default_reputation_threshold => true,
        :accept_default_reputation_points => true
      })
      g2.register!
      g2.activate!
      puts "* '#{g2.name}' group active." if g2.active?

      #--- biz -> accounting
      g2t1 = Topic.create({
        :tier => g2,
        :name => "Accounting", :name_de => "Buchhaltung", :name_es => "Contabilidad",
        :site_url => 'http://biz.luleka.com/accounting',
        :tags => Tag.tokenize("", :language_code => "en") +
          Tag.tokenize("", :language_code => "de") +
            Tag.tokenize("", :language_code => "es")
      })
      g2t1.register!
      g2t1.activate!
      puts "- '#{g2t1.name}' topic active." if g2t1.active?

      #--- biz -> finance
      g2t2 = Topic.create({
        :tier => g2,
        :name => "Finance", :name_de => "Finanzen", :name_es => "Finanzas",
        :site_url => 'http://biz.luleka.com/finance',
        :tags => Tag.tokenize("finance, investment, profit", :language_code => "en") +
          Tag.tokenize("Finanzen, Investitionen, Gewinne", :language_code => "de") +
            Tag.tokenize("finanzas, inversiones, beneficio", :language_code => "es")
      })
      g2t2.register!
      g2t2.activate!
      puts "- '#{g2t2.name}' topic active." if g2t2.active?

      #--- biz -> small business
      g2t3 = Topic.create({
        :tier => g2,
        :name => "Small Business", :name_de => "Kleinunternehmen", :name_es => "Pequeña empresa",
        :site_url => 'http://biz.luleka.com/small-business',
        :tags => Tag.tokenize("small business, SMB, small businesses, medium businesses", :language_code => "en") +
          Tag.tokenize("Kleinunternehmen, Kleinbetriebe, mittelständische Unternehmen", :language_code => "de") +
            Tag.tokenize("Pequeña empresa, PYME, PYMES, empresas pequeñas, medianas empresas", :language_code => "es")
      })
      g2t3.register!
      g2t3.activate!
      puts "- '#{g2t3.name}' topic active." if g2t3.active?

      #--- biz -> employment
      g2t4 = Topic.create({
        :tier => g2,
        :name => "Employment", :name_de => "Arbeitsverhältnis", :name_es => "Empleo",
        :site_url => 'http://biz.luleka.com/employment',
        :tags => Tag.tokenize("employment, employment contracts, payment", :language_code => "en") +
          Tag.tokenize("Anstellung, Arbeitsverträge, Zahlung", :language_code => "de") +
            Tag.tokenize("empleo, contratos de trabajo, pago", :language_code => "es")
      })
      g2t4.register!
      g2t4.activate!
      puts "- '#{g2t4.name}' topic active." if g2t4.active?

      #--- biz -> advertising-and-marketing
      g2t5 = Topic.create({
        :tier => g2,
        :name => "Advertising and Marketing", :name_de => "Werbung und Marketing", :name_es => "Publicidad y Marketing",
        :site_url => 'http://biz.luleka.com/advertising-and-marketing',
        :tags => Tag.tokenize("advertising, marketing, communication, public relations", :language_code => "en") +
          Tag.tokenize("Werbung, Marketing, Kommunikation, Public Relations", :language_code => "de") +
            Tag.tokenize("publicidad, marketing, comunicación, relaciones públicas", :language_code => "es")
      })
      g2t5.register!
      g2t5.activate!
      puts "- '#{g2t5.name}' topic active." if g2t5.active?


      #--- health
      g3 = Group.create({
        :name => 'Health',
        :name_de => 'Gesundheit',
        :name_es => 'Salud',
        :site_name => 'med',
        :summary => "",
        :summary_de => "",
        :summary_es => "",
        :description => "",
        :description_de => "",
        :description_es => "",
        :tags => Tag.tokenize("health, conditions, deseases, medicine, children, fitness, nutrition, beauty", :language_code => "en") +
          Tag.tokenize("Gesundheit, Gesundheitszustand, Krankheiten, Medizin, Kinder, Fitness, Ernährung, Beauty", :language_code => "de") +
            Tag.tokenize("salud, symptomas, enfermedades, medicamentos, niños, fitness, nutrición, belleza", :language_code => "es"),
        :site_url => 'http://med.luleka.com',
        :language_code => "en",
        :country_code => nil,
        :type => 'Group',
        :image => File.new("#{RAILS_ROOT}/public/images/logos/groups/health-icon.png"),
        :category => TierCategory.professional_group,
        :created_by => Person.finder("juergen"),
        :owner_email => "juergen@luleka.com",
        :terms_of_service => "1",
        :allow_display_in_directory => true,
        :allow_display_logo_in_profile => true,
        :allow_member_invites => true,
        :accept_person_total_reputation_points => false,
        :accept_default_reputation_threshold => true,
        :accept_default_reputation_points => true
      })
      g3.register!
      g3.activate!
      puts "* '#{g3.name}' group active." if g3.active?

      #--- med -> conditions-and-diseases
      g3t1 = Topic.create({
        :tier => g3,
        :name => "Conditions and Diseases", :name_de => "Symptome und Krankheit", :name_es => "Síntomas",
        :site_url => 'http://med.luleka.com/conditions-and-diseases',
        :tags => Tag.tokenize("conditions, diseases, illnesses, symptoms", :language_code => "en") +
          Tag.tokenize("Krankheiten, Krankheit, Symptome", :language_code => "de") +
            Tag.tokenize("condiciones, enfermedades, síntomas", :language_code => "es")
      })
      g3t1.register!
      g3t1.activate!
      puts "- '#{g3t1.name}' topic active." if g3t1.active?

      #--- med -> medicine
      g3t2 = Topic.create({
        :tier => g3,
        :name => "Medicine", :name_de => "Arzneimittel", :name_es => "Medicamentos",
        :site_url => 'http://med.luleka.com/medicine',
        :tags => Tag.tokenize("medicine, pills, drugs", :language_code => "en") +
          Tag.tokenize("Medizin, Pillen, Drogen", :language_code => "de") +
            Tag.tokenize("medicina, píldoras, drogas", :language_code => "es")
      })
      g3t2.register!
      g3t2.activate!
      puts "- '#{g3t2.name}' topic active." if g3t2.active?

      #--- med -> children
      g3t3 = Topic.create({
        :tier => g3,
        :name => "Children", :name_de => "Kinder", :name_es => "Niños",
        :site_url => 'http://med.luleka.com/children',
        :tags => Tag.tokenize("children, childhood disease", :language_code => "en") +
          Tag.tokenize("Kinder, Kinderkrankheiten", :language_code => "de") +
            Tag.tokenize("niños, enfermedad de la infancia", :language_code => "es")
      })
      g3t3.register!
      g3t3.activate!
      puts "- '#{g3t3.name}' topic active." if g3t3.active?

      #--- med -> fitness-and-nutrition
      g3t4 = Topic.create({
        :tier => g3,
        :name => "Fitness and Nutrition", :name_de => "Fitness und Ernährung", :name_es => "Fitness y Nutrición",
        :site_url => 'http://med.luleka.com/fitness-and-nutrition',
        :tags => Tag.tokenize("fitness, nutrition, wellbeing", :language_code => "en") +
          Tag.tokenize("Fitness, Ernährung, Wohlbefinden", :language_code => "de") +
            Tag.tokenize("fitness, nutrición, bienestar", :language_code => "es")
      })
      g3t4.register!
      g3t4.activate!
      puts "- '#{g3t4.name}' topic active." if g3t4.active?

      #--- med -> beauty
      g3t5 = Topic.create({
        :tier => g3,
        :name => "Beauty", :name_de => "Beauty", :name_es => "Belleza",
        :site_url => 'http://med.luleka.com/beauty',
        :tags => Tag.tokenize("beauty, plastic surgery", :language_code => "en") +
          Tag.tokenize("Beauty, Schönheit, Chirurgie, Plastische Chirurgie", :language_code => "de") +
            Tag.tokenize("belleza, cirugía, cirugía plástica", :language_code => "es")
      })
      g3t5.register!
      g3t5.activate!
      puts "- '#{g3t5.name}' topic active." if g3t5.active?


      #--- tourism
      g4 = Group.create({
        :name => 'Tourism',
        :name_de => 'Touristik',
        :name_es => 'Turismo',
        :site_name => 'travel',
        :summary => "",
        :summary_de => "",
        :summary_es => "",
        :description => "",
        :description_de => "",
        :description_es => "",
        :tags => Tag.tokenize("health, conditions, deseases, medicine, children, fitness, nutrition, beauty", :language_code => "en") +
          Tag.tokenize("Gesundheit, Gesundheitszustand, Krankheiten, Medizin, Kinder, Fitness, Ernährung, Beauty", :language_code => "de") +
            Tag.tokenize("salud, symptomas, enfermedades, remedios, niños, fitness, nutrición, belleza", :language_code => "es"),
        :site_url => 'http://med.luleka.com',
        :language_code => "en",
        :country_code => nil,
        :type => 'Group',
        :image => File.new("#{RAILS_ROOT}/public/images/logos/groups/tourism-icon.png"),
        :category => TierCategory.professional_group,
        :created_by => Person.finder("juergen"),
        :owner_email => "juergen@luleka.com",
        :terms_of_service => "1",
        :allow_display_in_directory => true,
        :allow_display_logo_in_profile => true,
        :allow_member_invites => true,
        :accept_person_total_reputation_points => false,
        :accept_default_reputation_threshold => true,
        :accept_default_reputation_points => true
      })
      g4.register!
      g4.activate!
      puts "* '#{g4.name}' group active." if g4.active?

      #--- travel -> accommodations
      g4t1 = Topic.create({
        :tier => g4,
        :name => "Accommodations", :name_de => "Beherbergung", :name_es => "Alojamiento",
        :site_url => 'http://med.luleka.com/accommodations',
        :tags => Tag.tokenize("", :language_code => "en") +
          Tag.tokenize("", :language_code => "de") +
            Tag.tokenize("", :language_code => "es")
      })
      g4t1.register!
      g4t1.activate!
      puts "- '#{g4t1.name}' topic active." if g4t1.active?

      #--- travel -> transportation
      g4t2 = Topic.create({
        :tier => g4,
        :name => "Transportation", :name_de => "Beförderung", :name_es => "Transportación",
        :site_url => 'http://med.luleka.com/transportation',
        :tags => Tag.tokenize("transportation, car rental, rental, car, public transportation, bus, train, shuttle, cab, taxi", :language_code => "en") +
          Tag.tokenize("Transport, Autovermietung, Mietauto, Auto, öffentliche Verkehrsmittel, Bus, Bahn, Taxi", :language_code => "de") +
            Tag.tokenize("transportación, coche, auto, transporte público, tren, autobus, bus, colectivo, taxi", :language_code => "es")
      })
      g4t2.register!
      g4t2.activate!
      puts "- '#{g4t2.name}' topic active." if g4t2.active?

      #--- travel -> food-and-restaurants
      g4t3 = Topic.create({
        :tier => g4,
        :name => "Food and Restaurants", :name_de => "Restaurants und Verpflegung", :name_es => "Comida y Restaurantes",
        :site_url => 'http://med.luleka.com/food-and-restaurants',
        :tags => Tag.tokenize("gastronomy, catering, food, restaurant, drink, dinner, lunch, breakfast", :language_code => "en") +
          Tag.tokenize("Gastronomie, Catering, Essen, Restaurant, Trinken, Drink, Abendessen, Mittagessen, Frühstück", :language_code => "de") +
            Tag.tokenize("gastronomía, restauración, abastecimiento, restaurant, bebida, cena, almuerzo, desayuno", :language_code => "es")
      })
      g4t3.register!
      g4t3.activate!
      puts "- '#{g4t3.name}' topic active." if g4t3.active?

      #--- travel -> entertainment
      g4t4 = Topic.create({
        :tier => g4,
        :name => "Entertainment", :name_de => "Unterhaltung", :name_es => "Entretenimiento",
        :site_url => 'http://med.luleka.com/entertainment',
        :tags => Tag.tokenize("entertainment, dance, disco, club, concert, theater, theatre, museum", :language_code => "en") +
          Tag.tokenize("Unterhaltung, Tanz, Disco, Konzert, Theater, Museum", :language_code => "de") +
            Tag.tokenize("entretenimiento, baile, discoteca, club, concierto, teatro, museo, boliche", :language_code => "es")
      })
      g4t4.register!
      g4t4.activate!
      puts "- '#{g4t4.name}' topic active." if g4t4.active?

      #--- travel -> attractions
      g4t5 = Topic.create({
        :tier => g4,
        :name => "Attractions", :name_de => "Attraktionen", :name_es => "Atracciones",
        :site_url => 'http://med.luleka.com/attractions',
        :tags => Tag.tokenize("attractions, theme parks, museum", :language_code => "en") +
          Tag.tokenize("Sehenswürdigkeiten, Freizeitparks, Museum", :language_code => "de") +
            Tag.tokenize("atracciones, parques temáticos, museos", :language_code => "es")
      })
      g4t5.register!
      g4t5.activate!
      puts "- '#{g4t5.name}' topic active." if g4t5.active?

      #--- travel -> travel-agencies
      g4t6 = Topic.create({
        :tier => g4,
        :name => "Travel Agencies", :name_de => "Reisebüros", :name_es => "Agencias de viajes",
        :site_url => 'http://med.luleka.com/travel-agencies',
        :tags => Tag.tokenize("travel agencies, agency, agencies, tours", :language_code => "en") +
          Tag.tokenize("Reisebüros, Agentur, Agenturen, Touren", :language_code => "de") +
            Tag.tokenize("agencias de viajes, agencia, agencias, viajes", :language_code => "es")
      })
      g4t6.register!
      g4t6.activate!
      puts "- '#{g4t6.name}' topic active." if g4t6.active?



      #--- legal
      g5 = Group.create({
        :name => 'Law and Legal',
        :name_de => 'Jura und Recht',
        :name_es => 'Ley y Derecho',
        :site_name => 'legal',
        :summary => "",
        :summary_de => "",
        :summary_es => "",
        :description => "",
        :description_de => "",
        :description_es => "",
        :tags => Tag.tokenize("law, legal, civil law, family law, corporate law, employment law, criminal law, public law", :language_code => "en") +
          Tag.tokenize("Gesetz, Recht, Zivilrecht, Bürgerliches Recht, Familienrecht, Gesellschaftsrecht, Arbeitsrecht, Strafrecht, Öffentliches Recht", :language_code => "de") +
            Tag.tokenize("ley, jurídica, derecho de familia, derecho corporativo, derecho laboral, derecho penal, derecho público", :language_code => "es"),
        :site_url => 'http://legal.luleka.com',
        :language_code => "en",
        :country_code => nil,
        :type => 'Group',
        :image => File.new("#{RAILS_ROOT}/public/images/logos/groups/law-icon.png"),
        :category => TierCategory.professional_group,
        :created_by => Person.finder("juergen"),
        :owner_email => "juergen@luleka.com",
        :terms_of_service => "1",
        :allow_display_in_directory => true,
        :allow_display_logo_in_profile => true,
        :allow_member_invites => true,
        :accept_person_total_reputation_points => false,
        :accept_default_reputation_threshold => true,
        :accept_default_reputation_points => true
      })
      g5.register!
      g5.activate!
      puts "* '#{g5.name}' group active." if g5.active?
      
      #--- legal -> civil-law
      g5t1 = Topic.create({
        :tier => g5,
        :name => "Civil Law", :name_de => "Bürgerliches Recht", :name_es => "Derecho Civil",
        :site_url => 'http://med.luleka.com/civil-law',
        :tags => Tag.tokenize("civil law, tenancy, rental agreement, lease, leasing contract, property, properties, privacy law", :language_code => "en") +
          Tag.tokenize("Zivilrecht, Mietrecht, Mietvertrag, Leasing, Leasingvertrag, Immobilien, Datenschutz", :language_code => "de") +
            Tag.tokenize("Derecho civil, arrendamiento, contrato de alquiler, arrendamiento, contrato de arrendamiento, propiedad, propiedades, derecho de privacidad", :language_code => "es")
      })
      g5t1.register!
      g5t1.activate!
      puts "- '#{g5t1.name}' topic active." if g5t1.active?

      #--- legal -> family-law
      g5t2 = Topic.create({
        :tier => g5,
        :name => "Family Law", :name_de => "Familienrecht", :name_es => "Derecho de familia",
        :site_url => 'http://med.luleka.com/family-law',
        :tags => Tag.tokenize("adoption, custody, visitation, child support, divorce separation, paternity, prenuptials, prenuptial, marital property", :language_code => "en") +
          Tag.tokenize("Adoption, Sorgerecht, Besuchsrecht, Alimente, Scheidung, Trennung, Vaterschaft, Ehevertrag, Güterstand", :language_code => "de") +
            Tag.tokenize("adopción, custodia, visitas, manutención, separación, divorcio, paternidad, prenupciales, estado civil", :language_code => "es")
      })
      g5t2.register!
      g5t2.activate!
      puts "- '#{g5t2.name}' topic active." if g5t2.active?

      #--- legal -> corporate-law
      g5t3 = Topic.create({
        :tier => g5,
        :name => "Corporate Law", :name_de => "Gesellschaftsrecht", :name_es => "Derecho de sociedades",
        :site_url => 'http://med.luleka.com/corporate-law',
        :tags => Tag.tokenize("corporate law, corporation", :language_code => "en") +
          Tag.tokenize("Gesellschaftsrecht, Körperschaft", :language_code => "de") +
            Tag.tokenize("derecho corporativo, corporación", :language_code => "es")
      })
      g5t3.register!
      g5t3.activate!
      puts "- '#{g5t3.name}' topic active." if g5t3.active?
      
      #--- legal -> employment-law
      g5t4 = Topic.create({
        :tier => g5,
        :name => "Employment Law", :name_de => "Arbeitsrecht", :name_es => "Ley de Empleo",
        :site_url => 'http://med.luleka.com/employment-law',
        :tags => Tag.tokenize("employment law, employement, labor law, employment discrimination, bullying, employment contract, hostile environment, sexual harassment, leave of absence, layoff, dismissal, termination, disability", :language_code => "en") +
          Tag.tokenize("Arbeitsrecht, Diskriminierung am Arbeitsplatz, Diskriminierung, Mobbing, Arbeitsvertrag, sexuelle Belästigung, Entlassung, Kündigung", :language_code => "de") +
            Tag.tokenize("derecho del trabajo, ley de empleo, empleo, legislación laboral, discriminación laboral, contrato de trabajo, ambiente hostil, acoso sexual, permiso de ausencia, despido, cese, incapacidad", :language_code => "es")
      })
      g5t4.register!
      g5t4.activate!
      puts "- '#{g5t4.name}' topic active." if g5t4.active?

      #--- legal -> criminal-law
      g5t5 = Topic.create({
        :tier => g5,
        :name => "Criminal Law", :name_de => "Strafrecht", :name_es => "Derecho Penal",
        :site_url => 'http://med.luleka.com/criminal-law',
        :tags => Tag.tokenize("personal injury, assault, battery, mayhem, bodily harm, domestic violance, evation, tax evation, drug crime, drunk driving, DUI, traffic violation, trespas, breach of domestic peace, unlawful entry, false testimony, perjury, defamation, slander, kidnapping, kidnap, hostage, coercion, burglary, larceny, theft, thievery, defalcation, concealment, embezzlement, fraud, deprivation, heist, predation, rape, robbery, swag, blackmail, forging, falsification, forgery, counterfeit, insolvency fraud, malicious arson, fire raising, incendiarism, pollution, corruption, corruptibility, venality, vandalism, property damage, graffity, sexual assault, rape, child abuse", :language_code => "en") +
          Tag.tokenize("Körperverletzung, häusliche Gewalt, steuerhinterziehen, Steuerhinterziehung, Drogenkriminalität, Trunkenheit am Steuer, Verkehrsdelikt, Hausfriedensbruch, Falschaussage, Meineid, Verleumdung, üble Nachrede, Entführung, Geiselnahme, Nötigung, Diebstahl, Veruntreuung, Unterschlagung, Betrug, Raub, Plünderung, Vergewaltigung, Raub, Beute, Erpressung, Fälschung, Insolvenzverschleppung, Brandstiftung, Umweltverschmutzung, Korruption, Bestechlichkeit, Käuflichkeit, Vandalismus, Sachbeschädigung, Graffiti, sexuelle Nötigung, Vergewaltigung, Kindesmissbrauch", :language_code => "de") +
            Tag.tokenize("lesiones personales, asalto, agresión, mutilación, lesiones corporales, violance nacional, evation, evation fiscal, drogas, conducir borracho, violación de tráfico, quebrantamiento de la paz nacional, entrada ilegal, falso testimonio, perjurio, difamación, calumnia, secuestro, toma de rehenes, coacción, robo, hurto, desfalco, ocultamiento, malversación, fraude, privación, depredación, violación, botín, chantaje, forja, falsificación, adulteración, falsificación, fraude de insolvencia, incendios provocados, incendiarios, contaminación, corrupción, corruptibilidad, venalidad, vandalismo, daños a la propiedad, graffity, asalto sexual, violación, abuso infantil", :language_code => "es")
      })
      g5t5.register!
      g5t5.activate!
      puts "- '#{g5t5.name}' topic active." if g5t5.active?

      
      puts 'done.'
    end
    
  end
  
  namespace :purge do

    desc "purges groups data"
    task :groups => :environment do 
      gs = []
      puts 'purging groups...'

      puts "'#{gs.first.name}' destroyed." unless (gs = Tier.destroy_all(:site_name => "computer")).empty?
      puts "'#{gs.first.name}' destroyed." unless (gs = Tier.destroy_all(:site_name => "money")).empty?
      puts "'#{gs.first.name}' destroyed." unless (gs = Tier.destroy_all(:site_name => "med")).empty?
      puts "'#{gs.first.name}' destroyed." unless (gs = Tier.destroy_all(:site_name => "travel")).empty?
      puts "'#{gs.first.name}' destroyed." unless (gs = Tier.destroy_all(:site_name => "legal")).empty?
      
      puts 'done.'
    end

  end
  
end