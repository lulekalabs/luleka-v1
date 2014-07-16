#--- default locale and fallbacks
I18n.locale = :"en-US"
I18n.default_locale = :"en-US"
I18n.fallbacks[:"en-US"] = [:"en-US", :en, :root]
#I18n.fallbacks[:"en-UK"] = [:"en-US", :en, :root]
I18n.fallbacks[:"de-DE"] = [:"de-DE", :de, :en, :root]
#I18n.fallbacks[:"de-CH"] = [:"de-DE", :de, :en, :root]
#I18n.fallbacks[:"de-AT"] = [:"de-DE", :de, :en, :root]
I18n.fallbacks[:"es-ES"] = [:"es-ES", :es, :en, :root]
I18n.fallbacks[:"es-AR"] = [:"es-AR", :"es-ES", :es, :en, :root]
#I18n.fallbacks[:"es-MX"] = [:"es-ES", :es, :en, :root]
I18n.fallbacks[:"es-CL"] = [:"es-CL", :"es-ES", :es, :en, :root]

#--- model translations, keep all in model
Globalize::Model::keep_translations_in_model = true

#--- chaining globalize static before i18n_backend_database and adding cache
if RAILS_ENV == "production"
  I18n.cache_store = ActiveSupport::Cache.lookup_store(:mem_cache_store, :namespace => "translations")
  I18n.cache_store.clear
else
  I18n.cache_store = ActiveSupport::Cache.lookup_store(:memory_store)
end
I18n.backend = Globalize::Backend::Chain.new(Globalize::Backend::Static, I18n::Backend::Database)

if "test" == RAILS_ENV
  # load i18n database fixtures
  require 'active_record/fixtures'
  ActiveRecord::Base.establish_connection(RAILS_ENV.to_sym)
  Fixtures.create_fixtures('test/fixtures', 'locales')
  Fixtures.create_fixtures('test/fixtures', 'translations')
  
  I18n.load_path += Dir[File.join(RAILS_ROOT, 'test', 'fixtures', 'locale', '*.{rb,yml}')]
end
