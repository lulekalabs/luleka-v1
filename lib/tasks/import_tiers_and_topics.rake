namespace :data do
  
  namespace :import do

    ORGANIZATIONS = [{
#--- google      
      :kind => :company,
      :site_name => 'google',
      :site_url => 'http://www.google.com',
      :name => 'Google',
      :name_de => nil,
      :image => File.new("#{RAILS_ROOT}/public/images/logos/organizations/google.jpg"),
      :tagline => nil,
      :tax_code => nil,
      :country_code => nil,
      :address_attributes => {
        :street => '1600 Amphitheatre Parkway',
        :city => 'Mountain View',
        :postal_code => '94043',
        :province_code => 'CA',
        :country_code => 'US',
        :phone => '+1 650-253-0000',
        :fax => '+1 650-253-0001'
      },
      :description => 'Google Inc. is an American public corporation, earning revenue from advertising related to its Internet search, e-mail, online mapping, office productivity, social networking, and video sharing services as well as selling advertising-free versions of the same technologies.',
      :description_de => nil
    }, {
      :kind => :company,
      :site_name => 'google',
      :site_url => 'http://www.google.com',
      :name => 'Google Inc.',
      :name_de => nil,
      :image => File.new("#{RAILS_ROOT}/public/images/logos/organizations/google.jpg"),
      :tagline => nil,
      :tax_code => nil,
      :country_code => 'US',
      :address_attributes => {
        :street => '1600 Amphitheatre Parkway',
        :city => 'Mountain View',
        :postal_code => '94043',
        :province_code => 'CA',
        :country_code => 'US',
        :phone => '+1 650-253-0000',
        :fax => '+1 650-253-0001'
      },
      :description => 'Google Inc. is an American public corporation, earning revenue from advertising related to its Internet search, e-mail, online mapping, office productivity, social networking, and video sharing services as well as selling advertising-free versions of the same technologies.',
      :description_de => nil
    }, {
      :kind => :company,
      :site_name => 'google',
      :site_url => 'http://www.google.de',
      :name => 'Google Deutschland GmbH',
      :name_de => nil,
      :image => File.new("#{RAILS_ROOT}/public/images/logos/organizations/google.jpg"),
      :tagline => nil,
      :tax_code => nil,
      :country_code => 'DE',
      :address_attributes => {
        :street => 'ABC-Strasse 19',
        :city => 'Hamburg',
        :postal_code => '20354',
        :province_code => 'HH',
        :country_code => 'DE',
        :phone => '+49 40-80-81-79-000',
        :fax => '+49 40-4921-9194'
      },
      :description => 'Google Inc. is an American public corporation, earning revenue from advertising related to its Internet search, e-mail, online mapping, office productivity, social networking, and video sharing services as well as selling advertising-free versions of the same technologies.',
      :description_de => 'Google ist der Name einer Suchmaschine. Durch den Erfolg der Suchmaschine konnte das Unternehmen Google eine Reihe weiterer Programme finanzieren, die über die Google-Seite zu erreichen sind.'
    }, {
#--- dell      
      :kind => :company,
      :site_name => 'dell',
      :site_url => 'http://www.dell.com',
      :name => 'Dell',
      :name_de => nil,
      :image => File.new("#{RAILS_ROOT}/public/images/logos/organizations/dell.jpg"),
      :tagline => nil,
      :tax_code => nil,
      :country_code => nil,
      :address_attributes => {
        :street => 'One Dell Way',
        :city => 'Round Rock',
        :postal_code => '78682',
        :province_code => 'TX',
        :country_code => 'US'
      },
      :description => 'Dell, Inc. is a multinational technology corporation that develops, manufactures, sells, and supports personal computers and other computer-related products.',
      :description_de => nil
    }, {
      :kind => :company,
      :site_name => 'dell',
      :site_url => 'http://www.dell.com',
      :name => 'Dell Inc.',
      :name_de => nil,
      :image => File.new("#{RAILS_ROOT}/public/images/logos/organizations/dell.jpg"),
      :tagline => nil,
      :tax_code => nil,
      :country_code => 'US',
      :address_attributes => {
        :street => 'One Dell Way',
        :city => 'Round Rock',
        :postal_code => '78682',
        :province_code => 'TX',
        :country_code => 'US'
      },
      :description => 'Dell, Inc. is a multinational technology corporation that develops, manufactures, sells, and supports personal computers and other computer-related products.',
      :description_de => nil
    }, {
      :kind => :company,
      :site_name => 'dell',
      :site_url => 'http://www.dell.de',
      :name => 'Dell Deutschland GmbH',
      :name_de => nil,
      :image => File.new("#{RAILS_ROOT}/public/images/logos/organizations/dell.jpg"),
      :tagline => nil,
      :tax_code => 'DE113541138',
      :country_code => 'DE',
      :address_attributes => {
        :street => 'Monzastraße 4',
        :city => 'Langen',
        :postal_code => '63225',
        :country_code => 'DE',
        :phone => '06103-971-0',
        :fax => '06103-971-701'
      },
      :description => 'Dell, Inc. is a multinational technology corporation that develops, manufactures, sells, and supports personal computers and other computer-related products.',
      :description_de => 'Das Unternehmen Dell ist ein US-amerikanischer Hersteller von Computer-Hardware.'
    }, {
#--- apple      
      :kind => :company,
      :site_name => 'apple',
      :site_url => 'http://www.apple.com',
      :name => 'Apple',
      :name_de => nil,
      :image => File.new("#{RAILS_ROOT}/public/images/logos/organizations/apple.jpg"),
      :tagline => nil,
      :tax_code => nil,
      :country_code => nil,
      :address_attributes => {
        :street => '1 Infite Loop',
        :city => 'Cupertino',
        :postal_code => '95014',
        :province_code => 'CA',
        :country_code => 'US',
        :phone => '+1 408.996.1010'
      },
      :description => 'Apple designs and creates iPod and iTunes, Mac laptop and desktop computers, the OS X operating system, and the revolutionary iPhone.',
      :description_de => nil
    }, {
      :kind => :company,
      :site_name => 'apple',
      :site_url => 'http://www.apple.com',
      :name => 'Apple Inc.',
      :name_de => nil,
      :image => File.new("#{RAILS_ROOT}/public/images/logos/organizations/apple.jpg"),
      :tagline => nil,
      :tax_code => nil,
      :country_code => 'US',
      :address_attributes => {
        :street => '1 Infite Loop',
        :city => 'Cupertino',
        :postal_code => '95014',
        :province_code => 'CA',
        :country_code => 'US',
        :phone => '+1 408.996.1010'
      },
      :description => 'Apple designs and creates iPod and iTunes, Mac laptop and desktop computers, the OS X operating system, and the revolutionary iPhone.',
      :description_de => nil
    }, {
      :kind => :company,
      :site_name => 'apple',
      :site_url => 'http://www.apple.de',
      :name => 'Apple GmbH',
      :name_de => nil,
      :image => File.new("#{RAILS_ROOT}/public/images/logos/organizations/apple.jpg"),
      :tagline => nil,
      :tax_code => nil,
      :country_code => 'DE',
      :address_attributes => {
        :street => 'Dornacher Straße 3',
        :city => 'Feldkirchen',
        :postal_code => '85622',
        :province_code => 'BY',
        :country_code => 'DE',
        :phone => '+49 (89) 99640-0'
      },
      :description => 'Apple designs and creates iPod and iTunes, Mac laptop and desktop computers, the OS X operating system, and the revolutionary iPhone.',
      :description_de => 'Apple Inc. ist ein Unternehmen mit Hauptsitz in Cupertino, Kalifornien (Vereinigte Staaten), das Computer und Unterhaltungselektronik sowie Betriebssysteme und Anwendungssoftware herstellt.'
    }, {
#--- microsoft
      :kind => :company,
      :site_name => 'microsoft',
      :site_url => 'http://www.microsoft.com',
      :name => 'Microsoft',
      :name_de => nil,
      :image => File.new("#{RAILS_ROOT}/public/images/logos/organizations/microsoft.jpg"),
      :tagline => nil,
      :tax_code => nil,
      :country_code => nil,
      :address_attributes => {
        :address_line_1 => '205 108th Ave. NE',
        :address_line_2 => 'Suite 400',
        :city => 'Bellevue',
        :postal_code => '98004',
        :province_code => 'WA',
        :country_code => 'US',
        :phone => '+1 (425) 705-1900'
      },
      :description => 'Microsoft Corporation is a multinational computer technology corporation that develops, manufactures, licenses, and supports a wide range of software products for computing devices.',
      :description_de => nil
    }, {
      :kind => :company,
      :site_name => 'microsoft',
      :site_url => 'http://www.microsoft.com',
      :name => 'Microsoft Corporation',
      :name_de => nil,
      :image => File.new("#{RAILS_ROOT}/public/images/logos/organizations/microsoft.jpg"),
      :tagline => nil,
      :tax_code => nil,
      :country_code => 'US',
      :address_attributes => {
        :address_line_1 => '205 108th Ave. NE',
        :address_line_2 => 'Suite 400',
        :city => 'Bellevue',
        :postal_code => '98004',
        :province_code => 'WA',
        :country_code => 'US',
        :phone => '+1 (425) 705-1900'
      },
      :description => 'Microsoft Corporation is a multinational computer technology corporation that develops, manufactures, licenses, and supports a wide range of software products for computing devices.',
      :description_de => nil
    }, {
      :kind => :company,
      :site_name => 'microsoft',
      :site_url => 'http://www.microsoft.de',
      :name => 'Microsoft Germany GmbH',
      :name_de => 'Microsoft Deutschland GmbH',
      :image => File.new("#{RAILS_ROOT}/public/images/logos/organizations/microsoft.jpg"),
      :tagline => nil,
      :tax_code => nil,
      :country_code => 'DE',
      :address_attributes => {
        :street => 'Konrad-Zuse-Str. 1',
        :city => 'Unterschleißheim',
        :postal_code => '85716',
        :country_code => 'DE',
        :phone => '+49 89 / 3176-0'
      },
      :description => 'Microsoft Corporation is a multinational computer technology corporation that develops, manufactures, licenses, and supports a wide range of software products for computing devices.',
      :description_de => 'Die Microsoft Corporation ist ein multinationaler Softwarehersteller.'
    }, {
#--- trader joe's      
      :kind => :company,
      :site_name => 'traderjoes',
      :site_url => 'http://www.traderjoes.com',
      :name => 'Trader Joe\'s',
      :name_de => nil,
      :image => File.new("#{RAILS_ROOT}/public/images/logos/organizations/traderjoes.jpg"),
      :tagline => nil,
      :tax_code => nil,
      :country_code => 'US',
      :address_attributes => {
        :street => '117 Kendrick Street',
        :city => 'Needham',
        :postal_code => '02494',
        :province_code => 'MA',
        :country_code => 'US'
      },
      :description => 'Trader Joe\'s is a privately held chain of specialty grocery stores headquartered in Monrovia, California.',
      :description_de => nil
    }, {
#--- volkswagen
      :kind => :company,
      :site_name => 'volkswagen',
      :site_url => 'http://www.volkswagen.com',
      :name => 'Volkswagen',
      :name_de => nil,
      :image => File.new("#{RAILS_ROOT}/public/images/logos/organizations/volkswagen.jpg"),
      :tagline => 'Das Auto',
      :tax_code => nil,
      :country_code => nil,
      :address_attributes => {
        :street => 'Brieffach 1849',
        :city => 'Wolfsburg',
        :postal_code => '38436',
        :country_code => 'DE',
        :phone => '+49-5361-9-0',
        :fax => '+49-5361-9-28282'
      },
      :description => 'Volkswagen Passenger Cars or VW (for short) is a German manufacturer of automobiles, based in Wolfsburg, Germany.',
      :description_de => nil
    }, {
      :kind => :company,
      :site_name => 'volkswagen',
      :site_url => 'http://www.vw.com',
      :name => 'Volkswagen of America Corp.',
      :name_de => nil,
      :image => File.new("#{RAILS_ROOT}/public/images/logos/organizations/volkswagen.jpg"),
      :tagline => 'Das Auto',
      :tax_code => nil,
      :country_code => 'US',
      :address_attributes => {
        :street => '2200 Ferdinand Porsche Dr',
        :city => 'Herndon',
        :postal_code => '20171',
        :province_code => 'VA',
        :country_code => 'US',
        :phone => '+1 703-364-7000'
      },
      :description => 'Volkswagen Passenger Cars or VW (for short) is a German manufacturer of automobiles, based in Wolfsburg, Germany.',
      :description_de => nil
    }, {
      :kind => :company,
      :site_name => 'volkswagen',
      :site_url => 'http://www.volkswagen.de',
      :name => 'Volkswagen AG',
      :name_de => nil,
      :image => File.new("#{RAILS_ROOT}/public/images/logos/organizations/volkswagen.jpg"),
      :tagline => 'Das Auto',
      :tax_code => nil,
      :country_code => 'DE',
      :address_attributes => {
        :street => 'Brieffach 1849',
        :city => 'Wolfsburg',
        :postal_code => '38436',
        :country_code => 'DE',
        :phone => '+49-5361-9-0',
        :fax => '+49-5361-9-28282'
      },
      :description => 'Volkswagen ist eine von mehreren Marken, unter der Fahrzeuge der Volkswagen AG gebaut werden.',
      :description_de => nil
    }, {
#--- aldi
      :kind => :company,
      :site_name => 'aldi',
      :site_url => 'http://www.aldi.com',
      :name => 'Aldi',
      :name_de => nil,
      :image => File.new("#{RAILS_ROOT}/public/images/logos/organizations/aldi.jpg"),
      :tagline => nil,
      :tax_code => nil,
      :country_code => nil,
      :address_attributes => {
        :street => 'Gewerbestraße 10',
        :city => 'Horst',
        :postal_code => '25358',
        :country_code => 'DE'
      },
      :description => 'Aldi, short for "Albrecht Discount", is a discount supermarket chain based in Germany. The chain is made up of two separate groups, Aldi Nord and Aldi Süd, which operate independently from each other within specific market boundaries.',
      :description_de => 'Aldi ist der Kurzname der beiden weltweit operierenden deutschen Handelsunternehmen Aldi Nord und Aldi Süd. Der Firmenname Aldi ist eine Abkürzung und steht für Albrecht-Discount.'
    }, {
#--- henkel
      :kind => :company,
      :site_name => 'henkel',
      :site_url => 'http://www.henkel.com',
      :name => 'Henkel AG',
      :name_de => nil,
      :image => File.new("#{RAILS_ROOT}/public/images/logos/organizations/henkel.jpg"),
      :tagline => nil,
      :tax_code => 'DE119429301',
      :country_code => nil,
      :address_attributes => {
        :city => 'Düsseldorf',
        :postal_code => '40191',
        :country_code => 'DE'
      },
      :description => 'The company operates in three business areas: Home Care (with household cleaning products such as laundry detergent and dishwashing liquid), Personal Care (with beauty and oral care products such as shampoo, toothpaste, hair colorants and shower gel), and Adhesives, Sealants & Surface Treatment for consumer and industrial purposes.',
      :description_de => 'Der Henkel-Konzern ist ein börsennotierter Chemiekonzern mit Hauptsitz in Düsseldorf-Holthausen, das auf drei strategischen Geschäftsfeldern aktiv ist: „Wasch- und Reinigungsmittel“, „Kosmetik und Körperpflege“ sowie „Klebstoffe, Dichtstoffe und Oberflächentechnik“.'
    }, {
#--- persil ww
      :kind => :company,
      :site_name => 'persil',
      :site_url => 'http://www.persil.com',
      :name => 'Persil',
      :name_de => nil,
      :image => File.new("#{RAILS_ROOT}/public/images/logos/organizations/persil.jpg"),
      :tagline => nil,
      :tax_code => nil,
      :country_code => nil,
      :address_attributes => {
        :street => 'Springfield Drive',
        :city => 'Leatherhead',
        :postal_code => 'KT22 7GR',
        :province_code => 'Surrey',
        :country_code => 'UK',
        :phone => '+44 800 776644'
      },
      :description => 'Persil is a brand of laundry detergent manufactured and marketed by both Henkel in some countries and by Unilever in the UK.',
      :description_de => 'Persil ist eine Waschmittelmarke, die von Henkel in vielen Ländern und Unilever in Grossbritannien vermarktet wird.'
    }, {
#--- persil germany
      :kind => :company,
      :site_name => 'persil',
      :site_url => 'http://www.persil.de',
      :name => 'Persil',
      :name_de => nil,
      :image => File.new("#{RAILS_ROOT}/public/images/logos/organizations/persil_henkel.jpg"),
      :tagline => 'Da weiss man, was man hat.',
      :tax_code => nil,
      :country_code => 'DE',
      :address_attributes => {
        :city => 'Düsseldorf',
        :postal_code => '40191',
        :country_code => 'DE',
        :phone => '+49 (800) 1 11 22 90'
      },
      :description => 'Persil is a brand of laundry detergent manufactured and marketed by both Henkel in some countries and by Unilever in the UK.',
      :description_de => 'Persil ist eine Waschmittelmarke, die von Henkel in vielen Ländern und Unilever in Grossbritannien vermarktet wird.'
    }, {
#--- persil great britain
      :kind => :company,
      :site_name => 'persil',
      :site_url => 'http://www.persil.co.uk',
      :name => 'Persil',
      :name_de => nil,
      :image => File.new("#{RAILS_ROOT}/public/images/logos/organizations/persil_unilever.jpg"),
      :tagline => 'Every child has the right to get dirty.',
      :tax_code => nil,
      :country_code => 'UK',
      :address_attributes => {
        :street => 'Springfield Drive',
        :city => 'Leatherhead',
        :postal_code => 'KT22 7GR',
        :province_code => 'Surrey',
        :country_code => 'UK',
        :phone => '+44 800 776644'
      },
      :description => 'Persil is a brand of laundry detergent manufactured and marketed by both Henkel in some countries and by Unilever in the UK.',
      :description_de => nil
    }, {
#--- internal revenue service
      :kind => :agency,
      :site_name => 'irs',
      :site_url => 'http://www.irs.gov/',
      :name => 'Internal Revenue Service',
      :image => File.new("#{RAILS_ROOT}/public/images/logos/organizations/irs.jpg"),
      :tagline => nil,
      :tax_code => nil,
      :country_code => 'US',
      :address_attributes => {
        :city => 'Los Angeles',
        :postal_code => '90060',
        :country_code => 'US',
        :province_code => 'CA'
      },
      :description => 'United States Department of the Treasury. The IRS is the US government agency responsible for tax collection and tax law enforcement.',
      :description_de => nil
    }, {
#--- arbeitsagentur
      :kind => :agency,
      :site_name => 'arbeitsagentur',
      :site_url => 'http://www.arbeitsagentur.de',
      :name => 'Arbeitsagenturen',
      :image => File.new("#{RAILS_ROOT}/public/images/logos/organizations/arbeitsagentur.jpg"),
      :tagline => 'Bundesagentur für Arbeit',
      :tax_code => 'DE811458858',
      :country_code => 'DE',
      :address_attributes => {
        :street => 'Regensburger Straße 104',
        :city => 'Nürnberg',
        :postal_code => '90478',
        :country_code => 'DE',
        :phone => '+49 (911) 179-0',
        :fax => '+49 (911) 179-2123'
      },
      :description => 'Agentur für Arbeitsuchende und Arbeitgeber in Deutschland.',
      :description_de => nil
    }]

    PRODUCTS = [{
#--- google search
      :kind => :service,
      :organization => 'google',
      :name => "Google Web Search",
      :site_url => 'http://www.google.com',
      :description => "Search over 8 billion web pages.",
      :description_de => "Suche über 8 milliarden Internet-Seiten.",
      :image => File.new("#{RAILS_ROOT}/public/images/logos/products/google_web_search.jpg"),
      :language_code => nil,
      :country_code => nil,
      :unit => 'piece',
      :pieces => 1,
      :internal => false
    }, {
#--- google chrome
      :kind => :product,
      :organization => 'google',
      :name => "Google Chrome",
      :site_url => 'http://www.google.com/chrome',
      :description => "A browser built for speed, stability and security.",
      :description_de => "Ein schneller, stabiler und sicherer Internet-Browser.",
      :image => File.new("#{RAILS_ROOT}/public/images/logos/products/google_chrome.jpg"),
      :language_code => nil,
      :country_code => nil,
      :unit => 'piece',
      :pieces => 1,
      :internal => false
    }, {
#--- google docs
      :kind => :service,
      :organization => 'google',
      :name => "Google Docs",
      :site_url => 'http://docs.google.com',
      :description => "Create and share your work online.",
      :description_de => "Ein online Arbeitsplatz zum teilen.",
      :image => File.new("#{RAILS_ROOT}/public/images/logos/products/google_docs.gif"),
      :language_code => nil,
      :country_code => nil,
      :unit => 'piece',
      :pieces => 1,
      :internal => false
    }, {
#--- google earth
      :kind => :product,
      :organization => 'google',
      :name => "Google Earth",
      :site_url => 'http://earth.google.com',
      :description => "Google Earth lets you fly anywhere on Earth to view satellite imagery, maps, terrain, 3D buildings and even explore galaxies in the Sky.",
      :description_de => "Google Earth ermöglicht dir an jeden Platz auf der Erde zu fliegen, Satellitenbilder, Landkarten, und 3D Gebäude einzusehen oder sogar Galaxien zu erkunden.",
      :image => File.new("#{RAILS_ROOT}/public/images/logos/products/google_earth.png"),
      :language_code => nil,
      :country_code => nil,
      :unit => 'piece',
      :pieces => 1,
      :internal => false
    }, {
#--- google picassa
      :kind => :product,
      :organization => 'google',
      :name => "Google Picasa",
      :site_url => 'http://picasa.google.com',
      :description => "Manage your photos in one place, and find photos you forgot you had.",
      :description_de => "Verwalte alle Bilder an einem einzigen Platz und finde Bilder die du schon längst als verloren geglaubt hast.",
      :image => File.new("#{RAILS_ROOT}/public/images/logos/products/google_picasa.gif"),
      :language_code => nil,
      :country_code => nil,
      :unit => 'piece',
      :pieces => 1,
      :internal => false
    }, {
#--- apple iphone
      :kind => :product,
      :organization => 'apple',
      :name => "iPhone 3G",
      :site_url => 'http://www.apple.com/iphone',
      :description => "iPhone 3G combines three products in one - a revolutionary phone, a widescreen iPod, and a breakthrough Internet device.",
      :description_de => "iPhone 3G beinhaltet drei Geräte in einem - ein revultionäres Mobiltelefon, ein Breitbild iPod und ein Internetbrowser.",
      :image => File.new("#{RAILS_ROOT}/public/images/logos/products/apple_iphone.png"),
      :language_code => nil,
      :country_code => nil,
      :unit => 'piece',
      :pieces => 1,
      :internal => false
    }, {
#--- apple ipod touch
      :kind => :product,
      :organization => 'apple',
      :name => "iPod Touch",
      :site_url => 'http://www.apple.com/ipodtouch/',
      :description => "Millions of songs. Thousands of movies. Hundreds of games. The iPod touch has arrived.",
      :description_de => "Millionen von Songs. Tausende von Filmen. Hunderte von Spielen. Der iPod touch ist da.",
      :image => File.new("#{RAILS_ROOT}/public/images/logos/products/apple_ipodtouch.jpg"),
      :language_code => nil,
      :country_code => nil,
      :unit => 'piece',
      :pieces => 1,
      :internal => false
    }, {
#--- apple macbook pro 17"
      :kind => :product,
      :organization => 'apple',
      :name => "MacBook Pro 17-inch",
      :name_de => 'MacBook Pro 17"',
      :site_url => 'http://www.apple.com/macbookpro/',
      :description => "The 17-inch MacBook Pro laptop features a precision aluminum unibody enclosure, powerful NVIDIA graphics and an LED-backlit display.",
      :description_de => "Das 17-Zoll MacBook Pro Laptop ist mit einem Präzisions-Unibody-Aluminiumgehäuse gefertigt und mit einer NVIDIA Grafikkarte sowie einem Bildschirm mit LED-Hintergrundbeleuchtung ausgestattet.",
      :image => File.new("#{RAILS_ROOT}/public/images/logos/products/apple_macbookpro.jpg"),
      :language_code => nil,
      :country_code => nil,
      :unit => 'piece',
      :pieces => 1,
      :internal => false
    }, {
#--- apple macbook pro 15"
      :kind => :product,
      :organization => 'apple',
      :name => "MacBook Pro 15-inch",
      :name_de => 'MacBook Pro 15"',
      :site_url => 'http://www.apple.com/macbookpro/',
      :description => "The 15-inch MacBook Pro laptop features a precision aluminum unibody enclosure, powerful NVIDIA graphics and an LED-backlit display.",
      :description_de => "Das 15-Zoll MacBook Pro Laptop ist mit einem Präzisions-Unibody-Aluminiumgehäuse gefertigt und mit einer NVIDIA Grafikkarte sowie einem Bildschirm mit LED-Hintergrundbeleuchtung ausgestattet.",
      :image => File.new("#{RAILS_ROOT}/public/images/logos/products/apple_macbookpro.jpg"),
      :language_code => nil,
      :country_code => nil,
      :unit => 'piece',
      :pieces => 1,
      :internal => false
    }, {
#--- apple macbook
      :kind => :product,
      :organization => 'apple',
      :name => "MacBook",
      :site_url => 'http://www.apple.com/macbook/',
      :description => "The MacBook laptop features a precision aluminum unibody enclosure, powerful NVIDIA graphics, a 13-inch LED-backlit display.",
      :description_de => "Das MacBook ist mit einem Präzisions-Unibody-Aluminiumgehäuse gefertigt und mit einer NVIDIA Grafikkarte sowie einem 13-Zoll Bildschirm mit LED-Hintergrundbeleuchtung ausgestattet.",
      :image => File.new("#{RAILS_ROOT}/public/images/logos/products/apple_macbook.jpg"),
      :language_code => nil,
      :country_code => nil,
      :unit => 'piece',
      :pieces => 1,
      :internal => false
    }, {
#--- apple macbook white
      :kind => :product,
      :organization => 'apple',
      :name => "MacBook White/Black",
      :name_de => "MacBook Weiss/Schwarz",
      :site_url => 'http://www.apple.com/macbook/',
      :description => "The white/black MacBook features a fast Intel Core 2 Duo processor, large hard drive, and support for up to 2GB of memory.",
      :description => "The schwarze/weisse MacBook hat einen schnellen Intel Core 2 Duo Prozessor, grosse Festplatte und unterstützt bis zu 2GB Hauptspeicher.",
      :image => File.new("#{RAILS_ROOT}/public/images/logos/products/apple_macbook_black_white.jpg"),
      :language_code => nil,
      :country_code => nil,
      :unit => 'piece',
      :pieces => 1,
      :internal => false
    }, {
#--- apple macbook air
      :kind => :product,
      :organization => 'apple',
      :name => "MacBook Air",
      :site_url => 'http://www.apple.com/macbookair/',
      :description => "The MacBook Air appears to be the world’s thinnest notebook, it features a big hard drive, great graphics, and even more power.",
      :description_de => "Das MacBook Air gilt immer noch als das dünnste Notebook der Welt, es ist mit ausgezeichneter Darstellung, grosser Festplatte und enormer Leistung ausgestattet.",
      :image => File.new("#{RAILS_ROOT}/public/images/logos/products/apple_macbook_air.jpg"),
      :language_code => nil,
      :country_code => nil,
      :unit => 'piece',
      :pieces => 1,
      :internal => false
    }, {
#--- apple macpro
      :kind => :product,
      :organization => 'apple',
      :name => "MacPro",
      :site_url => 'http://www.apple.com/macpro/',
      :description => "Meet Mac Pro. It's the fastest Mac workstation.",
      :description_de => "Mac Pro, Tower Workstation System mit starker Leistung.",
      :image => File.new("#{RAILS_ROOT}/public/images/logos/products/apple_macpro.jpg"),
      :language_code => nil,
      :country_code => nil,
      :unit => 'piece',
      :pieces => 1,
      :internal => false
    }, {
#--- apple imac
      :kind => :product,
      :organization => 'apple',
      :name => "iMac",
      :site_url => 'http://www.apple.com/imac/',
      :description => "Discover the ultimate all-in-one iMac. The all-new iMac packs a complete, high- performance computer into a beautifully thin design.",
      :description_de => "Design. Leistung. Und jetzt noch mehr Geschwindigkeit.",
      :image => File.new("#{RAILS_ROOT}/public/images/logos/products/apple_imac.jpg"),
      :language_code => nil,
      :country_code => nil,
      :unit => 'piece',
      :pieces => 1,
      :internal => false
    }, {
#--- microsoft windows vista
      :kind => :product,
      :organization => 'microsoft',
      :name => "Windows Vista",
      :site_url => 'http://www.microsoft.com/windowsvista/',
      :description => "Windows Vista is an operating system developed by Microsoft for use on personal computers, including home and business desktops, laptops, Tablet PCs, and media center PCs.",
      :description_de => "Windows Vista ist das Betriebssystem von Microsoft, welches am 30. Januar 2007 veröffentlicht wurde. Windows Vista wurde als Nachfolger von Windows XP entwickelt.",
      :image => File.new("#{RAILS_ROOT}/public/images/logos/products/microsoft_windows_vista.jpg"),
      :language_code => nil,
      :country_code => nil,
      :unit => 'piece',
      :pieces => 1,
      :internal => false
    }, {
#--- microsoft office
      :kind => :product,
      :organization => 'microsoft',
      :name => "Office",
      :site_url => 'http://www.microsoft.com/office/',
      :description => "Microsoft Office is a set of interrelated desktop applications, servers and services, collectively referred to as an office suite, for the Microsoft Windows and Mac OS X operating systems.",
      :description_de => "Microsoft Office ist das Office-Paket des US-amerikanischen Unternehmens Microsoft für die Betriebssysteme Microsoft Windows und Mac OS. Für unterschiedliche Aufgabenstellungen werden verschiedene Suiten angeboten, die sich in den enthaltenen Komponenten, dem Preis und der Lizenzierung unterscheiden.",
      :image => File.new("#{RAILS_ROOT}/public/images/logos/products/microsoft_office.jpg"),
      :language_code => nil,
      :country_code => nil,
      :unit => 'piece',
      :pieces => 1,
      :internal => false
    }, {
#--- volkswagen golf
      :kind => :product,
      :organization => 'volkswagen',
      :name => "Golf",
      :site_url => 'http://www.vw.com/golf/',
      :description => "The Volkswagen Golf is a compact car and small family car manufactured by Volkswagen.",
      :description_de => "Der Volkswagen Golf gilt als einer der weltweit erfolgreichsten kompakten Mittelklasse-Wagen von Volkswagen.",
      :image => File.new("#{RAILS_ROOT}/public/images/logos/products/volkswagen_golf5.jpg"),
      :language_code => nil,
      :country_code => nil,
      :unit => 'piece',
      :pieces => 1,
      :internal => false
    }, {
#--- persil english deutschland
      :kind => :product,
      :organization => 'persil',
      :name => "Persil Powder",
      :site_url => 'http://www.persil.com/',
      :description => "Washing powder detergent with anti-greying formula and active stain dissolver.",
      :image => File.new("#{RAILS_ROOT}/public/images/logos/products/henkel_persil.jpg"),
      :language_code => 'en',
      :country_code => 'DE',
      :unit => 'piece',
      :pieces => 1,
      :internal => false
    }, {
#--- persil deutsch deutschland
      :kind => :product,
      :organization => 'persil',
      :name => "Persil Universal-Pulver",
      :site_url => 'http://www.persil.de/',
      :description => "Sie reinigen kraftvoll und absolut zuverlässig bei allen Temperaturen und pflegen dabei Ihre Wäsche",
      :image => File.new("#{RAILS_ROOT}/public/images/logos/products/henkel_persil.jpg"),
      :language_code => 'de',
      :country_code => 'DE',
      :unit => 'piece',
      :pieces => 1,
      :internal => false
    }, {
#--- persil english UK
      :kind => :product,
      :organization => 'persil',
      :name => "Colour Care Powder",
      :site_url => 'http://persil.com/productcolourcare.aspx',
      :description => "With its great cleaning power combined with specially formulated colour protectors, Persil Colour Care really ensures the grime comes out – while the colour stays in.",
      :image => File.new("#{RAILS_ROOT}/public/images/logos/products/persil_colour_care_powder.jpg"),
      :language_code => 'en',
      :country_code => 'UK',
      :unit => 'piece',
      :pieces => 1,
      :internal => false
    }]

    desc "create tiers data"
    task :tiers => :environment do 
      puts 'importing tiers...'

      ORGANIZATIONS.reject {|o| o[:site_name] == 'luleka'}.each do |attributes|
        attributes.merge!(:parent_id => Organization.find_root_by_permalink_and_active(attributes[:site_name]))
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

    desc "create topics data"
    task :topics => :environment do 
      puts 'importing topics...'
      
      PRODUCTS.each do |attributes|
        type = attributes.delete(:kind)
        tier = attributes.delete(:organization)
        product = Topic.new(attributes.merge(:type => type))
        
        if organization = Tier.find_by_permalink_and_region_and_active(
          site_name = tier,
          attributes[:country_code]
        )
          product.attributes = attributes.merge(:tier => organization)
          if product.save
            product.register!
            product.activate!
            puts "'#{product.name}' added to '#{organization.name}'."
          else
            puts "'#{product.name}' error #{product.errors.full_messages.join(', ')}."
          end
        else
          puts "'#{site_name}' tier not found."
        end
      end
      puts 'done.'
    end

  end
  
  namespace :purge do

    desc "purges tiers data"
    task :tiers => :environment do 
      puts 'purging tiers...'
      
      ORGANIZATIONS.reject {|o| o[:site_name] == 'luleka'}.each do |attributes|
        if found = Tier.find_by_permalink_and_region_and_active(attributes[:site_name], attributes[:country_code])
          found.destroy
          puts "'#{found.name}' destroyed."
        end
      end
      
      puts 'done.'
    end

    desc "purges topics data"
    task :topics => :environment do 
      puts 'purging topics...'
      PRODUCTS.each do |attributes|
        if found = Topic.find_by_permalink_and_region_and_active(
          attributes[:name].parameterize.to_s, attributes[:country_code]
        )
          found.destroy
          puts "'#{found.name}' destroyed."
        end
      end
      puts 'done.'
    end

  end
  
end