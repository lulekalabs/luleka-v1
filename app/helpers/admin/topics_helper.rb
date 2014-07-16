module Admin::TopicsHelper

  def image_url_column(record)
    if record.image.file?
      image_tag(record.image.url(:thumb), {:size => '35x35'})
    else
      '[No Image]'
    end
  end
  
  def image_form_column(record, name)
    html = ''
    if record.image.file?
      html << image_tag(record.image.url(:thumb), {:size => '35x35'})
      html << "<br/>"
    end
    html << file_field(:record, :image)
    html
  end
  
  def country_code_form_column(record, name)
    select(:record, :country_code, collect_countries_for_select(false, "Worldwide".t))
  end

  def language_code_form_column(record, name)
    select(:record, :language_code, collect_supported_languages_for_select("Multi-language"))
  end

end
