# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.
class ApplicationController < ActionController::Base
  include AuthenticatedSystem
  include ExceptionNotification::Notifiable
  include CacheKeys
  include Facebooker2::Rails::Controller

  htpasswd :user => "stage", :pass => "staging" if RAILS_ENV == 'staging'
  
#  session :off, :if => proc {|request| Utility.robot?(request.user_agent)}
  
  #--- filter logging
  filter_parameter_logging :password, :password_confirmation, :credit_card, :fb_sig_friends

  #--- filters
  before_filter :redirect_obsolete_domains
  before_filter :store_previous
  after_filter  :set_charset
  self.allow_forgery_protection = false
  # skip_before_filter :verify_authenticity_token # playing with the CSRF token issue resetting session 
  # before_filter :set_facebook_session
  # helper_method :facebook_session

  #--- rescue pages
  unless ActionController::Base.consider_all_requests_local
    rescue_from Exception, :with => :render_500
    rescue_from ActionController::RoutingError, :with => :render_404
    rescue_from ActionController::UnknownAction, :with => :render_404
    rescue_from ActionController::UnknownController, :with => :render_404
    rescue_from ActiveScaffold::ActionNotAllowed, :with => :render_401
    rescue_from ActiveRecord::RecordNotFound, :with => :render_404
  end
     
  # See ActionController::RequestForgeryProtection for details
  # Uncomment the :secret if you're not using the cookie session store
  protect_from_forgery # :secret => 'ffaf0d5091dab90a0c48ac5427dcb6bea53a1e1a'

  include SslRequirement

  def translate
    if params[:code]
      new_locale = Utility.short_to_long_locale(params[:code])
      if new_locale && self.current_locale != new_locale
        cookies[locale_cookie_token] = {
          :value => new_locale,
          :expires => 15.days.from_now,
          :domain => Utility.site_domain
        }
        self.current_locale = new_locale
      end
    end
    redirect_to params[:to] || "/"
  end

  protected

  # helper to determine if we are in nl?
  def nl?
    session[:site_ui] == "nl"
  end
  helper_method :nl?

  # returns true if this request's protocol is SSL
  def ssl_requested?
    request.protocol == "https://"
  end

  # redirects those subdomains that are no longer used, e.g.
  #
  #   http://luleka.net      ->  http://luleka.com
  #   http://www.luleka.net  ->  http://luleka.com
  #   http://www.luleka.com  ->  http://luleka.com
  #   http://de.luleka.com   ->  http://luleka.com?locale=de
  #
  def redirect_obsolete_domains
    if Utility.domain_from_host(request.host) == "luleka.net"
      # e.g. http://luleka.net/foo/bar -> http://luleka.com/foo/bar
      redirect_to request.protocol + 
        request.host.gsub(Regexp.new(Utility.domain_from_host(request.host), Regexp::IGNORECASE), "luleka.com") + 
          request.request_uri, :status => :moved_permanently
      return false
    elsif [request.subdomains].compact.flatten.map(&:to_s).first == "www"
      # e.g. http://www.luleka.com  ->  http://luleka.com
      redirect_to url_for({}).gsub(/\/\/www\./, "//"), :status => :moved_permanently
      return false
    elsif locale = locale_from_subdomain
      # e.g. http://de.luleka.com  ->  http://luleka.com?locale=de
      short_locale = Utility.long_to_short_locale(locale)
      new_url = url_for({}).gsub(/\/\/#{short_locale}\./, "//")
      new_url = new_url.index("?") ? "#{new_url}&locale=#{short_locale}" : "#{new_url}?locale=#{short_locale}"
      redirect_to new_url, :status => :moved_permanently
      return false
    elsif !Utility.request_host_main_domain?(request.host) && locale = locale_from_request_host
      # e.g. http://www.luleka.com.ar  ->  http://luleka.com?locale=ar
      short_locale = Utility.long_to_short_locale(locale)
      new_url = url_for({:host => ActionMailer::Base.default_url_options[:host] || "luleka.com", 
        :locale => short_locale})
      redirect_to new_url, :status => :moved_permanently
      return false
    end
  end
  
  # the :locale parameter represents an abbreviated locale code, where 
  # 
  #   'de.luleka.com' stands for 'de-DE'
  #   'us.luleka.com' stands for 'en-US'
  #   etc.
  #
  # if the locale is not included, we are trying to infer the locale from
  # 
  #   * host domain, e.g. 'luleka.de'  stands for  'de-DE'
  #   * http accept language, e.g. 'es'  stands for  'es-ES'
  #
  def set_locale
    # locale_from_subdomain
    if new_locale = locale_from_params || locale_from_subdomain
      # set locale from url's subdomain
      I18n.locale = @new_locale = new_locale
      return true
    elsif self.current_locale
      # set the locale from session
      I18n.locale = self.current_locale
    elsif current_user && current_user.default_locale
      # set user's locale
      I18n.locale = current_user.default_locale
    else
      # set locale from host name, e.g. luleka.co.uk or request language code
      # locale from domain name or request language
      host_locale = Utility.request_host_to_supported_locale(request.host)
      request_locale = Utility.request_language_to_supported_locale(request.env['HTTP_ACCEPT_LANGUAGE'].to_s)
      
      # filter active locales
      new_locale = host_locale || request_locale || :"en-US"
      new_locale = Utility.supported_locale?(new_locale) ? new_locale.to_sym : :"en-US"
      
      # set new locale or use default
      I18n.locale = new_locale
    end
  end

  def set_charset
    unless headers["Content-Type"] =~ /charset/i
      headers["Content-Type"] ||= ""
      %(headers["Content-Type"] += "; charset=utf-8")
    end
  end

  # back parameter for session id, override in sub controller
  def return_to_previous_param
    :redirect_previous
  end

  # current parameter for session id, override in sub controller
  def return_to_current_param
    :redirect_current
  end

  # saves the redirect back location
  def store_previous
    unless request.xhr?
      session[return_to_previous_param] = session[return_to_current_param]
      session[return_to_current_param] = request.get? ? request.request_uri : request.env["HTTP_REFERER"]
    end
  end
  
  # url to the previous url location stored in the session
  def return_to_previous_url
    session[return_to_previous_param]
  end

  # url to the current url location stored in the session
  def return_to_current_url
    session[return_to_current_param]
  end

  # Redirect to the URI stored by the most recent store_previous call or
  # to the passed default.
  def redirect_previous_or_default(default)
    redirect_to(return_to_previous_url || default)
    session[return_to_previous_param] = nil
    session[return_to_current_param] = nil
  end
  
  # rescues redirect back error
  # http://blog.hendrikvolkmer.de/2007/3/8/http-referer-and-redirect_to-back/
  def rescue_action_in_public(exception)
    case exception
    when ::ActionController::RedirectBackError
      redirect_back = session[:redirect_back] || '/'
      redirect_to redirect_back
    else
      super
    end
  end

  def ssl_supported?
    RAILS_ENV == 'production'# || RAILS_ENV == 'staging'
  end
  helper_method :ssl_supported?
  
  # converts from user time zone to UTC time and returns the new time
  # NOTE: the resulting time format may not show "UTC" but it is
  def user2utc(user_time)
    current_user && current_user.tz ? current_user.tz.dup.local_to_utc(user_time) : user_time
  end
  helper_method :user2utc

  # converts utc time to user time zone if the user is present
  def utc2user(utc_time)
    current_user && current_user.tz ? current_user.tz.dup.utc_to_local(utc_time) : utc_time
  end
  helper_method :utc2user

  # Retrieve country code for partial state_country
  # currently used in credit_card_entry and paypal_entry
  # 
  # e.g.
  # 
  #   instance_for(:person)  => returns @person
  #
  def instance_for(object_name)
    instance_variable_get("@#{object_name}")
  end
  helper_method :instance_for

  # returns the relevant class name for a controller name
  #
  # e.g.
  #
  #   'invitations' => 'Person'
  #
  def controller_name_to_class_name(name=controller_name)
    controller_name = case name.to_s.downcase
      when /invitation/, /invitations/ then 'Person'
      when /contacts/, /contact/ then 'Person'
      when /people/, /person/ then 'Person'
      when /organizations/, /organization/ then 'Organization'
    else
      'Kase'
    end
  end
  helper_method :controller_name_to_class_name
  
  # returns the class for controller name
  #
  # e.g.
  #
  #   'invitations'  ->  Person
  #
  def controller_name_to_class(name=controller_name)
    controller_name_to_class_name(name).constantize
  end
  helper_method :controller_name_to_class

  # returns the controller base who takes care of the given class
  #
  # e.g.
  #
  #   Person  ->  'people'
  #   'Kase'  =>  'kases'
  #
  def class_to_controller_base_name(class_or_class_name)
    case class_or_class_name.to_s
    when /Person/ then 'people'
    when /Invitation/ then 'invitations'
    when /Organization/ then 'organizations'
    when /Company/ then 'organizations'
    when /Product/ then 'products'
    when /Service/ then 'products'
    else
      'kases'
    end
  end
  helper_method :class_to_controller_base_name

  # returns the base name for a controller name
  #
  # e.g.
  #
  #   'contacts'  ->  'people'
  #
  def controller_name_to_controller_base_name(name=controller_name)
    class_to_controller_base_name(controller_name_to_class(name))
  end
  helper_method :controller_name_to_controller_base_name

  # returns the controller base for categoires
  #
  # e.g.
  #
  #   Person          ->  'people'
  #   'Organization'  ->  'kases'
  #
  def class_to_categories_controller_name(class_or_class_name)
    case class_or_class_name.to_s
    when /Person/, /Invitation/ then 'people'
    else
      'kases'
    end
  end
  helper_method :class_to_categories_controller_name

  def controller_name_to_categories_controller_name(name=controller_name)
    class_to_categories_controller_name(controller_name_to_class(name))
  end
  helper_method :controller_name_to_categories_controller_name

  # returns a path to the category depending on the controller context
  def category_controller_name_path(category, name=controller_name)
    send("category_#{controller_name_to_categories_controller_name}_path", :category_id => category)
  end
  helper_method :category_controller_name_path

  # set the page title
  def page_title=(title=nil)
    set_page_title(title)
  end
  helper_method :page_title=

  # gets the page title
  def page_title
    @page_title
  end
  helper_method :page_title

  # set the actual @page_title
  def set_page_title(title=nil)
    @page_title = "#{title || I18n.t('service.tagline')} - #{I18n.t('service.name')}"
  end

  # hash key for locale session id
  def locale_session_param
    :locale
  end
  
  def locale_cookie_token
    "#{locale_session_param}_auth_token".to_sym
  end
  
  # Accesses the current locale from the session. 
  def current_locale
    @current_locale ||= (load_locale_from_session || load_locale_from_cookie) unless @current_locale == false
    @current_locale.to_sym if @current_locale
  end
  helper_method :current_locale

  # Store the given locale in the session.
  def current_locale=(new_locale)
    new_locale = new_locale ? new_locale.to_sym : new_locale
    session[locale_session_param] = new_locale
    @current_locale = new_locale || false
  end
  
  def load_locale_from_session
    self.current_locale = session[locale_session_param] if session[locale_session_param]
  end

  # Called from #current_locale.  Finally, attempt to retrieve local by an expiring token in the cookie.
  def load_locale_from_cookie
    locale = cookies[locale_cookie_token]
    if locale
      cookies[locale_cookie_token] = {
        :value => locale,
        :expires => 15.days.from_now,
        :domain => Utility.site_domain
      }
      self.current_locale = locale
    end
  end
  
  # generic for e.g. organizations_path
  #
  # e.g.
  #
  #    collection_path(@tier)  ->  companies_path
  #    collection_path(Organization)  ->  organizations_path
  #    collection_path([@tier, @topic])  ->  tier_topics_path(:tier_id => @tier)
  #
  def collection_path(object_or_class, action=nil, options={})
    method_name, default = method_name_and_options_for_collection_path(object_or_class, action)
    send(method_name, default.merge(options))
  end
  helper_method :collection_path

  # dito, but url helper
  def collection_url(object_or_class, action=nil, options={})
    method_name, default = method_name_and_options_for_collection_path(object_or_class, action, true)
    send(method_name, default.merge(options))
  end
  helper_method :collection_url

  # generic for e.g. hash_for_organizations_path
  def hash_for_collection_path(object_or_class, action=nil, options={})
    method_name, default = method_name_and_options_for_collection_path(object_or_class, action)
    send("hash_for_#{method_name}", default.merge(options))
  end
  helper_method :hash_for_collection_path

  # generic for e.g. company_path(company)  ->  "companies/luleka"
  #
  # e.g.
  #
  #   member_path(Tier, :new)  ->  new_tier_path
  #   member_path([@tier, Topic], :new)  ->  new_tier_topic_path
  #   member_path([@tier, @topic])  ->  tier_topic_path(@topic)
  #
  def member_path(object_or_class, action=nil, options={})
    method_name, default = method_name_and_options_for_member_path(object_or_class, action)
    send(method_name, default.merge(options))
  end
  helper_method :member_path

  # dito, but url helper
  def member_url(object_or_class, action=nil, options={})
    method_name, default = method_name_and_options_for_member_path(object_or_class, action, true)
    send(method_name, default.merge(options))
  end
  helper_method :member_url

  # generic for e.g. hash_for_company_path(company)  ->  "companies/luleka"
  def hash_for_member_path(object_or_class, action=nil, options={})
    method_name, default = method_name_and_options_for_member_path(object_or_class, action)
    send("hash_for_#{method_name}", default.merge(options))
  end
  helper_method :hash_for_member_path

  # generates a context sensitive tag path
  #
  # e.g.
  #
  #   tag_path([Kase], "one two") /kases/tags/one+two
  #   /communities/apple/topics/imac/kases/tags/broken+fan
  #   /people/tags/juergen+programmer+rails
  #
  def tag_path(object_or_class, id, options={})
    "#{collection_path(object_or_class, nil, options)}/tags/#{id.is_a?(Tag) ? id.to_param : id}"
  end
  helper_method :tag_path

  # dito, just the url version
  def tag_url(object_or_class, id, options={})
    "#{collection_url(object_or_class, nil, options)}/tags/#{id.is_a?(Tag) ? id.to_param : id}"
  end
  helper_method :tag_url

  # temporarily sets the template format to something else
  # there is a view helper that works the same, this is used
  # in sessions controller to implement AJAX session login.
  #
  # e.g.
  #   ...
  #   format.js
  #     with_format :html do
  #       render :partial => 'foo' # will render foo.html.erb instead of foo.js.erb
  #     end
  #   end
  #   ...
  #
  def with_format(format)
    old_format = response.template.template_format
    response.template.template_format = format
    yield
    response.template.template_format = old_format
  end
  
  # returns true if a (e.g. facebox) modal has already been opened by the client
  # which is indicated by passing a uses_modal=true|1 parameter or the @uses_modal
  # instance method
  def uses_modal?
    @uses_modal ||= !!(params[:uses_modal] =~ /^true|^1/)
  end
  helper_method :uses_modal?

  # not only is 
  def uses_opened_modal?
    @uses_modal ||= !!(params[:uses_opened_modal] =~ /^true|^1/)
  end
  helper_method :uses_opened_modal?

  # adds SSL to session_url if 
  #
  #   * ssl is supported 
  #   * we are not rendering a modal dialog
  #   * we are already on SSL
  #
  # Note: we are adding back a uses_modal parameter in case uses_modal existed in GET
  #
  def session_url_with_ssl(options={})
    options = {:only_path => false, 
      :protocol => ssl_supported? && (!uses_modal? || request.ssl?) ? 'https://' : 'http://'}.merge(options)
    options = options.merge({:uses_modal => true}) if uses_modal?
    if @tier || params[:tier_id]
      options = options.merge({:tier_id => @tier || params[:tier_id]})
      collection_url([:tier, :session], nil, options)
    else
      collection_url([:session], nil, options)
    end
  end
  helper_method :session_url_with_ssl

  # adds SSL to new_session_url if (see conditions above)
  def new_session_url_with_ssl(options={})
    options = {:only_path => false, 
      :protocol => ssl_supported? && (!uses_modal? || request.ssl?) ? 'https://' : 'http://'}.merge(options)
    options = options.merge({:uses_modal => true}) if uses_modal?
    if @tier || params[:tier_id]
      options = options.merge({:tier_id => @tier || params[:tier_id]}) 
      collection_url([:tier, :session], :new, options)
    else
      collection_url([:session], :new, options)
    end
  end
  helper_method :new_session_url_with_ssl

  # adds SSL to new_session_url if (see conditions above)
  def new_session_url_with_ssl_and_modal(options={})
    @uses_modal = true
    new_session_url_with_ssl(options.merge(uses_modal? ? {:uses_modal => true} : {}))
  end
  helper_method :new_session_url_with_ssl_and_modal

  # new session path propagating the xhr and if necessary the uses_modal
  # NOTE: obsolete?
  def new_session_path_with_xhr_and_modal(options={})
    @uses_modal = true
    new_session_path(options.merge(:xhr_redirect => true).merge(uses_modal? ? {:uses_modal => true} : {}))
  end

  # returns true if this request from a Googlebot, etc.
  def request_from_robot?
    !!Utility.robot?(request.user_agent)
  end

  # halts the filter chain if request is from robot
  def stop_request_from_robot
    if request_from_robot?
      render_optional_error_file(404)
      return false
    end
  end

  # this mechanism is used when a redirect has occured and we 
  # want to render xhr, e.g. on session login with modal
  # returns true if a params[:xhr_redirect] = '1'||"true" exists
  def xhr_redirect?
    !!(params[:xhr_redirect] =~ /^true|^1/) || flash[:xhr_redirect]
  end
  helper_method :xhr_redirect?

  # xhr redirect_to are passed on in Safari, but not in Firefox
  # so when we receive an xhr parameter given through the 
  # account_controller method using authenticated plugin, we
  # are adding back the xhr headers
  def reset_header_on_xhr_redirect
    if xhr_redirect?
      request.env['HTTP_X_REQUESTED_WITH'] = 'XMLHttpRequest' unless request.xhr?
      unless request.env['HTTP_ACCEPT'] =~ /^text\/javascript/
        request.env['HTTP_ACCEPT'] = "text/javascript, #{request.env['HTTP_ACCEPT']}"
      end
    end
  end

  # empty flash used in after_filter
  #
  # e.g.
  #
  #   after_filter :discard_flash, :only => :new
  #
  def discard_flash
    flash.discard
  end

  # this indicated if the password needs to be encrypted in addition to SSL 
  # or if SSL is not available.
  # default setting to not encrypt password, will be overriden in session controllers
  def encryption_required?
    Rails.env.development? ? false : request.protocol != "https://"
  end
  helper_method :encryption_required?

  # override from globalize_bridge
  def render_optional_error_file(status_code)
    I18n.locale = self.current_locale if self.current_locale
    super(status_code)
  end
  
  # override from ssl_requirement
  # http://ianlotinsky.wordpress.com/2010/09/29/ssl-in-ruby-on-rails/
  def ensure_proper_protocol
    if !ssl_allowed? && ssl_required? && !request.ssl? && !(request.get? || request.head?)
      raise 'SSL required!' # either we have a bug somewhere or someone is playing with us.
    else
      super
    end
  end
  private

  # helper returns method_name and options for collection_path and hash_for_collection_path
  def method_name_and_options_for_collection_path(object_or_class, action=nil, url=false)
    method_names = []
    options = {}
    [object_or_class].flatten.compact.each_with_index do |member, index|
      if member.class == Class
        # for class reps e.g. [Tier, Topic]
        if [object_or_class].flatten.compact.size - 1 == index
          # last index, e.g. [Person] -> people_path
          method_names << "#{polymorphic_resource_class(member).name.underscore.pluralize}_"
        else
          # before last, e.g. [Kase, Response] -> kase_responses_path
          method_names << "#{polymorphic_resource_class(member).name.underscore}_"
        end
      elsif member.class == String || member.class == Symbol
        # for string reps ["tier", "members"] or  [:tier, :members]
        if [object_or_class].flatten.compact.size - 1 == index
          method_names << "#{member.to_s.underscore}_"
        else
          method_names << "#{member.to_s.underscore}_"
        end
      else
        # for class instance reps [@tier, @topic]
        if [object_or_class].flatten.compact.size - 1 == index
          method_names << "#{polymorphic_resource_class(member.class).name.underscore.pluralize}_"
        else
          method_names << "#{polymorphic_resource_class(member.class).name.underscore}_"
          options["#{polymorphic_resource_class(member.class).name.underscore}_id"] = member if member.id
        end
      end
    end
    return "#{action ? "#{action}_" : ''}#{method_names}#{url ? 'url' : 'path'}", options.symbolize_keys
  end
  
  # helper returns method_name and options for member_path and hash_for_member_path
  def method_name_and_options_for_member_path(object_or_class, action, url=false)
    method_names = []
    options = {}
    [object_or_class].flatten.compact.each_with_index do |member, index|
      if member.class == Class
        method_names << "#{polymorphic_resource_class(member).name.underscore}_"
      elsif member.class == Symbol
        method_names << "#{polymorphic_resource_class(member.to_s.classify.constantize).name.underscore}_"
      else
        method_names << "#{polymorphic_resource_class(member.class).name.underscore}_"
        if [object_or_class].flatten.compact.size - 1 == index
          options["id"] = member
        else
          options["#{polymorphic_resource_class(member.class).name.underscore}_id"] = member
        end
      end
    end
    return "#{action ? "#{action}_" : ''}#{method_names}#{url ? 'url' : 'path'}", options.symbolize_keys
  end
  
  # returns the class for which a polymorphic resource exists
  #
  # E.g. 
  #
  #   Organization -> Tier
  #   Problem -> Problem
  #   Product -> Topic
  #
  def polymorphic_resource_class(klass)
    if %w(Tier Group Organization).include?(klass.name)
      Tier
    elsif %w(Topic Product Service).include?(klass.name)
      Topic
    else
      klass
    end
  end
  
  # From http://launchpad.rocketjumpindustries.com/posts/5-defining-a-dynamic-page-cache-loction-by-subdomain-in-rails
  #
  # Inserts the currently requested host as a directory in front of the
  # cached file location. Assuming you’ve moved the default page cache
  # storage location to /public/cache, a request to www.example.com would be
  # cached as:
  #
  # RAILS_ROOT/public/cache/www.example.com/index.html
  # (page_cache_directory/host/request_path)
  #
  def cache_page_with_domain(content = nil, options = nil)
    path = "/#{request.host}/"
    path << case options
    when Hash
      url_for(options.merge(:only_path => true, :skip_relative_url_root => true, :format => params[:format]))
    when String
      options
    else
      if request.path.empty? || request.path == '/'
        '/index'
      else
        request.path
      end
    end
    cache_page_without_domain(content, path)
  end
  alias_method_chain :cache_page, :domain

  # normalize_params
  # or to_post_params
  #
  # e.g.
  #
  #   {:sidebar => '1'}  ->  ?sidebar=1
  #
  def create_post_params(params, base = "")
    toreturn = ''
    params.each_key do |key|
      keystring = base.blank? ? key : "#{base}[#{key}]"
      toreturn << (params[key].class == Hash ? create_post_params(params[key], keystring) : "#{keystring}=#{CGI.escape(params[key])}&")
    end
    toreturn
  end
  
  # helper to return current domain if any
  def current_subdomain
    [request.subdomain].flatten.last
  end
  
  # returns the locale if found in request subdomain, 
  #
  # e.g. 
  #
  #   http://de.luleka.com -> :"de-DE"
  #   http://luleka.com -> nil
  #   http://de.apple.luleka.com -> :"de-DE"
  #   http://apple.luleka.com -> nil
  #
  def locale_from_subdomain
    subdomains = [request.subdomains].compact.flatten
    if subdomains.first && Utility.active_short_locales.include?(subdomains.first.to_sym)
      return Utility.short_to_long_locale(subdomains.first.to_sym)
    end
  end
  
  # E.g.
  #
  #  http://luleka.de => :"de-DE"
  #  http://luleka.com.ar => :"es-AR"
  #
  def locale_from_request_host
    Utility.request_host_to_supported_locale(request.host)
  end

  # returns the (long) locale if found in parameters as locale 
  #
  # e.g. 
  #
  #   http://www.luleka.com?locale=de -> :"de-DE"
  #   http://www.luleka.com?locale=us -> :"en-US"
  #
  def locale_from_params
    if params[:locale] && Utility.active_short_locales.include?(params[:locale].to_sym)
      return Utility.short_to_long_locale(params[:locale])
    end
  end
  
  # overrides route path, from http://luleka.com/tiers/bla to http://foo.luleka.com
  def tier_url(*args)
    tier_root_url(*args)
  end
  alias_method :tier_path, :tier_url
  helper_method :tier_path
  helper_method :tier_url
  
  # e.g. http://luleka.luleka.com/
  def luleka_root_url
    tier_root_url(:tier_id => SERVICE_TIER_NAME)
  end
  alias_method :luleka_root_path, :luleka_root_url
  helper_method :luleka_root_path
  helper_method :luleka_root_url

  # not found
  def render_404(error)
    respond_to do |type|
      type.html { render_optional_error_file(404) }
      type.all  { render :nothing => true, :status => "404 Not Found" }
    end
  end

  # not allowed
  def render_401(error)
    respond_to do |type|
      type.html { render_optional_error_file(401) }
      type.all  { render :nothing => true, :status => "401 Not Allowed" }
    end
  end

  # app error
  def render_500(error)
    respond_to do |type|
      type.html { render_optional_error_file(500) }
      type.all  { render :nothing => true, :status => "500 Error" }
    end
    # notify_about_exception(error)
  end

end
