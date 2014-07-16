namespace :data do
  
  namespace :import do

    USERS = [{
      # mariana -> partner
      :login => 'mariana',
      :email => 'mariana@luleka.net',
      :language => 'en',
      :currency => 'USD',
      :time_zone => 'Argentina',
      :birthdate => '1973-05-09',
      :gender => 'f',
      :password => 'probonomariana',
      :password_confirmation => 'probonomariana',
      :verification_code => 'match',
      :verification_code_session => 'match',
      :person_attributes => {
        :status => :partner,
        :academic_title_id => nil,
        :first_name => 'Mariana',
        :middle_name => nil,
        :last_name => 'Saiz',
        :avatar => File.new("#{RAILS_ROOT}/public/images/logos/people/mariana.jpg"),
        :personal_status_id => 2,
        :profile => "Mariana is the community maven of luleka.net",
        :home_page_url => 'www.moola.de',
        :prefers_casual => true,
        :notify_on_newsletter => true,
        :notify_on_promotion => true,
        :notify_on_clarification_request => true,
        :notify_on_clarification_response => true,
        :notify_on_kase_matching => true,
        :notify_on_kase_status => true,
        :notify_on_comment_posted => true,
        :notify_on_comment_received => true,
        :notify_on_response_posted => true,
        :notify_on_response_received => true,
        :notify_on_follower => true,
        :notify_on_following => true,
        #--- addresses
        :personal_address_attributes => {
          :street => '100 Rousseau St.',
          :city => 'San Francisco',
          :postal_code => '94112',
          :province_code => 'CA',
          :country_code => 'US',
          :phone => '+1 (415) 508-5782',
          :mobile => '+1 (415) 508-5783',
          :fax => '+1 (415) 508-5784'
        },
        :business_address_attributes => {
          :street => '101 Rousseau St.',
          :city => 'San Francisco',
          :postal_code => '94112',
          :province_code => 'CA',
          :country_code => 'US',
          :phone => '+1 (415) 308-5782',
          :mobile => '+1 (415) 308-5783',
          :fax => '+1 (415) 308-5784'
        },
        :billing_address_attributes => {
          :first_name => 'Mariana',
          :last_name => 'Saiz',
          :street => '102 Rousseau St.',
          :city => 'San Francisco',
          :postal_code => '94112',
          :province_code => 'CA',
          :country_code => 'US',
          :phone => '+1 (415) 108-5782',
          :mobile => '+1 (415) 108-5783',
          :fax => '+1 (415) 108-5784'
        },
        #--- tags
        :have_expertise => 'community management, economic, statistics',
        :want_expertise => 'partners, cases, companies, products',
        :interest => 'polo, sailing, swimming',
        :university => 'Pontificia Universidad Católica Argentina (UCA), UCA, Ludwig-Maxilian University (LMU), LMU',
        :industry => 'Internet',
        :academic_degree => 'Master of Science',
        :profession => 'Economist',
        :professional_title => 'Community Manager'
      }
    }, {
      # juergen -> partner
      :login => 'juergen',
      :email => 'juergen@luleka.net',
      :language => 'de',
      :currency => 'EUR',
      :time_zone => 'Berlin',
      :birthdate => '1972-02-26',
      :gender => 'm',
      :password => 'probonojuergen',
      :password_confirmation => 'probonojuergen',
      :verification_code => 'match',
      :verification_code_session => 'match',
      :person_attributes => {
        :status => :partner,
        :academic_title_id => nil,
        :first_name => 'Jürgen',
        :middle_name => nil,
        :last_name => 'Feßlmeier',
        :avatar => File.new("#{RAILS_ROOT}/public/images/logos/people/juergen.jpg"),
        :personal_status_id => 1,
        :profile => "Jürgen ist der alles richtet bei luleka.net",
        :home_page_url => 'www.moola.de',
        :prefers_casual => true,
        :notify_on_newsletter => true,
        :notify_on_promotion => true,
        :notify_on_clarification_request => true,
        :notify_on_clarification_response => true,
        :notify_on_kase_matching => true,
        :notify_on_kase_status => true,
        :notify_on_comment_posted => true,
        :notify_on_comment_received => true,
        :notify_on_response_posted => true,
        :notify_on_response_received => true,
        :notify_on_follower => true,
        :notify_on_following => true,
        #--- addresses
        :personal_address_attributes => {
          :street => '100 Rousseau St.',
          :city => 'San Francisco',
          :postal_code => '94112',
          :province_code => 'CA',
          :country_code => 'US',
          :phone => '+1 (415) 508-5782',
          :mobile => '+1 (415) 508-5783',
          :fax => '+1 (415) 508-5784'
        },
        :business_address_attributes => {
          :street => '101 Rousseau St.',
          :city => 'San Francisco',
          :postal_code => '94112',
          :province_code => 'CA',
          :country_code => 'US',
          :phone => '+1 (415) 308-5782',
          :mobile => '+1 (415) 308-5783',
          :fax => '+1 (415) 308-5784'
        },
        :billing_address_attributes => {
          :first_name => 'Jürgen',
          :last_name => 'Feßlmeier',
          :street => '102 Rousseau St.',
          :city => 'San Francisco',
          :postal_code => '94112',
          :province_code => 'CA',
          :country_code => 'US',
          :phone => '+1 (415) 108-5782',
          :mobile => '+1 (415) 108-5783',
          :fax => '+1 (415) 108-5784'
        },
        #--- tags
        :have_expertise => 'Produkt Management, User Interface, Ruby on Rails, RoR, Web 2.0',
        :want_expertise => 'Mitarbeiter, Partner, Fälle, Firmen, Organizationen, Produkte',
        :interest => 'Tennis, Segeln',
        :university => 'Fachhochschule Rosenheim, California University, Lucas Graduate School of Business',
        :industry => 'Internet',
        :academic_degree => 'Diplom-Informatiker, MBA',
        :profession => 'Entwickler, Verkäufer, Produkt Manager, Designer',
        :professional_title => 'Managing Partner'
      }
    }, {
      # ginger -> member
      :login => 'ginger',
      :email => 'ginger@luleka.net',
      :language => 'en',
      :currency => 'USD',
      :time_zone => 'New York',
      :birthdate => '1977-09-21',
      :gender => 'f',
      :password => 'probonoginger',
      :password_confirmation => 'probonoginger',
      :verification_code => 'match',
      :verification_code_session => 'match',
      :person_attributes => {
        :status => :member,
        :academic_title_id => 1,
        :first_name => 'Ginger',
        :middle_name => 'S.',
        :last_name => 'Weichselbaum',
        :avatar => File.new("#{RAILS_ROOT}/public/images/logos/people/ginger.jpg"),
        :personal_status_id => 2,
        :profile => "Ginger is an attorney specializing in community law in New York City.",
        :home_page_url => nil,
        :prefers_casual => false,
        :notify_on_newsletter => true,
        :notify_on_promotion => true,
        :notify_on_clarification_request => true,
        :notify_on_clarification_response => true,
        :notify_on_kase_matching => true,
        :notify_on_kase_status => true,
        :notify_on_comment_posted => true,
        :notify_on_comment_received => true,
        :notify_on_response_posted => true,
        :notify_on_response_received => true,
        :notify_on_follower => true,
        :notify_on_following => true,
        #--- addresses
        # 451 Mercer St, Jersey City, NJ 07302, USA
        :personal_address_attributes => {
          :street => '451 Mercer St',
          :city => 'Jersey City',
          :postal_code => '07302',
          :province_code => 'NJ',
          :country_code => 'US',
          :phone => '+1 (201) 482-9382',
          :mobile => '+1 (201) 953-3834',
          :fax => '+1 (201) 483-2873'
        },
        #--- tags
        :have_expertise => 'community law, labor law',
        :want_expertise => 'tax, taxes, real estate',
        :interest => 'squash, horseback',
        :university => 'Columbia University',
        :industry => 'Law',
        :academic_degree => 'Master of Laws, LL.M.',
        :profession => 'Lawyer',
        :professional_title => 'Partner'
      }
    }, {
      # herbert
      :login => 'herbert',
      :email => 'herbert@luleka.net',
      :language => 'de',
      :currency => 'EUR',
      :time_zone => 'Berlin',
      :birthdate => '1964-08-11',
      :gender => 'm',
      :password => 'probonoherbert',
      :password_confirmation => 'probonoherbert',
      :verification_code => 'match',
      :verification_code_session => 'match',
      :person_attributes => {
        :status => :member,
        :academic_title_id => nil,
        :first_name => 'Herbert',
        :middle_name => nil,
        :last_name => 'Wenke',
        :avatar => File.new("#{RAILS_ROOT}/public/images/logos/people/herbert.jpg"),
        :personal_status_id => 1,
        :profile => "Herbert ist ein Autoexperte, spezialisiert in der Restauration von VW Käfern.",
        :home_page_url => nil,
        :prefers_casual => true,
        :notify_on_newsletter => true,
        :notify_on_promotion => true,
        :notify_on_clarification_request => true,
        :notify_on_clarification_response => true,
        :notify_on_kase_matching => true,
        :notify_on_kase_status => true,
        :notify_on_comment_posted => true,
        :notify_on_comment_received => true,
        :notify_on_response_posted => true,
        :notify_on_response_received => true,
        :notify_on_follower => true,
        :notify_on_following => true,
        #--- addresses
        # Moltkestraße 83, 72762 Reutlingen, Germany
        :personal_address_attributes => {
          :street => 'Moltkestraße 83',
          :city => 'Reutlingen',
          :postal_code => '72762',
          :province_code => 'BW',
          :province => 'Baden-Würtemberg',
          :country_code => 'DE',
          :phone => '+49 (0)7121/342 323 64',
          :mobile => '+49 (0)172/323 523 5',
          :fax => '+49 (0)172/342 323 65'
        },
        #--- tags
        :have_expertise => 'automotoren, käfer, vw käfer, 4-zylinder',
        :want_expertise => 'rechtsfragen, recht, automobilrecht, steuern, versicherungen',
        :interest => 'autofahren, motorrad',
        :university => nil,
        :industry => 'Fahrzeugtechnik',
        :academic_degree => nil,
        :profession => 'Mechaniker',
        :professional_title => 'Meister'
      }
    }]

    desc "create users data"
    task :users => :environment do 

      puts 'importing users...'
      
      save_private_beta = Meta.private_beta?
      Meta.private_beta = false
      USERS.each do |user_attributes|
        unless user = User.find_by_login(user_attributes[:login])
          person_attributes = user_attributes.delete(:person_attributes) || {}
          status = person_attributes.delete(:status)
          personal_address_attributes = person_attributes.delete(:personal_address_attributes) || {}
          business_address_attributes = person_attributes.delete(:business_address_attributes) || {}
          billing_address_attributes = person_attributes.delete(:billing_address_attributes) || {}
          user = User.new(user_attributes)
          user.person.attributes = person_attributes
          # addresses
          user.person.build_personal_address(personal_address_attributes) unless personal_address_attributes.empty?
          user.person.build_business_address(business_address_attributes) unless business_address_attributes.empty?
          user.person.build_billing_address(billing_address_attributes) unless billing_address_attributes.empty?
          # save and register
          if user.save
            user.register!
            user.activate!
            # spoken languages
            user.person.spoken_languages << SpokenLanguage.find_by_code('en')
            user.person.spoken_languages << SpokenLanguage.find_by_code('de')
            user.person.spoken_languages << SpokenLanguage.find_by_code('es')
            # employment
            employment = Employment.create(
              :employee => user.person,
              :employer => Organization.find_by_permalink('luleka').root
            )
            employment.activate!
            user.person.activate!

            # upgrade to partner
            if status == :partner
              user.person.piggy_bank.direct_deposit(Money.new(10000, user.person.default_currency))
              voucher = PartnerMembershipVoucher.create(:consignee => user.person, :expires_at => Time.now.utc + 5.minutes)
              voucher.redeem!
            end
            puts "'#{user.login}' as '#{user.person.name}' created."
          else
            puts "'#{user.login}' error #{user.errors.full_messages.join(', ')}."
          end
        else
          puts "'#{user.login}' already exists."
        end
      end

      Meta.private_beta = save_private_beta
      puts 'done.'
    end
    
  end
  
  namespace :purge do

    desc "purges users data"
    task :users => :environment do 
      puts 'purging users...'

      USERS.each do |user_attributes|
        if user = User.find_by_login(user_attributes[:login])
          user.destroy
          puts "'#{user.login}' destroyed."
        else
          puts "'#{user_attributes[:login]}' not found."
        end
      end
      
      puts 'done.'
    end

  end
  
end