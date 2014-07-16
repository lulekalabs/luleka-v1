module FaceboxHelper

  # link to existing content
  #
  # e.g.
  #
  #   <%= link_to_facebox("Open Facebox", '#anchor') %>
  #   <div id="anchor">this is the content to display</div>
  #   
  #   or
  #
  #   <%= link_to_facebox("Open Facebox", "http://example.com/image.jpg") %>
  #
  def link_to_facebox(name, link, html_options={})
    @uses_facebox = true
    @uses_modal = true
    link_to(name, "#{link}", {:rel => 'facebox'}.merge(html_options))
  end
  
  # adds as remote link to facebox and populates the facebox with 
  # rendered content from remote function
  def link_to_remote_facebox(name, url_options={}, html_options={})
    @uses_facebox = true
    @uses_modal = true
    link_to(name, facebox_url_for(url_options), {:rel => 'facebox'}.merge(html_options))
  end

  # acts similar to the built in rails helper link_to_unless_current
  def link_to_remote_facebox_unless_current(name, url_options = {}, html_options = {})
    current_page?(url_options) ? name : link_to_remote_facebox(name, url_options, html_options)
  end
  
  # javascript to close the facebox
  def close_facebox_javascript
    <<-JS
facebox ? facebox.close() : (fb ? fb.close() : null);
    JS
  end
  
  # javascript helper returning facebox instance
  def facebox_instance_javascript
    "(facebox ? facebox : fb)"
  end
  
  # javascript html tag to close facebox
  def close_facebox_javascript_tag
    javascript_tag(close_facebox_javascript)
  end

  # necessary after we have replaced page elements with facebox links that have not been there when 
  # the page was loaded. Provide a dom id to selectively rebind rel tags only within that element,
  # and avoid double binding.
  def rebind_facebox_javascript(id)
    id = id.first == "'" ? id : "'#{id}'"
    <<-JS
#{facebox_instance_javascript}.watchClickEvents(#{id});
    JS
  end

  # renew javascript tag
  def renew_facebox_javascript_tag
    javascript_tag(renew_facebox_javascript)
  end
  
  # adds link to close facebox
  #
  # e.g.
  #
  #   link_to_close_facebox("Close")
  #
  def link_to_close_facebox(name, html_options = {})
    @uses_facebox = true
    @uses_modal = true
    link_to_function name, close_facebox_javascript, html_options
  end

  # adds standard html button to close facebox
  #
  # e.g.
  #
  #   button_to_close_facebox("Close")
  #
  def button_to_close_facebox(name, html_options = {})
    @uses_facebox = true
    @uses_modal = true
    button_to_function name, 'Facebox.close()', html_options
  end  
  
  private

  # adds a simple mechanism to determine the url options
  # as string, hash or hash with :url
  def facebox_url_for(url_options)
    if url_options.is_a?(String)
      uses_param_with(url_options)
    else # is a hash
      if url_options[:url]
        url_options.merge(:url => uses_param_with(url_for(url_options[:url])))
      else
        uses_param_with(url_for(url_options))
      end
    end
  end

  # adds an url encoded parameter to the given url_string
  def uses_param_with(url_string)
    unless url_string && url_string.match(/uses_modal/)
      if url_string.index("?")
        "#{url_string}&uses_modal=true"
      else
        "#{url_string}?uses_modal=true"
      end
    else
      url_string
    end
  end

end
