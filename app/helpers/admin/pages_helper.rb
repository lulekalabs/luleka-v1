module Admin::PagesHelper
  def xcontent_form_column(record, name)
    text_area :record, :content, {:size => '80x15', :style => 'font-family: courier; height: 300px;'}
  end

  def title_form_column(record, name)
    translated_text_field(record, name, :title)
  end

  def permalink_form_column(record, name)
    translated_text_field(record, name, :permalink)
  end

  def content_form_column(record, name)
    translated_text_area(record, name, :content, {:size => '80x15', :style => 'font-family: courier; height: 300px;'})
  end
  
  protected 
  
  def translated_text_field(record, name, column_name, options={})
    html = ""
    if record.translateable?(column_name)
      (Utility.active_language_codes - ["en"]).insert(0, "en").each do |code|
        html += text_field(:record, record.class.translated_attribute_name(column_name, code),
          options.merge({:value => record.send(record.class.translated_attribute_name(column_name, code)), 
            :class => "text-input #{column_name}", :id => "#{column_name}-#{code}", 
              :style => "#{options[:style]};display:#{code.to_sym == I18n.locale_language ? '' : 'none'};"}))
      end
      # tab links
      html += "<div class=\"lantabbar\">"
      (Utility.active_language_codes - ["en"]).insert(0, "en").each do |code|
        html += link_to_function(I18n.t("languages.#{code}"), 
          "this.up().childElements().each(function(e) { e.removeClassName('active'); }); this.className = 'lantab active';" + 
            "$$('input.#{column_name}').each(function(e) { e.hide() }); $('#{"#{column_name}-#{code}"}').show();", 
              {:class => "lantab #{code.to_sym == I18n.locale_language ? 'active' : ''}", :id => "#{column_name}-link-#{code}"})
      end
      html += "</div>"
    end
    html
  end

  def translated_text_area(record, name, column_name, options={})
    html = ""
    if record.translateable?(column_name)
      (Utility.active_language_codes - ["en"]).insert(0, "en").each do |code|
        html += text_area(:record, record.class.translated_attribute_name(column_name, code),
          options.merge({:value => record.send(record.class.translated_attribute_name(column_name, code)), 
            :class => "text-input #{column_name}", :id => "#{column_name}-#{code}", 
              :style => "#{options[:style]};display:#{code.to_sym == I18n.locale_language ? '' : 'none'};"}))
      end
      # tab links
      html += "<div class=\"lantabbar\">"
      (Utility.active_language_codes - ["en"]).insert(0, "en").each do |code|
        html += link_to_function(I18n.t("languages.#{code}"), 
          "this.up().childElements().each(function(e) { e.removeClassName('active'); }); this.className = 'lantab active';" + 
            "$$('textarea.#{column_name}').each(function(e) { e.hide() }); $('#{"#{column_name}-#{code}"}').show();", 
              {:class => "lantab #{code.to_sym == I18n.locale_language ? 'active' : ''}", :id => "#{column_name}-link-#{code}"})
      end
      html += "</div>"
    end
    html
  end
  
end
