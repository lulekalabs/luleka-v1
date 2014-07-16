module Admin::AdminApplicationHelper

  #   <li class='active'><a href='/admin'>Home</a></li>
  def admin_tab_list_link_to(name, url, options={})
    content_tag(
      :li,
      link_to(name, url, options),
      current_page?(url) ? {:class => 'active'} : {}
    )
  end
  
  def admin_tab_list_link_to_if(condition, name, url, options={})
    admin_tab_list_link_to(name, url, options) if condition
  end

  def admin_tab_list_link_to_unless(condition, name, url, options={})
    admin_tab_list_link_to(name, url, options) unless condition
  end

  # Adds a hidden field and a button_to_function for submitting
  # the form and telling the controller to re-render the same page
  def form_button(name='Save', options={})
    id = "#{ (options.delete(:name) || name.shortcase) }_only".to_sym
    id_button = "#{id}_button".to_sym
    confirm = options.delete(:confirm)
    html = ''
    html << hidden_field_tag(id)
    html << submit_tag(name, {:onclick => update_page do |page|
      if confirm
        page << "if (#{confirm_javascript_function(confirm)}) {"
        page[id].value = '1' 
        page << "} else {"
        page << "return false;"
        page << "}"
      else
        page[id].value = '1' 
      end
    end }.merge(options))
    html
  end

  def form_button_for_event(name, event, options={})
    if @record.next_state_for_event(event)
      form_button(name, options)
    end
  end
  
  def render_action_link(link, url_options)
    url_options = url_options.clone
    url_options[:action] = link.action
    url_options[:controller] = link.controller if link.controller
    url_options.delete(:search) if link.controller and link.controller.to_s != params[:controller]
    url_options.merge! link.parameters if link.parameters

    html_options = {:class => link.action}
    if link.inline?
      # NOTE this is in url_options instead of html_options on purpose. the reason is that the client-side
      # action link javascript needs to submit the proper method, but the normal html_options[:method]
      # argument leaves no way to extract the proper method from the rendered tag.
      url_options[:_method] = link.method

      if link.method != :get && respond_to?(:protect_against_forgery?)
        url_options[:authenticity_token] = form_authenticity_token if protect_against_forgery?
      end
    else
      # Needs to be in html_options to as the adding _method to the url is no longer supported by Rails
      html_options[:method] = link.method
    end

    html_options[:confirm] = link.confirm if link.confirm?
    html_options[:position] = link.position if link.position and link.inline?
    html_options[:class] += ' action' if link.inline?
    html_options[:popup] = true if link.popup?
    html_options[:id] = action_link_id(url_options[:action],url_options[:id])

    if link.dhtml_confirm?
      html_options[:class] += ' action' if !link.inline?
      html_options[:page_link] = 'true' if !link.inline?
      html_options[:dhtml_confirm] = link.dhtml_confirm.value
      html_options[:onclick] = link.dhtml_confirm.onclick_function(controller,action_link_id(url_options[:action],url_options[:id]))
    end

    # issue 260, use url_options[:link] if it exists. This prevents DB data from being localized.
    label = url_options.delete(:link) || link.label
    unless label.to_s.empty?
      if /\[(.*)\]/.match(label.to_s)
        button_to $1, url_options, html_options
      else
        link_to label, url_options, html_options
      end
    end
  end

  # overrides the default button_to method to support ajax submits
  def button_to(name, options = {}, html_options = {})
    html_options = html_options.stringify_keys
    convert_boolean_attributes!(html_options, %w( disabled ))

    method_tag = ''
    if (method = html_options.delete('method')) && %w{put delete}.include?(method.to_s)
      method_tag = tag('input', :type => 'hidden', :name => '_method', :value => method.to_s)
    end

    form_method = method.to_s == 'get' ? 'get' : 'post'

    request_token_tag = ''
    if form_method == 'post' && respond_to?(:protect_against_forgery?) && protect_against_forgery?
      request_token_tag = tag(:input, :type => "hidden", :name => request_forgery_protection_token.to_s, :value => form_authenticity_token)
    end

    if confirm = html_options.delete("confirm")
      html_options["onclick"] = "return #{confirm_javascript_function(confirm)};"
    end

    url = options.is_a?(String) ? options : self.url_for(options)
    name ||= url

    html_options.merge!("type" => "submit", "value" => name)

    form_remote_tag({ :url => url, :html => { :class => 'button_to' }}.merge(html_options[:confirm] ? {:confirm => html_options[:confirm]} : {})) +
      "<div>" + method_tag + tag("input", html_options) + request_token_tag + "</div></form>"
  end

end
