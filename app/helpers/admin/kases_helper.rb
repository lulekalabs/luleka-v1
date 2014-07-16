module Admin::KasesHelper

  def avatar_url_column(record)
    if record.person && record.person.avatar.file?
      image_tag(record.person.avatar.url(:thumb), {:size => '35x35'})
    else
      '[No Avatar]'
    end
  end
  
  def offer_type_id_form_column(record, name)
    select(:record, :offer_type_id, OfferType.find(:all).map {|m| [m.name, m.id]})
  end

  def offer_audience_type_id_form_column(record, name)
    select(:record, :offer_audience_type_id, AudienceType.find(:all).map {|m| [m.name, m.id]})
  end
  
  def discussion_type_id_form_column(record, name)
    select(:record, :discussion_type_id, DiscussionType.find(:all).map {|m| [m.name, m.id]})
  end

  def language_code_form_column(record, name)
    select(:record, :language_code, collect_supported_languages_for_select(false))
  end

  def severity_id_form_column(record, name)
    select(:record, :severity, collect_for_severity_feeling_select)
  end

  def description_form_column(record, name)
    text_area(:record, :description, {:size => "80x10", :class => "ff", :style => "height:300px"})
  end

end
