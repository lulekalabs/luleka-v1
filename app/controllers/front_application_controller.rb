# Base controller foundation for all front-end controllers
class FrontApplicationController < ApplicationController
  include FrontApplicationBase
  helper :people, :text

  #--- layout
  layout :choose_layout

  #--- accessors
  class_inheritable_accessor :theme_name
  class_inheritable_accessor :theme_method_name

  #--- filters
  prepend_before_filter :login_required
  prepend_before_filter :set_locale
  before_filter :stop_request_from_robot, :only => [:list_item_expander]
  before_filter :load_current_user_and_person
  # before_filter :destroy_account_session
  before_filter :reset_header_on_xhr_redirect
  
  #--- constants
  TAG_COUNT_LIMIT  = 30
  PER_PAGE         = 10
  LOCATIONS_LIMIT  = 100
  LOCATIONS_RADIUS = 50
  
  #--- class methods
  class << self

    def set_theme(a_theme_name)
      self.theme_name = a_theme_name
      before_filter :set_theme_instance
    end
    
    def choose_theme(method_name)
      self.theme_method_name = method_name
      append_before_filter :set_theme_instance
    end
    
  end
  
  protected

  def user_class
    User
  end
  
  def user_session_param
    :user_id
  end
  
  def return_to_param
    :return_to
  end
  
  def account_controller
    new_session_redirect_path
  end
 
  def account_login_path
    new_session_redirect_path
  end
  
  def new_session_redirect_path
    if request.xhr?
      options = {:xhr_redirect => true}.merge(params[:uses_modal] ? {:uses_modal => true} : {})
      if @tier || params[:tier_id]
        collection_url([:tier, :session], :new, options.merge({:tier_id => @tier || params[:tier_id]}))
      else
        new_session_path(options)
      end
    else 
      new_session_path
    end
  end

  def do_search_people(class_or_record=Person, method=nil, options={})
    @people = do_search(class_or_record, method, {
      :partial => 'people/list_item_content',
      :url => hash_for_people_path,
      :sort => {'people.last_name' => "Name".t}
    }.merge(options))
  end
  
  def do_search_kases(class_or_record=Kase, method=nil, options={})
    @kases = do_search(class_or_record, method, {
      :partial => 'kases/list_item_content',
      :url => hash_for_kases_path,
      :sort => {'kases.subject' => "Subject".t, 'kases.price_cents' => "Price".t, 'kases.expires_at' => "Time".t}
    }.merge(options))
  end
  
  # used in index / list actions for searching people
  # encapsulates ajax pagination and sorting
  # provides context sensitive tags instance if requested
  # 
  # Options:
  #   :with_tags => retrieves tag list for the requests objects
  #   :with_render => does render the list (used in AJAX calls)
  #   :per_page => <no of items per page> || 10
  #   :tag_count_limit => <no of tag items in @tags> || 30
  #   :model_name => 'Organization' || :organziation -> base class name used for tags
  #
  def do_search(class_or_record, method=nil, options={})
    options = {:per_page => PER_PAGE, :tag_count_limit => TAG_COUNT_LIMIT, 
      :with_tags => false, :with_render => false}.merge(options).symbolize_keys
    
    tag_count_limit = options.delete(:tag_count_limit)
    with_tags = options.delete(:with_tags)
    with_render = options.delete(:with_render) || request.xhr?
    model_name = options.delete(:model_name)
    
    # search
    records = uses_list_for(
      class_or_record,
      method,
      options
    )
    
    # handle ajax request for pagination or sort order changes
    render :partial => 'shared/items_list_content', :locals => {
      :items => records,
      :options => options
    } if with_render
    
    # with tags
    # TODO: doesn't handle tag count within kontext of tier, etc.
    if with_tags == true && !records.empty?
      model ||= model_name ? model_name.constantize : records.first.class.base_class
      @tags = model.tag_counts(:limit => tag_count_limit, :order => "tags.name ASC")
    end  
      
    records
  end

  # Defines a instance variables with pagination based on parameters
  # stemming from name parameter
  # Params:
  #   ???_tag
  #   ???_sort
  #   ???_query
  #
  # Options:
  #   :per_page => 1..n
  #
  # Example:
  #   uses_list_for @person, :solved_issues, :per_page => 5
  #   or 
  #   uses_list_for Issue, nil, :per_page => 10
  def uses_list_for(class_or_record, method_name, options={})
    defaults = {:per_page => 10}
    options = defaults.merge(options).symbolize_keys

    # setup
    page = (params['page'] ||= 1).to_i
    per_page = options.delete(:per_page)

    # sort
    if sort = params['sort']
      sort = sort.gsub(/_reverse/, " DESC")
    end

    # merge conditions
    query = params['query']
    conditions = ["name LIKE ?", "%#{query}%"] unless query.nil?
    conditions = User.sanitize_and_merge_conditions(conditions, options[:conditions])

    # finder
    items = nil
    if tag_names = params['tag'] || params['tag_names']
      count = class_or_record.tag_counts(:tags => tag_names, :order => 'count desc', :delimiter => ',').first.count.to_i rescue 0
      items = class_or_record.find_tagged_with(tag_names, :delimiter => ',', :order => sort).paginate(
        :page => page,
        :per_page => per_page,
        :count => count
      )
    else
      if Class == class_or_record.class
        # Class, e.g. Person or Person.active
        method_name = nil if [:find_all, :all].include?(method_name)
        items = (method_name ? class_or_record.send(method_name) : class_or_record).all.paginate(
          :page => page, :per_page => per_page,
          :conditions => conditions, :order => sort, :include => options[:include]
        )
      else
        # active record instance
        items = (method_name ? class_or_record.send(method_name) : class_or_record).paginate(
          :page => page, :per_page => per_page,
          :conditions => conditions, :order => sort, :include => options[:include]
        )
      end
    end
    items
  end

  # retrieves current user and person if present
  def load_current_user_and_person
    if logged_in?
      @user = User.current_user = self.current_user
      @person = @user.person
    end
  end

  # Instantiate for each payment methods @mastercard, @visa, etc. with CreditCard
  # build_payment_objects
  def build_payment_methods(*payment_objects)
    PaymentMethod.types.each do |type|
      if payment_object = payment_objects.find {|o| PaymentMethod.normalize_type(o.type) == type}
        if payment_object.respond_to?(:type) && type == PaymentMethod.normalize_type(payment_object.type) &&
           payment_object.is_a?(PaymentMethod.klass(type))
          build_payment_method(type, payment_object, :select => payment_objects.index(payment_object) == 0)
          next
        end
      end
      build_payment_method(type, nil, :select => false)
    end
  end

  # Assign an object to an instance of a payment method
  # build_payment_object
  def build_payment_method(type, object_or_attributes=nil, options = {})
    options = {:select => true}.merge(options).symbolize_keys
    if !object_or_attributes || object_or_attributes.is_a?(Hash)
      object = instance_variable_set("@#{type}", PaymentMethod.build(type, object_or_attributes))
    elsif object_or_attributes.is_a?(PaymentMethod.klass(type))
      object = instance_variable_set("@#{type}", object_or_attributes)
    else
      object = nil
    end
    flash[:selected_payment_method] = type.to_sym if options[:select]
  	object
  end

  # Instantiate for each deposit method @paypal
  def build_deposit_methods(deposit_object=nil, attributes={})
    DepositMethod.types.each do |type|
      if deposit_object
        # in the following code we have to do class.to_s.constantize, otherwise DepositClass!=DepositClass
        if deposit_object.respond_to?(:kind) && deposit_object.kind == type &&
           deposit_object.is_a?(DepositMethod.klass(type))
          deposit_object.attributes = attributes
          build_deposit_method(type, deposit_object, :select => true)
          next
        end
      end
      build_deposit_method(type, attributes, :select => false)
    end
  end

  # Assign an object to an instance of a deposit method
  def build_deposit_method(type, object_or_attributes=nil, options={})
    options = {:select => true}.merge(options).symbolize_keys
    if !object_or_attributes || object_or_attributes.is_a?(Hash)
      # Note: we need to make sure that the transfer amount is
      #       assigned after the :person attribute is, so that
      #       when an amount of "1.50" is assigned as transfer
      #       amount gets converted correctly to the person's
      #       default currency.
      transfer_amount = object_or_attributes.delete(:transfer_amount)
      object = DepositMethod.build(type, object_or_attributes)
      object.transfer_amount = transfer_amount if transfer_amount
      object = instance_variable_set("@#{type}", object)
    elsif object_or_attributes.is_a?(DepositMethod.klass(type))
      object = instance_variable_set("@#{type}", object_or_attributes)
    else
      object = nil
    end
    flash[:selected_deposit_method] = type.to_sym if options[:select]
  	object
  end

  # Collects province from globalize_regions table
  def collect_provinces_for_select(country_code)
    result = nil
    unless country_code.to_s.empty?
      result = LocalizedProvinceSelect::localized_provinces_array("#{country_code}")
      result = nil if result.compact.empty?
    end
    result
  end
  helper_method :collect_provinces_for_select

  #--- globalize helpers
  
  # returns current locale code, e.g. 'en-US'
  def current_locale_code
    Utility.locale_code
  end
  helper_method :current_locale_code

  # Returns the current language code portion from locale (parameter or default)
  def current_language_code(locale=nil)
    Utility.language_code(locale)
  end
  helper_method :current_language_code

  def currency_code(locale=nil)
    Utility.currency_code(locale)
  end
  helper_method :currency_code

  # returns the current country_code from Locale
  def current_country_code(locale=nil)
    Utility.country_code(locale)
  end
  helper_method :current_country_code

  # returns true if current logged in user is person or user
  # This is used in profile views where the own profile looks different from other
  # peoples profiles.
  #
  # Note: This helper has a similar helper method, with block wrapping 
  #
  # e.g.
  #
  #   current_user_me? @person  #-> true if @person is me as a logged in user(.person)
  #
  def current_user_me?(user_or_person)
    if user_or_person && self.current_user
      if user_or_person.is_a?(User)
        return self.current_user == user_or_person
      elsif user_or_person.is_a?(Person)
        return self.current_user && self.current_user.person == user_or_person
      end
    end
    false
  end

  # opposit of current_user_me?
  def current_user_not_me?(user_or_person)
    if user_or_person && self.current_user
      return !current_user_me?(user_or_person)
    end
    false
  end

  # returns true if the current user is a friend/contact of given user/person
  def current_user_friends_with?(user_or_person)
    if user_or_person && self.current_user
      if user_or_person.is_a?(User)
        return self.current_user.person.is_friends_with?(user_or_person.person)
      elsif user_or_person.is_a?(Person)
        return self.current_user.person.is_friends_with?(user_or_person)
      end
    end
    false
  end
  
  # returns true if the current user is following a given followable
  # e.g a @user, @person, @kase, etc.
  def current_user_following?(followable)
    if followable && self.current_user
      if followable.is_a?(User)
        return self.current_user.person.following?(followable.person)
      elsif followable.respond_to?(:followers)
        return self.current_user.person.following?(followable)
      end
    end
    false
  end

  # called from before filter, to make sure we destroy the account session
  # so that when a user jumps from the account to the regular page, it makes
  # sure that the user cannot go back without account login
  def destroy_account_session
    session[Account::AccountApplicationController::USER_SESSION_PARAM] = nil
  end

  # loads a gmap key into @gmap_key depending on the request's URI
  # used in before filters, e.g. kases_controller
  def load_gmap_key
    url = request.protocol + Utility.domain_from_host(request.host) + (request.port_string.blank? ? "" : "#{request.port_string}")
    unless lookup_key = GOOGLE_MAPS_KEYS[url]
      logger.error "** Error looking up google maps key for \"#{url}\""
    end
    @gmap_key = lookup_key || GeoKit::Geocoders::google
    logger.warn "** Google maps key for \"#{url}\" is #{@gmap_key}"
  end

  # Works just like the RoR built-in error_messages_for helper with
  # additional parameters for translation and priorities.
  #
  # Options:
  #   :header => "%{errors} on %{object}" where those will be replaced with "5 errors" and "Person" 
  #   :sub_header => "This is a serious problem!"
  #   :priority => [ :username, :password, :gender]
  #   :attr_names => { :gender => "Geschlecht", :birthdate => ... }
  #   :defaults => true  # adds default values if any
  #   :type => :error || :warning || :notice
  #
  def form_error_messages_for(object_names, options = {}, &block)
    defaults = {
      :priority => [],
      :attr_names => {},
      :defaults => true,
      :header => options[:concise] ? "Errors".t : "The following errors occured".t,
      :sub_header => '',
      :type => :error,
      :unique => false,
      :concise => false,
      :theme => respond_to?(:current_theme_name) ? current_theme_name : :profile
    }
    options = defaults.merge(options).symbolize_keys
    options[:attr_names].symbolize_keys!

    # Convert object name to an array of objects
    object_names = [object_names].flatten
    objects = []
    object_names.each {|name| objects << (name.is_a?(String) || name.is_a?(Symbol) ? instance_variable_get("@#{name}") : name)}
    objects.reject! {|o| o.blank?}
    options.merge!(:objects => objects)

    # add errors
    errors = []
    objects.compact.each do |object| 
      object.errors.each do |attr, val| 
        if !options[:unique] || (errors.select {|item| item[0] == attr}.empty? && options[:unique])
          errors << [attr, [object.errors.on(attr)].flatten]
        end
      end
    end
    options.merge!(:errors => errors)

    # priotize and sort
    unless errors.empty?
      unless options[:priority].empty?
        errors.sort! do |a, b|
          if options[:priority].include?(a[0]) and options[:priority].include?(b[0])
            # both columns have priority, compare accordingly
            options[:priority].index(a[0]) <=> options[:priority].index(b[0])
          elsif options[:priority].include?(a[0])
            # column a defined, stick in front of b
            -1
          elsif options[:priority].include?(b[0])
            # column b defined, stick in front of a
            1
          else
            # both columns have equal priority
            0
          end
        end
      end

      # replace errors and object if present in the header string
      errors_count = if options[:attr_names].empty?
        errors.size
      else 
        errors.select {|item| options[:attr_names].has_key? item[0].to_sym}.size
      end
      options[:header] = options[:header] % {
        :errors => "%d error" / errors_count,
        :object => object_names.collect { |i| i.to_s.humanize.t }.join(", ")
      }
      if errors_count > 0
        if block_given?
          block_to_partial('shared/form_error_messages_for', options, &block) 
        else
          # i need to do the following because i want to use this method in controllers and views.
          # i want to avoid a double render exception. therefore, in the controller this will use
          # the render_to_string and when this function is used in the view, it will use the render
          # method.
          if respond_to?(:render_to_string)
            render_to_string :partial => 'shared/form_error_messages_for', :locals => options
          else
            render :partial => 'shared/form_error_messages_for', :locals => options
          end
        end
      end
    end
  end

  # returns the theme name
  def current_theme_name
    @theme_name
  end

  # checks the params hash for any occurances of a class "like" id or
  # returns nil if there is none
  #
  # e.g. class_param_id(Organization) checks for :organization_id, :company_id, :agency_id, etc.
  #
  def class_param_id(klass)
    klass.self_and_subclass_param_ids.each {|id| return params[id] if params[id]}
    nil
  end

  # protect the site in private alpha with basic authentication
  # username = environment, password = probono
  def basic_authentication
    if RAILS_ENV == "staging"
      authenticate_or_request_with_http_basic do |username, password|
        username == RAILS_ENV && password == "probono"
      end
    end
  end
  
  # define additional options, eager loading, when the current user is loaded
  # those are merged in login_from_session
  def user_class_find_options
    {:include => {:person => :piggy_bank}}
  end
  
  # override from authenticated system to eager load person 
  def login_from_session
    self.current_user = user_class.find_by_id(session[user_session_param],
      user_class_find_options) if session[user_session_param]
  end

  # layout between tier and front
  def choose_layout
    @tier ? 'tier' : 'front'
  end

  # adds a random number to the end of dom_class(...)
  def dom_class_with_random(*args)
    "#{dom_class(*args)}_#{rand(1000000)}"
  end
  helper_method :dom_class_with_random

  # used in before_filter e.g. before_filter :reputation_threshold_required
  # checks if the reputation threshold is sufficient, if not shows a message
  def reputation_threshold_required
    if current_user_requires_reputation_threshold?
      if (result = Reputation::Threshold.lookup(self.reputation_threshold_action, current_user.person, 
          {:tier => @tier}.merge(self.reputation_threshold_options))) && !result.success?
        flash[:warning] = result.message
        render :update do |page|
          page << "Luleka.Modal.instance().reveal('#{escape_javascript(form_flash_messages)}')"
          page << "document.fire('threshold:failure')"
          page.delay(MODAL_FLASH_DELAY) do 
            page << "Luleka.Modal.close()"
          end
        end
        flash.discard
        return false
      end
    end
    true
  end

  # threshold action to be defined in subclasses, expexted to return e.g. :leave_comment, etc.
  def reputation_threshold_action
    raise "Reputation threshold needs to be defined in reputation_threshold_action method"
  end

  # define additional options on controller level
  def reputation_threshold_options
    {}
  end
  
  # sometimes we don't want the current user to be subject to a reputation threshold limitation
  # override this method in subclasses, by default the current user's threshold will be checked
  def current_user_requires_reputation_threshold?
    true
  end

  private
  
  def set_theme_instance
    @theme_name = theme_method_name ? self.send(theme_method_name) : theme_name
    @theme = ActionView::Base::PROBONO_STYLE_THEMES[ActionView::Base::PROBONO_THEME_MAPPING[@theme_name]] if @theme_name
  end
    
end
