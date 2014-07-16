# Kases are Problems, Questions, Ideas, Praise, etc. that are managed
# by this controller
class KasesController < FrontApplicationController
  include WizardBase
  include PropertyEditor
  include FlagsControllerBase
  include TiersControllerBase
  include CommentablesControllerBase
  include VoteablesControllerBase
  include SessionsControllerBase

  helper :property_editor, :flags,
    :tiers, :organizations, :topics, :products, :locations,
    :voteables

  #--- constants
  SIDEBAR_ITEMS_COUNT = 5
  
  #--- filters
  skip_before_filter :login_required, :except => [:activate, :vote_up, :vote_down, :my, :follow, :stop_following, :my_matching, :my_responded]
  before_filter :load_location
  before_filter :load_tier
  before_filter :load_topic
  before_filter :load_kases, :only => [:index, :active, :open, :open_rewarded, :popular, :solved]
  before_filter :load_kase_or_redirect, :only => [:show, :edit, :update, :vote_up, :vote_down, :participants, :matching_people,
    :followers, :visitors, :destroy, :location]
  before_filter :can_edit, :only => :show
  before_filter :build_kase, :only => [:new, :create, :forward]
  before_filter :load_gmap_key
  before_filter :ensure_current_kase_url, :only => :show

  #--- layout
  layout :choose_layout
  
  #--- theme
  choose_theme :which_theme?

  #--- actions
  property_action :kase, :description, :partial => 'kases/description', :locals => {:label => false}

  def new
    render :template => 'kases/new'
  end
  
  def edit
    render :template => 'kases/edit'
  end
  
  def create
    if self.save_and_activate
      if request.xhr?
        render :update do |page|
          if @kase.active?
            page.redirect_to member_path([@tier, @kase])
          else
            page.redirect_to new_kase_path
          end
        end
      else
        if @kase.active?
          redirect_to member_path([@tier, @kase])
        elsif
          redirect_to new_kase_path
        end
      end
      flash.discard
      return
    end

    # invalid
    if request.xhr?
      render :update do |page|
        page.replace page_dom_id, :partial => '/kases/new'
        page.replace status_dom_id, :partial => 'layouts/front/status_navigation' if logged_in_recently?
        page << "loadmap();" if @kase.location?
        page << scroll_to_first_message_javascript
        page << observe_textarea_autogrow_javascript
      end
    else
      render :template => 'kases/new'
    end
    flash.discard
  end

  def update
    @kase.attributes = options_for_kase(params[:kase] || {})
    if @kase.save
      flash[:notice] = "%{type} successfully updated." % {:type => @kase.class.human_name}
      do_show
      
      respond_to do |format|
        format.js {
          render :update do |page|
            page.replace page_dom_id, :partial => 'kases/show'
            page << rebind_facebox_javascript(page_dom_id)
            page << close_modal_javascript
          end
          flash.discard
        }

        format.html {
          redirect_to member_path([@tier, @kase])
        }
      end
      return
    end

    # not valid
    respond_to do |format|
      format.js {
        @uses_modal = true
        render :update do |page|
          page.replace 'contentColumnModal', render(:file => 'kases/edit.html.erb')
          page << "loadmap();" if @kase.location?
          page << scroll_to_first_message_javascript
          page << observe_textarea_autogrow_javascript
        end
      }
      format.html {
        render :template => 'kases/edit'
        return
      }
    end
  end

  def index
    if @location
      render :template => 'locations/index'
      return
    else
      do_search_kases(@kases, nil, {:with_tags => true})
      render :template => 'kases/index' unless request.xhr?
    end
  end
  
  # my kases (that I have submitted...live in people controller)
  def my
    redirect_to kases_person_path(@person), :status => :moved_permanently
    return
  end

  # my kases (that I have submitted...live in people controller)
  def my_matching
    redirect_to matching_kases_person_path(@person), :status => :moved_permanently
    return
  end

  # my responded kases
  def my_responded
    redirect_to responded_kases_person_path(@person), :status => :moved_permanently
    return
  end

  # most recently active kases, sort by last activity
  def recent
    @title = "Recently Active".t
    do_search_kases(kase_class, :most_recent)
    render :template => 'kases/index' unless request.xhr?
  end
  
  # open kases, sort by last activity
  def open
    @title = action_synonym.titleize
    do_search_kases(@kases)
    render :template => 'kases/index' unless request.xhr?
  end
  
  # all open and rewarded cases
  def open_rewarded
    @title = action_synonym.titleize
    do_search_kases(@kases)
    render :template => 'kases/index' unless request.xhr?
  end
  
  # most popular kases, sort by most popular to least popular
  #
  # e.g.
  #
  #   questions  =>  frequently asked
  #   ideas      =>  ?
  #   problems   =>  ?
  #   praise     =>  ?
  # 
  def popular
    @title = "Most Popular".t
    do_search_kases(@kases)
    render :template => 'kases/index' unless request.xhr?
  end
  
  # solved 
  #
  # e.g.
  #
  #   questions  =>  answered
  #   ideas      =>  ?
  #   problems   =>  ?
  #   praise     =>  ?
  # 
  def solved
    @title = "Solved".t
    do_search_kases(@kases)
    render :template => 'kases/index' unless request.xhr?
  end

  # Ajax action to expand the view of an item in the list
  def list_item_expander
    respond_to do |format|
      format.html {
        render :nothing => true, :status => :no_content
      }
      format.js {
        @kase = Kase.find_by_permalink(params[:id])
        render :partial => 'kases/list_item_content', :object => @kase, :locals => {
          :expanded => params[:expanded].to_s.index(/1/) ? false : true
        }
      }
    end
  end

  # /kases/:id
  def show
    do_show
    respond_to do |format|
      format.html {
        render :template => 'kases/show'
      }
      format.js { 
        render :update do |page|
          page.replace page_dom_id, :partial => 'kases/show'
          page << rebind_facebox_javascript("'#{page_dom_id}'")
        end
      }
    end
  end

  # /kases/:id/location
  # TODO: obsolete
  def location
    render :partial => 'kases/location_in_place'
  end

  # put /person/:id/toggle_follow
  def toggle_follow
    respond_to do |format|
      format.html {
        render :nothing => true
        return
      }
      format.js {
        if current_user && @kase = Kase.finder(params[:id])
          if current_user.person != @kase.person
            if current_user.person.following?(@kase)
              @follow = current_user.person.stop_following(@kase)
              @kase.reload
              flash[:warning] = "You are now unfollowing this %{type}".t.to_sentence % {:type => @kase.class.human_name}
            else
              @follow = current_user.person.follow(@kase)
              @kase.reload
              flash[:warning] = "You are now following this %{type}".t.to_sentence % {:type => @kase.class.human_name}
            end
          else
            flash[:warning] = "You cannot follow your own %{type}".t.to_sentence % {:type => @kase.class.human_name}
          end
        end
        render :template => "kases/toggle_follow.js.rjs"
        return
      }
    end
  end
  
  # /kases/:id/participants
  def participants
    if request.xhr? && params[:sidebar]
      @participants = @kase.participants
      render :partial => 'shared/sidebar_profile_list', :object => @participants
      return
    else
      @people = do_search_people(@kase.participants, nil, :with_tags => !request.xhr?,
        :sort_display => true, :url => hash_for_people_path)
    end
  end

  # /kases/:id/matching_people
  def matching_people
    if request.xhr? && params[:sidebar]
      @matching_people = @kase.find_matching_people.paginate(
        :page => 1, :per_page => SIDEBAR_ITEMS_COUNT)
      render :partial => 'shared/sidebar_profile_list', :object => @matching_people
      return
    else
      @people = do_search_people(@kase.find_matching_people, nil, :with_tags => !request.xhr?,
        :sort_display => true, :url => hash_for_people_path)
      render :template => "people/index"
    end
  end
  
  # /kases/:id/followers
  def followers
    if request.xhr? && params[:sidebar]
      @followers = @kase.followers.paginate(
        :page => 1, :per_page => SIDEBAR_ITEMS_COUNT)
      render :partial => 'shared/sidebar_profile_list', :object => @followers
      return
    else
      @people = do_search_people(@kase.find_matching_people, nil, :with_tags => !request.xhr?,
        :sort_display => true, :url => hash_for_people_path)
    end
  end
  
  # /kases/:id/visitors
  def visitors
    if request.xhr? && params[:sidebar]
      @visitors = @kase.viewers.paginate(
        :order => "people.id", :page => 1, :per_page => SIDEBAR_ITEMS_COUNT)
      render :partial => 'shared/sidebar_profile_list', :object => @visitors
      return
    else
      @people = do_search_people(@kase.find_matching_people, nil, :with_tags => !request.xhr?,
        :sort_display => true, :url => hash_for_people_path)
    end
  end
  
  def destroy
    if current_user && @kase && @kase.person == current_user.person
      @kase.delete!
      flash[:notice] = "You have successfully removed the %{type} about \"%{title}\".".t.to_sentence % {
        :type => @kase.class.human_name.titleize,
        :title => @kase.title
      }
      redirect_to collection_path([@kase.tier, @kase])
    else
      render :nothing => true
    end
  end

  # kases/select_location
  def select_location
    if request.xhr?
      render :partial => 'kases/select_location', :locals => {:open => true, :delay => false}
    else
      render :nothing => true
    end
  end
  
  # rendered from lookup partial
  # kases/lookup/:title
  def lookup
    title = params[:kase][:title]
    klass = kase_class.klass(params[:kase][:kind]) || kase_class
    
    @kases = if @tier
      @tier.kases.find(:all, klass.find_options_for_query(title, :limit => 5))
    else
      klass.find_by_query(:all, title, :limit => 5)
    end
    
    if @kases.blank?
      render :update do |page|
        page.redirect_to(member_path([@tier, @topic, klass], :new, {:title => title}))
      end
      return
    else
      # return lookup results
      render :update do |page|
        page.replace_html dom_class(Kase, :lookup_results), :partial => 'kases/lookup_results'
        page << probono_visual_effect(:blind_down, dom_class(Kase, :lookup_results))
  
        page[dom_class(Kase, :lookup_spinner)].hide
        page[dom_class(Kase, :lookup_start)].show
        page[dom_class(Kase, :lookup_cancel)].show
        
        page.select("##{dom_class(Kase, :lookup_start)} a").first.write_attribute('href',
          member_path([@tier, @topic, klass], :new, {:title => title}))
      end
    end
  end
  
  def activate
    if @kase = Kase.find_by_activation_code(params[:id])
      @kase.person = @person

      if @kase.activate! && @kase.active?
        flash[:notice] = (PUBLISH_SUCCESS.t % {:object => @kase.class.human_name}).to_sentence
        redirect_to member_path([@kase.tier, @kase])
        return
      end
    end
    flash[:error] = (PUBLISH_FAIL.t % {:object => (@kase.class || Kase).human_name}).to_sentence
    redirect_to '/'
  end

  protected

  def ssl_required?
    false
  end
  
  def ssl_allowed?
    request.xhr? ? true : false
  end

  # returns the class 
  def kase_class
    Kase
  end
  helper_method :kase_class

  # returns the type of the kind, e.g. :problem
  def kase_type
    kase_class.kind if kase_class
  end

  def tier_class
    @tier_class || Tier
  end
  
  def topic_class
    @topic_class || Topic
  end

  # used when routes /organizations/xxx/kases... in before_filter is loaded
  def load_tier
    if id = tier_param_id
      @tier = Tier.find_by_permalink_and_region_and_active(id)
      @tier_class = @tier.class if @tier
    end
  end

  # used when routes /organizations/luleka/products/xxx/kases... in before_filter is loaded
  def load_topic
    if @tier && id = topic_param_id
      @topic = @tier.topics.find_by_permalink_and_region_and_active(id)
      @topic_class = @topic.class if @topic
    end
  end
  
  # /locations/san-francisco/kases
  def load_location
    @locations = []
    if params[:location_id]
      if @location = GeoKit::Geocoders::MultiGeocoder.geocode(Location.unescape(params[:location_id]))
        if @location.success
          load_gmap_key
          @radius = params[:r].to_i if params[:r]
          @radius ||= LOCATIONS_RADIUS
        else
          @location = nil unless @location.success
        end
      end
    end
    true
  end
  
  def load_kase_or_redirect
    @kase = kase_class.finder(params[:id]) if params[:id]
    @kase.expire! if @kase
    if @kase && @kase.visible?
      # redirect to http://xxx.luleka.com/problem/yyy
      if @kase.tier != @tier && !request.xhr?
        redirect_to member_path([@kase.tier, @kase]), :status => :moved_permanently
        return
      end
    else
      redirect_to collection_path([@tier, @topic, kase_class]), :status => :moved_permanently
      return
    end
  end
  
  # checks to see if permalink is still current, if not redirect to current slug
  def ensure_current_kase_url
    if (@tier && !@tier.friendly_id_status.best?) || (@topic && !@topic.friendly_id_status.best?) || 
        (@kase && !@kase.friendly_id_status.best?)
      redirect_to member_url([@tier, @topic, @kase]), :status => :moved_permanently
    end
  end

  def load_kases
    location_options = @location ? {
      :origin => @location,
      :within => @radius,
      :limit => LOCATIONS_LIMIT,
      :conditions => "kases.lat IS NOT NULL AND kases.lng IS NOT NULL"
    } : {}
    
    kase_options = kase_class.find_options_for_type(case action_name
      when /open_rewarded/ then kase_class.find_options_for_open_rewarded
      when /open/ then kase_class.find_options_for_open
      when /active/, /recent/ then kase_class.find_options_for_recent
      when /popular/ then kase_class.find_options_for_popular
      when /solved/ then kase_class.find_options_for_solved
      else kase_class.find_options_for_visible
    end)
    
    if @tier && params[:tag_id]
      # /tags/:tag_id/organization/:organization_id/kases/all/location
      @kases = kase_class.find_tagged_with(Tag.parse_param(params[:tag_id]), {
        :include => :kontexts,
        :conditions => ["kontexts.tier_id = ?", @tier.id]
      }.merge_finder_options(kase_options).merge_finder_options(location_options))
    elsif @tier
      # /organization/:organization_id/kases/all/location
      @kases = @tier.kases.find(:all, kase_options.merge_finder_options(location_options))
    elsif params[:tag_id]  
      # /tags/:tag_id/kases/all/location
      @kases = kase_class.find_tagged_with(Tag.parse_param(params[:tag_id]),
        kase_options.merge_finder_options(location_options))
    else
      # /kases or /locations/:location_id/kases
      @kases = kase_class.find(:all, kase_options.merge_finder_options(location_options))
    end
    @kases.sort_by_distance_from(@location) if @kases && @location
    @locations += @kases if @location && !@kases.blank?
    true
  end

  # current_case=
  # Saves the issue.id in session :ceating_issue
  def current_kase=(kase)
    @cached_kase = kase ? kase.id : nil
    session[:kase] = @cached_kase
  end

  # current_kase
  def current_kase
    @cached_kase = kase_class.find_by_id(session[:kase]) unless @cached_kase
    @cached_kase
  end
  
  # builds a new kase based on params and options passed in
  # may also build a @user if necessary
  def build_kase(options={}, user_options={})
    # build kase
    @kase = Kase.new(options_for_kase(options))

    # check user
    unless logged_in?
      signin_login = params[:user].delete(:signin_login) if params[:user]
      if @kase.authenticate_with_signin?
        @user = create_session_without_render(signin_login)
        if @user
          @kase.person = @person = @user.person
        end
      elsif @kase.authenticate_with_signup?
        @user = User.new((params[:user] || {}).symbolize_keys.merge(user_options.symbolize_keys))
        @user.guest!
        @kase.sender_email = @user.email
      else
        # by default set authentication type to signin
        @kase.authentication_type = "signin"
      end
    end
    @kase
  end
  
  # validates @kase and if not logged in the @user as well
  def valid?
    result = @kase.valid?
    unless logged_in?
      if @kase.authenticate_with_signin?
        # if we were authenticated, we would not end up here, so not good!
        result = false
      elsif @kase.authenticate_with_signup?
        result = @user.new_record? && @user.valid? && result
      end
    end
    result
  end

  # save all necessary instances, including @user if necessary
  def save_and_activate
    result = self.valid?
    if result && !logged_in? 
      if @kase.authenticate_with_signin?
        # nothing
      elsif @kase.authenticate_with_signup?
        result = result && @user.new_record? && @user.valid?
      end
    end
    if result = result && @kase.save
      @user.register! if @kase.authenticate_with_signup? && @user.valid?
      @kase.activate!
      flash[:info] = if @kase.active?
        (PUBLISH_SUCCESS.t % {:object => @kase.class.human_name}).to_sentence
      elsif @kase.created?
        (CREATE_SUCCESS.t % {:object => @kase.class.human_name}).to_sentence
      end
    end
    result
  end
  
  # takes the params and returns a hash for kase to instantiate
  def options_for_kase(options={})
    options = options.symbolize_keys
    options.reverse_merge!({:language_code => Utility.language_code || 'en', 
      :country_code => Utility.country_code || 'US'})
    options = (params[:kase] || {}).symbolize_keys.merge({:kind => params[:kind], :title => params[:title]}.reject {|k,v| v.blank?}.merge(options))
    
    # determine kind
    kind = case options[:kind] || self.kase_type.to_s
      when /problem/ then :problem
      when /idea/ then :idea
      when /praise/ then :praise
      when /question/ then :question
    end
    options.delete(:kind)
    
    options.merge!({
      :person => @person,
      :tier => @tier,
      :topics => [@topic].compact,
      :type => kind
    }.reject {|k,v| v.blank?})
    options
  end
  
  def redirect_to_kases_path
    redirect_to kases_path
  end

  # assembles a path similar to kase_path 
  #
  # e.g.
  #
  #   /kases/:id
  #   /tiers/:tier_id/kases/:id
  #   /tiers/:tier_id/topics/:topic_id/kases/:id
  #
  def kase_path(kase)
    selector = []
    selector << @tier if @tier
    selector << @topic if @topic
    selector << kase
    member_path(selector)
  end
  helper_method :kase_path

  def which_theme?
    [:new, :create, :forward, :edit].include?(self.action_name.to_sym) ? :profile : :issue
  end

  # dom id for the kase main content and sidebar
  def page_dom_id
    dom_class(Kase, :page)
  end
  helper_method :page_dom_id

  # returns an alternative lowercase translateable name for an action 
  # to be overidden in supbclasses
  #
  # e.g.
  #
  #  QuestionsController.popular => "frequently asked" 
  #
  def action_synonym(name=self.action_name)
    case "#{name}"
      when /new/, /create/ then "start new".t
      when /open_rewarded/ then "open rewarded".t
      when /open/ then "need attention".t
      when /index/ then "overview".t
      else "#{name}".gsub(/_/, '').t
    end
  end
  helper_method :action_synonym

  # show the form as expandable accordion, starting with the title
  def accordion?
    !!("#{params[:accordion]}" =~ /^(1|true)/)
  end
  helper_method :accordion?

  # sets the @can_edit instance variable if the kase is the logged in user's 
  def can_edit
    @can_edit = Reputation::Threshold.valid?(:edit_post, current_user.person, :tier => @tier) if logged_in?
  end

  def do_show
    # responses
    @responses = @kase.responses.visible
    @response = @kase.build_response(@person, {})
    
    # tier / topics
    @tier ||= @kase.tier
    @topics ||= @kase.topics unless !@topics.blank?

    # matching kases
    @matching_kases = @kase.find_matching_kases

    # visitors
    @kase.visit(@person ? @person : session.session_id) unless request_from_robot?

    # participants
    @participants = @kase.participants

    # employees
    @employees = (@tier.employees & @participants) if @tier && @tier.is_a?(Organization)
  end
  
  private
  
  # Helper to choose a layout based on criteria
  def choose_layout
    request.xhr? && uses_modal? ? false : super
  end

end
