module Admin::TiersHelper
  
  def image_url_column(record)
    if record.image.file?
      image_tag(record.image.url(:thumb), {:size => '35x35'})
    else
      '[No Image]'
    end
  end

  def name_column(record)
    link_to(h(record.name), tier_url(record), {:popup =>  true}) 
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
    select(:record, :language_code, collect_supported_languages_for_select(true))
  end

  def type_form_column(record, name)
    select(:record, :type, (Tier.self_and_subclasses - [Tier]).map {|m| [m.human_name, m.name]})
  end

  def category_id_form_column(record, name)
    select(:record, :category_id, record.class.find_all_categories.map {|m| [m.name.capitalize, m.id]})
  end

  def description_form_column(record, name)
    text_area(:record, :description, {:value => record.description, :size => "80x10", :class => "ff", :style => "height:150px"})
  end

  def summary_form_column(record, name)
    text_area(:record, :summary, {:value => record.summary, :size => "80x10", :class => "ff", :style => "height:150px"})
  end

  def name_form_column(record, name)
    text_field(:record, :name, {:value => record.name})
  end
    
end
