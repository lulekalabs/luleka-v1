# TopicsController is the super controller for all products, services, etc. or
# subclasses of Topics
class TopicsController < FrontApplicationController
  include TiersControllerBase
  helper :tiers, :products, :kases
  
  #--- filters
  skip_before_filter :login_required, :except => [:create]
  skip_before_filter :load_current_user_and_person, :only => :new
  before_filter :load_tier
  before_filter :load_topic, :only => :show
  before_filter :ensure_current_url, :only => :show
  
  #--- actions

  # /organizations/luleka/products
  def index
    do_search_topics nil, nil, :with_tags => true
    do_search_popular_topics
    render :template => 'topics/index' unless request.xhr?
  end
  
  # /organizations/luleka/products/service_fee
  def show
    do_search_kases(@topic.kases.most_recent, nil, :with_tags => true)
    do_search_popular_topics
    do_search_recent_topics
    render :template => 'topics/show'
  end
  
  # e.g. /organizations/luleka/products/new
  def new
    @topic = build_with {}
    render :template => 'topics/new'
  end
  
  def create
    @topic = build_with(params[topic_param])
    if @topic.save
      @topic.register!
      flash[:warning] = MESSAGE_POST_SUCCESS.t % {
        :name => @topic.name
      }
      redirect_to collection_path(@tier)
      return
    end
    render :template => 'topics/new'
  end
  
  def recent
    @topics = do_search_topics @tier.recent_topics, nil, :with_tags => true
    do_search_popular_topics
    render :template => 'topics/index' unless request.xhr?
  end
  
  def popular
    do_search_topics @tier.popular_topics, nil, :with_tags => true
    do_search_popular_topics
    render :template => 'topics/index' unless request.xhr?
  end

  # expands or retracts each list item using the (+) and (x) icons
  def list_item_expander
    respond_to do |format|
      format.html {
        render :nothing => true, :status => :no_content
      }
      format.js {
        @topic = self.load_topic
        render :partial => 'topics/list_item_content', :object => @topic, :locals => {
          :expanded => params[:expanded].to_s.index(/1/) ? false : true
        }
      }
    end
  end

  protected

  def tier_class
    @tier_class || Tier
  end
  
  def topic_class
    Topic
  end
  
  # instantiates product depending on topic_class
  def build_with(options={})
    options = {
      :kind => :topic,
      :tier => @tier,
      :site_url => 'http://',
      :created_by => @person
    }.merge(options.symbolize_keys)
    topic_class.new(options)
  end
  
  # used when routes /categories/xxx/cases in before_filter is loaded
  def load_tier
    if id = tier_param_id || params[:tier_id]
      @tier = Tier.find_by_permalink_and_region_and_active(id)
      @tier_class = @tier.class if @tier
    end
  end

  # used when routes /categories/xxx/cases in before_filter is loaded
  def load_topic
    if @tier && params[:id]
      @topic = @tier.topics.find_by_permalink_and_region_and_active(params[:id])
    end
  end
  
  # checks to see if permalink is still current, if not redirect to current slug
  def ensure_current_url
    return true # TODO: enable for friendly_id 3.x
    redirect_to member_url([@tier, @topic]), :status => :moved_permanently if (@tier && @tier.has_better_id?) || (@topic && @topic.has_better_id?)
  end
  
  # returns an alternative lowercase translateable name for an action 
  # to be overidden in subclasses
  def action_synonym(name=self.action_name)
    case "#{name}"
    when /new/, /create/ then "start new topic".t
    when /index/, /show/ then "overview".t
    when /active/, /recent/ then "recently active".t
    else "#{name}".gsub(/_/, '').t
    end
  end
  helper_method :action_synonym
  
end