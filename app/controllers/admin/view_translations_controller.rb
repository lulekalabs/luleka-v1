# Subclass of translations controller to handle globalize view translations
class Admin::ViewTranslationsController < Admin::TranslationsController
  cache_sweeper :translations_sweeper

  TRANSLATIONS_PER_PAGE = 100
  
  #--- filters
  protect_from_forgery :except => [:update]
  
  #--- actions
  
  def index
    conditions = if params[:q]
      [["(translations.raw_key LIKE ? OR translations.key LIKE ? OR translations.value LIKE ?)", 
        "%#{params[:q]}%", "%#{params[:q]}%", "%#{params[:q]}%"]]
    else
      []
    end
      
    case params[:options]
    when /untranslated/ 
      conditions << ["translations.locale_id IN (?) AND translations.value IS NULL", @locale.id]
      @translations = Translation.find(:all, 
        :conditions => conditions.compact.map {|c| Translation.send(:sanitize_sql, c)}.join(" AND "),
          :order => "translations.raw_key, translations.pluralization_index", 
            :group => "translations.key").paginate(:page => params[:page] || 1, :per_page => TRANSLATIONS_PER_PAGE)
      @translated_count = Translation.translated.count(:conditions => ["translations.locale_id IN (?)", @locales.map(&:id)])
      @untranslated_count = @translations.size
      @translations_count = @translated_count + @untranslated_count
    when /translated/
      conditions << ["translations.locale_id IN (?)", @locales.map(&:id)]
      @translations = Translation.translated.find(:all, 
        :conditions => conditions.compact.map {|c| Translation.send(:sanitize_sql, c)}.join(" AND "), 
          :order => "raw_key, locale_id = #{@locale.id}, pluralization_index").paginate(:page => params[:page] || 1, :per_page => TRANSLATIONS_PER_PAGE)
      @translated_count = @translations.size
      @untranslated_count = Translation.untranslated.count(:conditions => ["translations.locale_id IN (?)", @locales.map(&:id)])
      @translations_count = @translated_count + @untranslated_count
    else
      conditions << ["translations.locale_id IN (?)", @locales.map(&:id)]
      @translations = Translation.find(:all, 
        :conditions => conditions.compact.map {|c| Translation.send(:sanitize_sql, c)}.join(" AND "),
          :order => "raw_key, locale_id = #{@locale.id}, pluralization_index").paginate(:page => params[:page] || 1, :per_page => TRANSLATIONS_PER_PAGE)
      @translated_count = Translation.translated.count(:conditions => ["translations.locale_id IN (?)", @locales.map(&:id)])
      @untranslated_count = Translation.untranslated.count(:conditions => ["translations.locale_id IN (?)", @locales.map(&:id)])
      @translations_count = @translated_count + @untranslated_count
    end
    @page_title = "View Translations for #{Utility.locale_in_words(@locale.code)}"
  end

  # renders text into in place editor
  def update
    key = params[:key]
    value = params[:value]
    code = params[:code]
    translation_locale = params[:translation_locale]
    namespace = params[:namespace].blank? ? nil : params[:namespace]
    pluralization_index = params[:pluralization_index].to_i

    translations = Translation.find_all_by_key(params[:key], :include => :locale,
      :conditions => ["locales.code IN (?)", [code, translation_locale].compact.uniq])

    # update all existing translations
    translations.each do |translation|
      if translation.locale.code ==  translation_locale || (translation.locale.code == code && translation.value.nil?)
        translation.update_attributes({
          :value => value,
          :pluralization_index => pluralization_index
        })
      end
    end
    
    # duplicate translation for sublocales, e.g. :"de-DE" translation is also a :"de" translation, but
    # not vise versa
    # is code sublocale of translation code and is it not part of the translations found, then we need to create a row
    if code.to_s.length == 2 && translation_locale.to_s.length > 2 &&
      I18n.locale_language(code) == I18n.locale_language(translation_locale) &&
        !translations.empty? && !translations.any? {|t| t.locale.code == code}
      
      if locale = Locale.find_by_code(code)
        translation = Translation.create(:key => translations.first.raw_key, :value => translations.first.value,
          :pluralization_index => translations.first.pluralization_index,
            :locale => locale) unless Translation.translated.find(:first, :conditions => ["translations.key = ? AND translations.locale_id = ?", translations.first.key, locale.id])
        translations << translation
      end
    end

    render :text => "#{value}"
  end
  
  # locates the translation key in the ruby source
  def locate
    if (id = params[:id]) && (key = params[:key])
      @translation = Translation.find_by_id(id)
      raw_key = I18n.translation_key_escaped?(@translation.raw_key) ? I18n.unescape_translation_key_without_scope(@translation.raw_key) : @translation.raw_key
      grep = "grep -n -R --exclude=*.svn* '#{raw_key}' #{RAILS_ROOT}/app"
      source = `#{grep}`
      render :update do |page|
        unless source.blank?
          source.gsub!(/\n/, "<br/>")
          source = "<div class=\"source\">#{h(source)}</div>"
        else
          source = "<div class=\"nosource\">No sources found.</div>"
        end
        page.insert_html :bottom, dom_id(@translation, :key), source
      end
    end
  end
  
  # removes a translation and all of its pluralizations
  def destroy
    result = false
    if (id = params[:id]) && (key = params[:key])
      @translation = Translation.find_by_id(id)

      if params[:retire] =~ /^(1|true)/
        # retire all translations with key 
        Translation.find_all_by_key(key).each do |related|
          result = related.destroy
        end
      else
        # only delete one translation
        result = @translation.destroy if @translation
      end
      if result
        render :update do |page|
          page.replace dom_id(@translation), ''
        end
      else
        render :nothing => true
      end
    end
  end
  
  protected
  
  def decontaminate(string)
    string.gsub(/&nbsp;/, ' ')
  end
  
  def prepend_nbsp(string)
    string.gsub(/^\s|\s$/, '&nbsp;')
  end
  
end
