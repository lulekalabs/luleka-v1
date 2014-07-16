namespace :i18n do

  namespace :populate do

    desc 'Populate default locales'
    task :default_locales => :environment do
      active_locales = Utility.active_locales.map(&:to_s).sort.map(&:to_sym)
      active_locales.each do |active_locale|
        puts "* processing active locale #{active_locale}"
        
        fallback_locales = ([active_locale] + I18n.fallbacks[active_locale].reject {|l| l==:root}).uniq
        fallback_locales.each do |fallback_locale|
          I18n.switch_locale fallback_locale do
            language_name = I18n.t(I18n.locale_language(fallback_locale), :scope => 'languages', :default => '(unknown)')
            country_name = I18n.t(I18n.locale_country(fallback_locale), :scope => 'countries', :default => '(unknown)') if I18n.locale_country(fallback_locale)
            code = "#{fallback_locale}"
            name = country_name ? "#{language_name.firstcase} - #{country_name.firstcase}" : "#{language_name.firstcase}"
            if Locale.exists?(:code => code)
              puts "** locale exists #{code}: #{name}"
            else
              Locale.create!({:code => code, :name => name})
              puts "* locale created #{code}: #{name}"
            end
          end
        end
      end
    end

  end

end
