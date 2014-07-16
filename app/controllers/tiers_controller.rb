# TiersController is the super controller for all objects handling tiers 
# and their subclasses, e.g. OrganizationsController, CompaniesController, 
# GroupsController, etc.
class TiersController < FrontApplicationController
  include WizardBase
  include TiersControllerBase
  helper :topics, :organizations, :kases

  #--- filters
  skip_before_filter :login_required, :except => [:create]
  skip_before_filter :load_current_user_and_person, :only => :new
  before_filter :load_tier, :only => [:index, :show, :claim]
  before_filter :load_current_tier_or_redirect, :only => :complete
  before_filter :ensure_current_url, :only => :show
  before_filter :clear_current_tier, :except => :complete
  after_filter :clear_current_tier, :only => :complete
  
  #--- layout
  layout :choose_layout

  #--- theme
  choose_theme :which_theme?

  #--- wizard
  wizard do |step|
    step.add :new, "Register", :required => true, :link => true
    step.add :complete, "Complete", :required => true, :link => false
  end
  
  #--- actions
  
  def plans
    @features = [
      ["Best for".tn(:tiers), "Businesses or Groups just getting started".tn(:tiers), "Businesses that need to moderate community content ".tn(:tiers), "Businesses that need to manage and extend their brand ".tn(:tiers)],
      ["Employee Identification".tn(:tiers), true, true, true],
      ["Official Agents".tn(:tiers), false, "5", "unlimited".tn(:tiers)],
      ["Administrative Control".tn(:tiers), true, true, true],
      ["Hosted on Your URL".tn(:tiers), false, false, true],
      ["Management View".tn(:tiers), true, true, true],
      ["Widgets for your Site".tn(:tiers), "limited".t, true, true],
      ["Moderation Tools".tn(:tiers), false, true, true],
      ["Brand Analytics".tn(:tiers), false, false, true],
      ["Commercial API Access".tn(:tiers), false, true, true],
      ["Custom Visual Design".tn(:tiers), false, false, true],
      ["Technical Support".tn(:tiers), "Community Support only".tn(:tiers), "Email Support".tn(:tiers), "Phone/Email Support".tn(:tiers)]
    ]
  end
  
  def index
    @tier ? do_show_and_render : do_index_and_render
  end

  def show
    do_show_and_render
  end

  # expands or retracts each list item using the (+) and (x) icons
  def list_item_expander
    respond_to do |format|
      format.html {
        render :nothing => true, :status => :no_content
      }
      format.js {
        @tier = Tier.finder(params[:id])
        render :partial => 'tiers/list_item_content', :object => @tier, :locals => {
          :expanded => params[:expanded].to_s.index(/1/) ? false : true
        }
      }
    end
  end
  
  def new
    @tier ||= build_with(
      :name => params[:name] ? params[:name] : nil,
      :site_name => params[:name] ? params[:name].downcase : nil,
      :kind => :organization
    )
    render :template => 'tiers/new'
  end
  
  def create
    @tier = build_with(params[:tier] || {})

    if @tier.save
      @tier.register!
      self.current_tier = @tier
      flash[:warning] = "We will have to double check the details before making your community public. This may take 1-3 business days.".t

      if request.xhr?
        render :update do |page|
          page.redirect_to complete_tiers_path
        end
      else
        redirect_to complete_tiers_path
      end
      return
    end
    
    # invalid
    if request.xhr?
      render :update do |page|
        page.replace page_dom_id, :partial => '/tiers/new'
        page << scroll_to_first_message_javascript
        page << observe_textarea_autogrow_javascript
      end
    else
      render :template => 'tiers/new'
    end
  end
  
  def complete
  end
  
  def recent
    do_search_most_recent_tiers
    do_search_most_popular_tiers
    do_search_tiers(tier_class.find_all_recent)
    render :template => 'tiers/index' unless request.xhr?
  end
  
  def popular
    do_search_most_recent_tiers
    do_search_most_popular_tiers
    do_search_tiers(tier_class.find_all_popular)
    render :template => 'tiers/index' unless request.xhr?
  end
  
  # loads @tier claimings new if organization
  def claim
    if @tier.is_a?(Organization)
      redirect_to member_path([@tier, :claiming], :new)
    elsif @tier
      redirect_to tier_root_path(@tier)
    else
      redirect_to "/"
    end
  end
  
  # search by name and renders results to choose from
  # used from _select_organization_and_products
  def search_field
    respond_to do |format|
      format.html {render :nothing => true}
      format.js {
        @object_name = :kase
        @tag_list = if params[:added]
          @tag_name = params[:added]
          ([params[:added]] + [params[:kase] ? params[:kase][:tag_list] : nil]).flatten.reject(&:blank?).uniq
        elsif params[:removed]
          @tag_name = nil # params[:removed]
          ([params[:kase] ? params[:kase][:tag_list] : nil] - [params[:removed]]).flatten.reject(&:blank?).uniq
        end
        
        @selected_tier = params[:kase] && !params[:kase][:tier_id].blank? ?
          params[:kase][:tier_id].to_i :
            nil
            
        @selected_topics = params[:kase] && !params[:kase][:topic_ids].blank? ? 
          [params[:kase][:topic_ids]].flatten.reject(&:blank?).map(&:to_i) :
            nil
        
        @tiers = Tier.active.current_region.most_popular.find_deeply_tagged_with(@tag_list, 
          :conditions => (@selected_tier_id ? ["tiers.id = ?", @selected_tier_id] : nil),
            :include => :select_topics)
      }
    end
  end

  # search by name and renders results to choose from
  def select_field
    respond_to do |format|
      format.html {render :nothing => true}
      format.js {
        @organization = Organization.find_by_id(params[:id].to_i)
        @products = @organization.products.active.current_region if @organization
        @object_name = :kase
        @method_name = :product_ids,
        @selected = []
      }
    end
  end
  
  protected
  
  def tier_class
    Tier
  end
  
  def topic_class
    tier_class.topic_class
  end
  
  # instantiates Tier object depending on :kind hash value and set defaults
  def build_with(options={})
    options = {
      :kind => self.tier_type,
      :site_url => 'http://',
      :created_by => @person,
      :owner_email => current_user ? current_user.email : "",
      :language_code => current_locale ? "#{I18n.locale_language(current_locale)}" : "en"
    }.merge(options.symbolize_keys)
    options[:type] = options[:kind].blank? ? self.tier_type : options[:kind].to_sym

    result = tier_class.new(options)
    result.single_geo_location = result.single_geo_location  # make sure we reset country code if single geo loc is false
    result
  end
  
  # used by before_filter to load a @tier from params[:id] and 
  # assigning it to tier_instance_name instance
  def load_tier
    if id = params[:id] || params[:tier_id]
      if @tier = tier_class.find_by_permalink_and_region_and_active(id, Utility.country_code, nil)
        unless @tier.active?
          flash[:warning] = "\"%{name}\" is not active, yet. Please check back with us soon.".t % {:name => @tier.name}
          redirect_to collection_path(tier_class)
          return false
        end
      else
        flash[:error] = "\"%{name}\" not found. Would you like to %{add_it_now}?".t % {
          :name => params[:id],
          :add_it_now => "<a href=\"#{member_path(tier_class, :new)}\">#{"add it now".t}</a>"
        }
        redirect_to collection_path(tier_class)
        return false
      end
    end
    true
  end

  # returns an alternative lowercase translateable name for an action 
  # to be overidden in subclasses
  def action_synonym(name=self.action_name)
    case "#{name}"
    when /index/, /show/ then "overview".t
    when /active/ then "recently active".t
    else "#{name}".gsub(/_/, '').t
    end
  end
  helper_method :action_synonym
  
  # used as before filter to load current tier for complete wizard step
  def load_current_tier_or_redirect
    unless @tier = current_tier
      redirect_to new_tier_path
      return false
    end
    true
  end

  # checks to see if permalink is still current, if not redirect to current slug
  def ensure_current_url
    return true # TODO: enable for friendly_id 3.x
    redirect_to @tier, :status => :moved_permanently if @tier && @tier.has_better_id?
  end

  # override from front_application_controller
  def choose_layout
    %w(new create complete).include?(action_name) ? 'front' : super
  end

  # dom id for the kase main content and sidebar
  def page_dom_id
    dom_class(Tier, :page)
  end
  helper_method :page_dom_id

  # returns the theme name
  def which_theme?
    :profile
  end

  def tier_plans_fragment_cache_key
    "tier-plans-#{I18n.locale}"
  end
  helper_method :tier_plans_fragment_cache_key

  # renders page with a list of all active tiers
  def do_index_and_render
    do_search_most_recent_tiers
    do_search_most_popular_tiers
    do_search_tiers
    render :template => 'tiers/index' unless request.xhr?
  end

  # renders a page with a list of all kases of @tier
  def do_show_and_render
    do_search_kases(@tier.kases.most_recent, nil, :with_tags => true)
    do_search_popular_topics
    do_search_recent_topics
    @participants = @tier.people
    
    render :template => 'tiers/show' unless performed?
  end
  
end
