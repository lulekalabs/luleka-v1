# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper

  def csrf_meta_tag
    if protect_against_forgery?
      %(<meta name="csrf-param" content="#{Rack::Utils.escape_html(request_forgery_protection_token)}"/>\n<meta name="csrf-token" content="#{Rack::Utils.escape_html(form_authenticity_token)}"/>)
    end
  end
        
  # renders the block with the given template format
  #
  # e.g.
  #
  #   with_format :html do 
  #     render ...
  #   end
  #
  def with_format(format, &block)
    old_format = @template_format
    @template_format = format
    result = block.call
    @template_format = old_format
    return result
  end
  
  # see Money.format
  # TODO deprecate
  def money_display(money, options={})
  #  logger.debug("DEPRECATED: use Money.format instead")
    puts "DEPRECATED: money_display(<money>) has been deprecated, use <money>.format instead"
    money.format(options)
  end

  # Parse a string and returns a sanitized array of tags
  def sanitized_parse(list)
    tags = Tag.parse list
    case language_code
    when "de"
      tags.collect!{ |t| BAD_WORDS_de[t] ? BAD_WORDS_de[t] : t }
    else
      tags.collect!{ |t| BAD_WORDS_en[t] ? BAD_WORDS_en[t] : t }
    end
    tags = tags.reject{ |t| t.empty? } 
    tags.uniq!
    return tags
  end

  # Determines if this user is qualified to answer the case
  #
  # options:
  #   :include => true  # includes myself
  #
  # e.g.
  #
  #   do_i_qualify?(@issue) # -> returns true if user matches qualification for this issue
  #   do_i_qualify?(@issue, @person) # -> returns true if user matches qualification for this issue and person
  #
  def do_i_qualify?(issue, person=nil, options={})
    defaults = { :include => false }
    options = defaults.merge(options).symbolize_keys
    if person.nil?
      if user=current_user
        person=user.person
      else
        return false
      end
    end
    if options[:include]
      Person.find_qualified_partners_for(issue).include?(person)
    else
      issue.find_qualified_partners.include?(person)
    end
  end

  def time_ago_in_words_span_tag(from_time, include_seconds = false, html_options={})
    distance_of_time_in_words_span_tag(from_time, Time.now.utc, include_seconds, html_options)
  end

  def distance_of_time_in_words_span_tag(from_time, to_time = 0, include_seconds = false, html_options = {})
    html_options = {:id => "ta-#{rand(1000000)}"}.merge(html_options)
    html = span_tag('', html_options)
    html << javascript_tag( <<-JS
      $('#{html_options[:id]}').update(Luleka.DateHelper.distanceOfTimeInWords(#{(from_time.to_time.to_i * 1000).to_json}, #{(to_time.to_time.to_i * 1000).to_json}, #{include_seconds.to_json}));
    JS
    )
    html
  end

  # returns a span tag and the counter javascript
  def countdown_in_words_span_tag(to_time, html_options={})
    html_options = {:id => "cd-#{rand(1000000)}", :alt => to_time.loc, :title => to_time.loc}.merge(html_options)
    html = span_tag('', html_options)
    html << countdown_in_words_javascript_tag(html_options[:id], to_time)
    html
  end

  # adds a counter that counts down in words to a given dom id
  def countdown_in_words_javascript_tag(dom_id, to_time)
    javascript_tag <<-JS
      Luleka.DateHelper.countdownInWords(#{dom_id.to_json}, #{(to_time.to_i * 1000).to_json});
    JS
  end
  
  # javascript for standard observers, called e.g. after Ajax call
  def default_observer_javascript
    observe_textarea_autogrow_javascript + observe_textarea_markdown_javascript
  end

  # javascript to hookup the textarea autogrow observer
  def observe_textarea_autogrow_javascript
    <<-JS
      Widget.Textarea.observe(); 
    JS
  end
  
  # javascript to hookup the textarea markdown observer
  def observe_textarea_markdown_javascript
    <<-JS
      Markdown.Textarea.observe();
    JS
  end

  def observe_document_pretty_print_javascript
    <<-JS
      document.observe('dom:loaded',function(){
        prettyPrint();
      });
    JS
  end
  
  def observe_document_pretty_print_javascript_tag
    javascript_tag(observe_document_pretty_print_javascript)
  end

  def pretty_print_javascript
    <<-JS
      prettyPrint();
    JS
  end

  # javascript to scroll to the first message box in form
  def scroll_to_first_message_javascript
    <<-JS
      Luleka.Form.scrollToFirstMessage();
    JS
  end

  # Collect countries from globalize and create translations
  #
  # e.g.
  #
  #   collect_countries_for_select(true, "Choose...")
  #
  def collect_countries_for_select(all_countries=true, with_select=false)
    default = []
    all = []
    Utility.active_country_codes.each {|code| default.concat([[I18n.t(code, :scope => 'countries'), code]])}
    default = default.compact.sort_by {|province| province.first.parameterize}
    if all_countries
      all.concat(LocalizedCountrySelect::localized_countries_array)
      all = all - default
    end
    default.concat(['-' * 25]) if default.size != 0 && all.size != 0
    all = default.concat(all)
    all.insert(0, [with_select.is_a?(String) ? with_select : "Select...".t, nil]) if with_select
    all
  end

  # Used in views to collect the languages readily used
  # in select_display
  def collect_supported_languages_for_select(with_select=false)
    Utility.active_language_codes.map {|code| [I18n.t(code, :scope => 'languages'), code]}.sort_by {|l| l.first.parameterize}.insert(0,
      with_select ? [with_select.is_a?(String) ? with_select : "Select...".t, nil] : nil).reject {|a| a.nil?}
  end
  
  # lists the available locale languages and countries
  def collect_supported_locales_for_select(with_select=false)
    Utility.active_locales.map {|code| ["#{I18n.t(I18n.locale_language(code), :scope => 'languages')} - #{I18n.t(I18n.locale_country(code), :scope => 'countries')}", code]}.sort_by {|l| l.first.parameterize}.insert(0,
      with_select ? [with_select.is_a?(String) ? with_select : "Select...".t, nil] : nil).reject {|a| a.nil?}
  end

  # Prepare currency array for select in register view
  #
  # e.g.
  #
  #   collect_currencies_for_select(true)
  #   collect_currencies_for_select(false)
  #   collect_currencies_for_select("Choose...")
  #
  def collect_currencies_for_select(with_select=false)
    result = LocalizedCurrencySelect::localized_currencies_array_with_unit_and_code
    result.insert(0, with_select ? [with_select.is_a?(String) ? with_select : "Select...".t, nil] : nil)
    result.reject!(&:blank?)
    result
  end

  # returns an array of time zones that are in the US or Germany
  def collect_preferred_time_zones_for_time_zone_select
    ::ActiveSupport::TimeZone.us_zones + [::ActiveSupport::TimeZone['Berlin']]
  end

  # returns link to favicon
  # <link rel="icon" href="/favicon.ico" type="image/x-icon">
  def link_to_fav_icon
    # tag(:link, {:rel => "shortcut icon", :href => compute_public_path('favicon.ico', 'images'), :type => "image/x-icon"}, true)
    "<link href=\"#{compute_public_path('favicon.ico', 'images')}\" rel=\"shortcut icon\" type=\"image/x-icon\"/>"
  end
  
  def link_to_itouch_icon
    # tag(:link, {:rel => "apple-itouch-icon", :href => compute_public_path('apple-touch-icon.png', 'images')}, true)
    "<link href=\"#{compute_public_path('apple-touch-icon.png', 'images')}\" rel=\"apple-itouch-icon\"/>"
  end

  # javascript for luleka feedback widget
  def feedback_javascript(options={})
    options = {
      :key => 'luleka',
      :asset_host => RAILS_ENV == 'development' ? 'luleka.local:3000' : 'www.luleka.com',
      :domain => Utility.site_domain,
      :locale => "#{Utility.short_locale}",
      :show_tab => true,
      :tab_top => '45%',
      :tab_type => 'support',
      :tab_alignment => 'right',
      :tab_background_color => '#62B2B6',
      :tab_text_color => 'white',
      :tab_hover_color => '#008CDC'
    }.merge(options)
    
    js_location = case RAILS_ENV
      when /production/ then "www.luleka.com/javascripts/widgets/boot.js"
      when /staging/ then "www.staging.luleka.net/javascripts/widgets/boot.js"
      else "luleka.local:3000/javascripts/widgets/boot.js"
    end
    
    <<-JS
var lulekaOptions = #{options.to_json};

function _loadLuleka() {
  var s = document.createElement('script');
  s.setAttribute('type', 'text/javascript');
  s.setAttribute('src', ("https:" == document.location.protocol ? "https://" : "http://") + "#{js_location}");
  document.getElementsByTagName('head')[0].appendChild(s);
}
_loadSuper = window.onload;
window.onload = (typeof window.onload != 'function') ? _loadLuleka : function() { _loadSuper(); _loadLuleka(); };
    JS
  end

  # javascript tag for luleka feedback widget
  def feedback_javascript_tag(options={})
    javascript_tag(feedback_javascript(options))
  end

  # returns link to "Sign In or Sign Up"
  def link_to_signin_or_signup(signin_text="Sign In".t, signup_text="Sign Up".t, modal=true)
    result = []
    unless modal
      # signin link
      result << if current_page?(new_session_path) || current_page?(session_path)
        signin_text
      else
        link_to_unless_current(signin_text, new_session_url_with_ssl, {:id => "signin"})
      end
      # signup link
      result << if current_page?(new_user_path) || current_page?(:controller => "users", :action => "create")
        signup_text
      else
        link_to_unless_current(signup_text, new_user_path, {:id => "signup", :class => "highlighted"})
      end
    else
      # signin link
      result << if current_page?(new_session_path) || current_page?(session_path)
        signin_text 
      else
        link_to_remote_facebox(signin_text, new_session_url_with_ssl_and_modal,
          {:id => "signin", :rel => "facebox"})
      end
      # signup link
      result << if current_page?(new_user_path) || current_page?(:controller => "users", :action => "create")
        signup_text
      else 
        url = if @tier || params[:tier_id] 
          collection_url([:tier, :user], :new, {:tier_id => @tier || params[:tier_id]})
        else
          new_user_url
        end
        link_to_remote_facebox(signup_text, url, 
          {:id => "signup", :class => "highlighted"})
      end
    end
    result.to_sentence_with_or.strip_period
  end

  # returns link to "Sign Up" as normal or modal link
  def link_to_signup(signup_text="Sign Up".t, modal=true)
    unless modal
      link_to(signup_text, new_user_path, {:id => "signup"})
    else
      link_to_remote_facebox(signup_text, new_user_url(:uses_modal => "1"), 
        {:id => "signup", :rel => "facebox"})
    end
  end

  # signout link
  def link_to_signout(signout_text="Sign Out".t)
    if current_user && current_user.respond_to?(:facebook_user?) && current_user.facebook_user?
      link_to_function(signout_text, 
        "FB.Connect.logoutAndRedirect(\"#{session_url_with_ssl}\")",
        {:method => :delete, :id => "signout", :href => session_url_with_ssl})
    else
      link_to(signout_text, session_url_with_ssl, {:method => :delete, :id => "signout"})
    end
  end

  # facebook magic to link account
  def link_to_fb_connect(text=nil, options={})
    options = options.symbolize_keys.merge({:perms => "email,publish_stream,user_interests,user_about_me,user_groups,user_interests,user_location,user_photos,user_website,offline_access"})
    if @tier || params[:tier_id]
      url_modal = collection_url([:tier, :users], :link_fb_connect, {:tier_id => @tier || params[:tier_id],
        :uses_opened_modal => uses_modal?})
      url = collection_url([:tier, :users], :link_fb_connect, {:tier_id => @tier || params[:tier_id]})
    else
      url_modal = link_fb_connect_users_path({:uses_opened_modal => uses_modal?})
      url = link_fb_connect_users_path
    end
    text ||= if true
      image_tag("icons/fb/fb-login-107x25.gif", :id => "RES_ID_fb_login_image", :alt => "Facebook Connect", :title => "Facebook Connect")
    else
      image_tag("http://static.ak.fbcdn.net/rsrc.php/zA114/hash/7e3mp7ee.gif", :id => "RES_ID_fb_login_image", :alt => "Facebook Connect", :title => "Facebook Connect")
    end
    
    link_to_function(text,
     nil, {:class => "fbconnect_login_button", :id => "facebookConnect",
       :href => url}) do |page|
      page << "Luleka.Facebook.session('#{url_modal}', '#{form_authenticity_token}', #{options.to_json});"
    end
  end

  # twitter magic to connect to link account
  def link_to_twitter_connect(text=nil, options={})
    options = options.symbolize_keys.merge({})

    text ||= if true
      image_tag("icons/fb/fb-login-107x25.gif", :id => "RES_ID_fb_login_image", :alt => "Facebook Connect", :title => "Facebook Connect")
    else
      image_tag("http://static.ak.fbcdn.net/rsrc.php/zA114/hash/7e3mp7ee.gif", :id => "RES_ID_fb_login_image", :alt => "Facebook Connect", :title => "Facebook Connect")
    end
    
    url = url_modal = "#" 
    link_to_function(text,
     nil, {:class => "twitter_login_button", :id => "twitterConnect",
       :href => url}) do |page|
      page << "Luleka.Facebook.session('#{url_modal}', '#{form_authenticity_token}', #{options.to_json});"
    end
  end

  # in the header that javascript is not enabled
  def noscript_warning
    unless current_page?(:controller => 'pages', :action => 'no_javascript')
      <<-HTML
<noscript>
  <meta http-equiv="refresh" content="0; URL=#{url_for(:controller => 'pages', :action => 'no_javascript')}" />
</noscript>
      HTML
    end
  end
  
  # Javascript for google analytics
  def ga_async_javascript(id)
    <<-JS
var _gaq = _gaq || [];
_gaq.push(['_setAccount', '#{id}']);
_gaq.push(['_setDomainName', '.luleka.com']);
_gaq.push(['_trackPageview']);

(function() {
  var ga = document.createElement('script');
  ga.src = ('https:' == document.location.protocol ? 'https://ssl' : 'http://www') + '.google-analytics.com/ga.js';
  ga.setAttribute('async', 'true');
  document.documentElement.firstChild.appendChild(ga);
})();
    JS
  end
  
  # wraps ga code in a script tag
  def ga_async_javascript_tag(id)
    javascript_tag(ga_async_javascript(id)) if RAILS_ENV == "production"
  end

  # feedback remote link with ajax
  def link_to_feedback_remote(name="Feedback".t)
	  link_to(name, new_luleka_kase_path, 
	    :onmouseover => "Luleka.Popin.preload();return false;", 
	    :onclick => "Luleka.Popin.show(lulekaOptions);return false;")
  end
  
  # feedback remote link with ajax
  def link_to_feedback(name="Feedback".t)
	  link_to(name, new_luleka_kase_path)
  end

  # dom element of the top navigation status
  def status_dom_id
    'topHeaderSmallNavi'
  end
  
end
