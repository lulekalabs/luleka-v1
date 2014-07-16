module Admin::PeopleHelper

  def avatar_url_column(record)
    if record.avatar.file?
      image_tag(record.avatar.url(:thumb), {:size => '35x35'})
    else
      '[No Avatar]'
    end
  end
  
  def avatar_form_column(record, name)
    html = ''
    if record.avatar.file?
      html << image_tag(record.avatar.url(:thumb), {:size => '35x35'})
      html << "<br/>"
    end
    html << file_field(:record, :avatar)
    html
  end

end
