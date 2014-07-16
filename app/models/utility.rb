# application class holding all application relevant metadata
module Utility
  #--- constants & accessors
  mattr_accessor :site_name
  mattr_accessor :site_domain
  mattr_accessor :site_url
  mattr_writer :pre_launch
  @@pre_launch = false
  
  # cache
  @@models_to_translate_cache = nil
  
  # files
  VALID_IMAGE_FILE_EXTENSIONS = %w(gif png jpg jpeg)

  # encodings for PDF generation in to_pdf
  LANGUAGE_TO_CHARSET_ENCODING = {
    'de' => 'iso8859-1', # 'latin1',
    'en' => 'iso8859-1', # 'latin1',
    'es' => 'iso8859-1', # 'latin1',
    'jp' => 'SHIFT-JIS'
  }

  COUNTRY_TO_CURRENCY_MAPPING = {
    'EUR' => %w(DE ES FR IR IT AU IT BE NL FI LU PT GR SI CY MT SK),
    'USD' => %w(US AR CL MX),
    'GBP' => %w(UK)
  }

  @@file_extensions_to_content_types = {
    'jpg'  => ['image/jpeg', 'image/pjpeg'],
    'jpeg' => ['image/jpeg', 'image/pjpeg'],
    'bmp'  => ['image/bmp'],
    'png'  => ['image/png', 'image/x-png'],
    'gif'  => ['image/gif']
  }

  @@uniq_file_extname = [
    {'gif'    => ['gif']},
    {'jpg'    => ['jpeg', 'jpg']},
    {'mov'    => ['mov', 'wmv', 'avi']},
    {'mp3'    => ['mp3', 'wma', 'wav']},
    {'pdf'    => ['pdf', 'ps']},
    {'png'    => ['png']},
    {'ppt'    => ['ppt']},
    {'txt'    => ['txt']},
    {'doc'    => ['doc', 'rtf']},
    {'xls'    => ['xls', 'xlxs', 'csv', 'wk3', 'wk4', 'xlw', 'xla']},
    {'zip'    => ['zip', 'jar']},
  ]
  
  #--- class methods
  
  class << self

    def pre_launch?
      !!@@pre_launch
    end

    # getter site_name
    def site_name
      @@site_name || I18n.t(:name, :scope => "service")
    end
    
    # getter site_domain
    def site_domain
      @@site_domain || I18n.t(:domain, :scope => "service")
    end

    # getter site_url
    def site_url
      @@site_url || I18n.t(:url, :scope => "service")
    end
    
    #--- country
    
    # returns an array of active country codes, e.g. ['DE', 'US']
    def active_country_codes
      Utility.active_locales.map {|a| I18n.locale_country(a)}.map(&:to_s).uniq
    end

    # returns the ISO country code from the given locale or I18n, e.g. 'DE' for Germany
    def country_code(locale=nil)
      I18n.locale_country(locale || I18n.locale).to_s if I18n.locale_country(locale || I18n.locale)
    end
    
    # returns the default country code string
    def default_country_code
      I18n.locale_country(I18n.default_locale).to_s if I18n.locale_country(I18n.default_locale)
    end
    
    #--- language
    
    # returns an array of active language codes, e.g. ['en', 'de']
    def active_language_codes
      Utility.active_locales.map {|a| I18n.locale_language(a)}.map(&:to_s).uniq
    end

    # returns the current ISO language code
    def language_code(locale=nil)
      I18n.locale_language(locale || I18n.locale).to_s if I18n.locale_language(locale || I18n.locale)
    end
    
    # returns default language, also base language, code as string, e.g. :en
    def default_language_code
      I18n.locale_language(I18n.default_locale).to_s if I18n.locale_language(I18n.default_locale)
    end
    
    #--- currency
    
    # returns an array of active currency codes, e.g. ['USD', 'EUR']
    def active_currency_codes
      I18n.t("currencies").keys.map(&:to_s)
    end
    
    # returns local's default currency_code, in priotity of
    #
    #   * the given locale
    #   * the curent locale
    #
    # e.g.
    #
    #   currency_code :'de-DE' -> USD
    #   currency_code -> USD
    #
    def currency_code(locale=nil)
      locale ? I18n.backend.translate(locale, "number.currency.code") : I18n.t("number.currency.code")
    end

    #--- taxes
    
    def tax_regexp(country_code = Utility.country_code)
      if country_code
        if !(rxs = I18n.translate(country_code, :scope => 'taxes').map {|key, value| value[:regexp]}.compact).blank?
          rxs = rxs.map {|rx| (rx.is_a?(Regexp) ? rx.source : rx)}
          Regexp.new(rxs.compact.join("|")) unless rxs.compact.empty?
        end
      else
        Regexp.new("")
      end
    end
    
    def tax_example_in_words(country_code = Utility.country_code)
      result = I18n.translate(country_code, :scope => 'taxes').map do |key, value|
        "%{example} for %{tax}".t % {:tax => "#{value[:name]} (#{value[:short_name]})", :example => "#{value[:example]}"}
      end
      result.to_sentence_with_or
    end

    #--- paper

    # returns the paper format for the current locale or the one 
    # specified as parameter, e.g. A4, letter (default)
    def paper_size(locale=nil)
      locale ? I18n.backend.translate(locale, "paper.sizes.standard") : I18n.t("paper.sizes.standard")
    end

    #--- locale

    # returns current locale code as string, e.g. 'en-UK', etc.
    def locale_code(locale=nil)
      locale ? locale.to_s : I18n.locale.to_s
    end

    # true if long (e.g. :"en-US") or short locale (e.g. "us" -> :"en-US")  is supported 
    def supported_locale?(locale)
      result = false
      if locale
        result = Utility.active_locales.map(&:to_s).any? {|e| e.to_s.match(Regexp.new(locale.to_s, :ignore_case))} ||
          Utility.active_locales.map {|l| Utility.long_to_short_locale(l)}.compact.map(&:to_s).any? {|e| e.to_s.match(Regexp.new(locale.to_s, :ignore_case))}
      end
      result
    end
    
    # returns human readable locale code in current language
    #
    # e.g.
    #
    #   I18n.locale = :en
    #   Utility.locale_in_words  -> "English - United States"
    #   Utility.locale_in_words(:de)  -> "German"
    #
    def locale_in_words(locale=I18n.locale)
      result = []
      result << I18n.t(I18n.locale_language(locale), :scope => 'languages') if I18n.locale_language(locale)
      result << I18n.t(I18n.locale_country(locale), :scope => 'countries') if I18n.locale_country(locale)
      result.join(" - ")
    end

    # returns full locale code from incomplete locale entry 
    # depending on active locales
    #
    # e.g.
    #
    #   :en      -> :en-US
    #   :es      -> :es-ES
    #   :us      -> :en-US
    #   :cl      -> :es-CL
    #   :en-US   -> :en-US
    #   nil      -> nil
    #
    def full_locale(locale)
      result = nil
      if supported_locale?(locale)
        result = Utility.active_locales.map(&:to_s).find {|e| e.to_s.match(Regexp.new(locale.to_s, :ignore_case))}
        unless result
          result = Utility.active_locales.map {|l| Utility.long_to_short_locale(l)}.compact.map(&:to_s).find {|e| e.to_s.match(Regexp.new(locale.to_s, :ignore_case))}
        end
        result = result.to_sym if result
      end
      result
    end
    
    #--- request
    
    def request_host_main_domain?(host)
      host =~ /(com)$/i ? true : false
    end
    
    # tries to infer the host domain to a valid locale code, e.g. luleka.de -> :"de-DE"
    def request_host_to_supported_locale(host)
      found_locale = case host.to_s
        when /(eu)$/i then :"en-UK"
        when /(de)$/i then :"de-DE"
        when /(co.uk)$/i then :"en-UK"
        when /(com.ar)$/i then :"es-AR"
        when /(com)$/i then :"en-US"
      end
      result = Utility.active_locales.map(&:to_s).find {|a| a.match(Regexp.new(found_locale.to_s, :ignore_case))} if found_locale
      result.to_sym if result
    end

    # infers locale from request language, e.g. "en-us,en;q=0.5" -> "en-US"
    def request_language_to_supported_locale(request_language)
      if request_language.match(/([a-z]{2}-[a-z]{2})/i)
        matching_locale = $1
        Utility.active_locales.map(&:to_s).find {|a| a.match(Regexp.new(matching_locale, :ignore_case))}
      else
        # infer from the language portion with regexp, e.g. /de|en|es/
        if request_language.match(Regexp.new("(#{Utility.active_language_codes.join("|")})", :ignore_case))
          matching_language = $1
          Utility.active_locales.find {|l| matching_language.downcase == I18n.locale_language(l).to_s}
        end
      end
    end

    #--- image

    # returns an array of content_type for the given file_name
    #
    # e.g. 
    #
    #   Utility.content_type "ginger.png"  ->  ["image/png", "image/x-png"]
    #   Utility.content_type "test.gif"  ->  ['image/gif']
    #
    def content_type(file_name)
      if file_name =~ /\.([^\.]*)$/
        file_extension = $1.downcase
        return @@file_extensions_to_content_types[file_extension]
      end
    end

    # returns all valid content types for image uploads
    # as array of content types
    def image_content_types
      result = [] + [content_type("test.gif")] + [content_type("test.png")] +
        [content_type("test.jpg")] + [content_type("test.jpeg")]
      result.flatten.uniq
    end

    # returns a unque file extension for a file name or extension
    # 
    # e.g.
    #
    #   'wk4'        ->  'xls'
    #   'test.csv'   ->  'xls'
    #   'bogus'      ->  nil
    #
    def uniq_file_extname(ext)
      find = File.extname(ext.to_s).gsub(".", "") rescue nil
      find = ext if find.blank?
      
      @@uniq_file_extname.each do |item|
        item.each do |k, v|
          if v.find {|i| i == find.to_s.downcase}
            return item.to_a.flatten.first
          end
        end
      end
      nil
    end

    #--- admin translation

    # returns the models with model translations
    def models_to_translate
      if @@models_to_translate_cache  
        @@models_to_translate_cache
      else
        @@models_to_translate_cache = []
        Dir.glob(File.join(RAILS_ROOT,'app','models','**','*.rb')).each do |file_name|
          base_name = File.basename(file_name, '.rb')
          excepts = %w(utility query_base inline_authentication_base)
          if !excepts.include?(base_name) && klass = base_name.pluralize.classify.constantize
            if klass.respond_to?(:translated_attribute_names) && klass.base_class == klass
              @@models_to_translate_cache.push(klass)
            end
          end
        end
        @@models_to_translate_cache
      end
    end

    #--- loader helpers
    
    # loads all sub classes of Tier/Topic, Kase, Voucher
    # http://dev.rubyonrails.org/ticket/11269
    def require_sti_dependencies
      %w(question problem praise idea organization group product service employment partner_membership_voucher request invitation contact_invitation claiming).each do |name|
        require_dependency "#{RAILS_ROOT}/app/models/#{name}.rb"
      end
    end

    # returns all top level active locales defined using fallbacks, e.g. [:"de-DE", :"en-US"]
    def active_locales
      I18n.fallbacks.reject {|k,v| k.to_s.length < 4}.keys
    rescue Exception => ex
      RAILS_DEFAULT_LOGGER.error  "** Error #{ex.message} I18n.fallbacks may not be setup correctly"
      []
    end

    # used in environment to set default currency to "USD"
    # and 
    def setup_default_currency_and_bank_rates
      Money.default_currency = 'USD'
      ExchangeRate.setup_money_bank
    rescue Exception => ex
      RAILS_DEFAULT_LOGGER.error  "** Error #{ex.message}: Exchange rates were not setup correctly"
    end

    #--- misc
    
    # used in ApplicationController to turn of session handler if check is true for bot
    def robot?(user_agent)
      user_agent =~ /(Baidu|bot|Google|SiteUptime|Slurp|WordPress|ZIBB|ZyBorg)/i
    end

    # caches all active people in the network
    def people_count
      @@people_count_cache ||= Person.count(Person.find_options_for_active)
    end

    # caches all visible cases in the network
    def kases_count
      @@kases_count_cache ||= Kase.count(Kase.find_options_for_visible)
    end
    
    # dito for responses
    def responses_count
      @@responses_count_cache ||= Response.count(Response.find_options_for_visible)
    end

    # dito for reputation
    def reputation_count
      46795
    end
    
    # e.g. "de" -> "de-DE"
    # short_to_long_locale
    def short_to_long_locale(short_code)
      case short_code.to_s
        when /(uk)$/i then :"en-UK"  # english - United Kingdom
        when /(en)$/i then :"en-US"  # english - United Kingdom
        when /(us)$/i then :"en-US"  # english - United States
        when /(de)$/i then :"de-DE"  # german - Germany
        when /(es)$/i then :"es-ES"  # spanish - Spain
        when /(fr)$/i then :"fr-FR"  # french - France
        when /(ar)$/i then :"es-AR"  # spanish - Argentina
        when /(mx)$/i then :"es-MX"  # spanish - Mexico
        when /(cl)$/i then :"es-CL"  # spanish - Chile
        when /(pt)$/i then :"pt-PT"  # portuguese - Portugal
        when /(br)$/i then :"pt-BR"  # portuguese - Brasil
        when /(ch)$/i then :"de-CH"  # german - Switzerland
      end
    end

    # e.g. "de-DE" -> "de"
    # long_to_short_locale
    def long_to_short_locale(long_code)
      case long_code.to_s
        when /(en-UK)$/i then :uk  # english - United Kingdom
        when /(en-US)$/i then :us  # english - United States
        when /(de-DE)$/i then :de  # german - Germany
        when /(es-ES)$/i then :es  # spanish - Spain
        when /(fr-FR)$/i then :fr  # french - France
        when /(es-AR)$/i then :ar  # spanish - Argentina
        when /(es-MX)$/i then :mx  # spanish - Mexico
        when /(es-CL)$/i then :cl  # spanish - Chile
        when /(pt-PT)$/i then :pt  # portuguese - Portugal
        when /(pt-BR)$/i then :br  # portuguese - Brasil
        when /(de-CH)$/i then :ch  # german - Switzerland
      end
    end

    # e.g. Utility.active_short_locale -> :ar for locale :"es-AR" or nil for no match
    def short_locale(locale=nil)
      long_to_short_locale(locale || I18n.locale)
    end
    
    # returns all active locales in short locale format, e.g. [:de, :us], etc.
    def active_short_locales
      Utility.active_locales.map {|l| Utility.long_to_short_locale(l)}
    end

    # Random hex number e.g. "e8e327cd0e365987734ea35a9ca44b50"
    def generate_random_hex(length=16)
      ActiveSupport::SecureRandom.hex(length)
    end
    
    # UUID, e.g. "589393ef-6add-4b87-ad6c-21aac6902017"
    def generate_random_uuid
      defined?(UUIDTools) ? UUIDTools::UUID.random_create.to_s : UUID.random_create.to_s
    end
    
    # case insensitive alpha-num encoding, e.g. 36^6 = 2,176,782,336 combinations
    # e.g. "uq4kqru1v01p"
    def generate_random_alpha_numeric(length=6)
      Array.new(length){"0123456789abcdefghijklmnopqrstuvwxyz"[rand(35)].chr}.join
    end

    # bit.ly style case sensitive alpha-num encoding, e.g. 62^6 = 56,800,235,584 combinations
    # e.g. "c4pAr0"
    def generate_random_alpha_numeric_case_sensitive(length=6)
      Array.new(length){"0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"[rand(61)].chr}.join
    end

    # returns the english name for language code or if not given current locale language name, 
    #
    # E.g.
    #
    #    Utility.english_language_name("de") -> "German"
    #    Utility.english_language_name -> "English"
    #
    def english_language_name(language_code=I18n.locale_language)
      result = nil
      if language_code
        I18n.switch_locale :"en-US" do
          result = I18n.t("languages.#{language_code}")
        end 
      end
      result
    end
    
    # returns a valid currency for country code, e.g. "US" -> "USD", "DE" -> "EUR"
    def country_to_currency_code(country_code)
      if country_code && select = COUNTRY_TO_CURRENCY_MAPPING.select {|k, v| v.include?("#{country_code}".upcase)}
        select[0] ? select[0].first : "USD"
      else
        'USD'
      end
    end
    
    # get domain from URL os hostname
    def domain_from_host(host)
      host.gsub(/^(?:(?>[a-z0-9-]*\.)+?|)([a-z0-9-]+\.(?>[a-z]*(?>\.[a-z]{2})?))$/i, '\1').strip
    end
    
  end
end
