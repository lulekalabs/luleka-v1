# This controller serves the home page and inherits from page
class HomePagesController < PagesController
  helper :people, :tiers, :topics, :kases
  
  #--- actions
  
  def index
    render :template => nl? ? "home_pages/nl/index" : "home_pages/index"
  end
  
  def show
    render :template => 'home_pages/index'
  end
  
  def widget
    respond_to do |format|
      format.html { render :nothing => true }
      format.js { render :partial => "widget", :locals => {:update => true} }
    end
  end

  def widget_avatar
    debugger
    respond_to do |format|
      format.html { render :nothing => true }
      format.js { 
        if logged_in?
          render :inline => "<%= image_tag(image_avatar_path(current_user.person, {:name => :profile})) %>"
        else
          render :inline => "<%= image_tag(image_avatar_path(nil, {:name => :profile})) %>"
          #render :nothing => true, :status => 301
        end
      }
    end
  end
  
  protected

  # override from SessionsControllerBase
  def remember_me?
    false
  end
  
  def load_page
    @page = case params[:id]
    when /why/ then :why
    when /how/ then :how
    else :what
    end
  end
  
  def welcome_fragment_cache_key
    "welcome-#{I18n.locale}"
  end
  helper_method :welcome_fragment_cache_key
  
  def featured_fragment_cache_key
    "featured-#{I18n.locale}"
  end
  helper_method :featured_fragment_cache_key

  def summary_fragment_cache_key
    "summary-#{I18n.locale}"
  end
  helper_method :summary_fragment_cache_key

  def choose_layout
    nl? ? 'nl/front' : 'front'
  end
  
end
