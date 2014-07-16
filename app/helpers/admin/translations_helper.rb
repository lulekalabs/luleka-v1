module Admin::TranslationsHelper
  
  def unescape_raw_key(key)
    if key
      key = I18n.translation_key_escaped?(key) ? I18n.unescape_translation_key_without_scope(key) : key
      h(key).gsub(/^\s|\s$/, '&nbsp;')
    else
      '[empty]'
    end
  end
  
  def unescape_raw_key_namespace(key)
    I18n.unescape_translation_key(key)[0] unless key.blank?
  end
  
  # returns a human readable locale name, e.g. "English" or "English - United Kingdom"
  def human_locale_name(locale)
    result = []
    result << I18n.t(I18n.locale_language(locale), :scope => 'languages')
    unless I18n.locale_country(locale).blank?
      result << I18n.t(I18n.locale_country(locale), :scope => 'countries')
    end
    result = result.join(" - ")
    result
  end
  
end
