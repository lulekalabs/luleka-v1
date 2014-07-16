# Manages the memberships of Tier or Topic
class MembersController < FrontApplicationController
  include TiersControllerBase
  helper :users, :partners, :property_editor, :kases, :flags,
    :tiers, :organizations, :topics, :products, :locations

  #--- filters
  skip_before_filter :login_required
  before_filter :load_tier
  before_filter :load_topic

  #--- theme
  set_theme :profile

  #--- actions
  
  # renders a list of all the user's accepted contacts (friends)
  def index
    @title = "#{[@tier, @topic].compact.map(&:name).join(' ')} #{ @tier.members_t}".firstcase
    @people = do_search_people(@topic || @tier, :members, :with_tags => !request.xhr?,
      :sort => false, :sort_display => false, 
      :url => hash_for_collection_path([@tier, @topic, "members"]))
    render :template => 'people/index' unless request.xhr?
  end

  protected

  def tier_class
    @tier_class || Tier
  end
  
  def topic_class
    @topic_class || Topic
  end
  
  # used when routes /tiers/xxx/members... in before_filter is loaded
  # tier :id is required otherwise, throws exception
  def load_tier
    @tier = Tier.find_by_permalink_and_region_and_active(tier_param_id)
    @tier_class = @tier.class if @tier
  end

  # used when routes /tiers/luleka/products/xxx/members... in before_filter is loaded
  def load_topic
    if @tier && id = topic_param_id
      @topic = @tier.topics.find_by_permalink_and_region_and_active(id)
      @topic_class = @topic.class if @topic
    end
  end

end
