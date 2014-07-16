# Extends Backend Database to deal with escaped key values
::Translation.class_eval do 
  
  #--- callbacks
  after_destroy :sweep_cache
  
  #--- class methods
  class << self
  
    # returns "Foo. And Bar." for value 'foo."Foo. And Bar."'
    def unescape(key)
      I18n.unescape_translation_key_without_scope(key)
    end
    
  end

  def unescape(key)
    self.class.unescape(key)
  end

  # Returns unescaped default key value correctly, and going through the fallback chain
  def default_locale_value(rescue_value='No default locale value')
    fallback_codes = self.fallback_locale_codes 
    unless fallback_codes.empty?
      translations = ::Translation.find(:all, 
        :include => :locale,
          :order => "#{fallback_codes.reverse.map {|fc| "field(locales.code, '#{fc}')"}.join(",")}",
            :conditions => ["translations.key = ? AND translations.pluralization_index = ? AND locales.code IN (?)", 
              self.key, self.pluralization_index, fallback_codes])

      # return the first match
      translations.each do |translation|
        return self.unescape(translation.value) if translation.value
      end
    end
    # default value
    self.unescape(rescue_value)
  end
  
  # create cache key
  # override from i18n_backend_database to receive locale codes as string
  def self.ck(locale, key, hash=true)
    key = self.hk(key) if hash
    "#{locale.is_a?(::Locale) ? locale.code : locale.to_s}:#{key}"
  end
  
  protected
    
  def generate_hash_key
    self.raw_key = key.to_s
    self.key = ::Translation.hk(key)
  end

  # override from i18n backend database to select the I18n global cache store
  # Note: we better flush the store for all fallback languages
  def update_cache
    if I18n.cache_store && !!changes.symbolize_keys[:value]
      # delete fallback locale translations as they may be affected
      # e.g. if a fallback translation was empty and cached, but now 
      # exists a translation due to this update, we want to make sure
      # that the cache is removed.
      self.fallback_locale_codes.each do |code|
        I18n.cache_store.delete(::Translation.ck(code, self.key, false))
      end

      # re-write cache for this translation
      I18n.cache_store.write(::Translation.ck(self.locale, self.key, false), self.value)
    end
  end

  # removes translation from cache
  def sweep_cache
    I18n.cache_store.delete(::Translation.ck(self.locale, self.key, false)) if I18n.cache_store
  end

  # returns a list of fallback locale codes, e.g. for :"en-ES" -> [:"es", :"en", :"en-US"]
  def fallback_locale_codes
    fallback_codes = I18n.fallbacks[self.locale.code].map(&:to_sym).reject {|l| :root == l || self.locale.code.to_sym == l}.compact.map(&:to_s)
    fallback_codes << Locale.default_locale.code if Locale.default_locale
    fallback_codes = fallback_codes.uniq.compact
  end  
end
