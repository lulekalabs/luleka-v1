module FlagsHelper
  
  # adds a link called "Inappropriate?" which shows 
  # link_to_remote_redbox(text, {:url => new_flag_path(@kase), :method => :get}.merge(options),
  #  {:class => 'inapropriate'}.merge(html_options))
  def link_to_flag(text, object, options={}, html_options={})
    link_to_remote_facebox(text, new_flag_path(object),
	    {:class => 'inapropriate', :id => flag_link_dom_id(object), :style => "display:none;"}.merge(html_options))
  end

  # link to flag for object
  def link_to_flag_for(object, text="Flag?".t, options={}, html_options={})
    link_to_flag(text, object, options, html_options)
  end

  # used for flag link id in link_to
  def flag_link_dom_id(object)
    dom_id(object, :flag_link)
  end
  
  # returns options for a tag helper for the flag link to appear
  def flag_mouse_over_tag_options(object, options={})
    {:onmouseover => "$('#{flag_link_dom_id(object)}').show();",
      :onmouseout => "$('#{flag_link_dom_id(object)}').hide();"}.merge(options)
  end
  
end