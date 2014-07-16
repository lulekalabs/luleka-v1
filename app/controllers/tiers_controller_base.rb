# provides controller helpers for TiersController and TopicsController
module TiersControllerBase
  def self.included(base)
    base.extend(ClassMethods)
    base.send :helper_method,
      :tier_class, :tier_type, :tier_param,
      :topic_class, :topic_type, :topic_param
  end
  
  module ClassMethods
  end

  protected

  MESSAGE_POST_SUCCESS = "Thanks for adding \"%{name}\". We will have to double check the details before making it public. This may take 1-3 business days."
  
  def tier_class
    raise 'override tier_class in controller'
  end
  
  # used for instantiating a tier, e.g. Tier.new :type => tier_type
  def tier_type
    tier_class.kind if tier_class
  end
  
  # used for querying params, e.g. params[tier_param]
  def tier_param
    tier_type
  end
  
  def topic_class
    raise 'override topic_class in controller'
  end
  
  def topic_type
    topic_class.kind if topic_class
  end
  
  # used for querying params, e.g. params[tier_param]
  def topic_param
    topic_type
  end
  
  # pagination search tiers
  def do_search_tiers(class_or_record=nil, method=nil, options={})
    @tiers = do_search(
      class_or_record || tier_class.find_all_by_region_and_active(
        Utility.country_code, true, :include => [{:tags => :taggings}]),
      nil, {
        :partial => 'tiers/list_item_content',
        :url => hash_for_collection_path(tier_class),
        :sort => {'tiers.activated_at' => "Recently Added".t}
      }.merge(options)
    )
  end

  # search recent active tiers for sidebar
  def do_search_most_recent_tiers(options={})
    @recent_tiers = tier_class.recent({:limit => 5}.merge(options))
  end

  # search popular tiers for sidebar
  def do_search_most_popular_tiers(options={})
    @popular_tiers = tier_class.popular({:limit => 5}.merge(options))
  end

  def do_search_topics(class_or_record=nil, method=nil, options={})
    @topics = do_search(
      class_or_record || @tier.topics.active(:include => :kases, :order => 'kases.updated_at DESC'),
      nil, {
        :partial => 'topics/list_item_content',
        :url => hash_for_collection_path([@tier, topic_class]),
        :sort => {'topics.activated_at' => "Recently Added".t}
      }.merge(options)
    )
  end

  def do_search_popular_topics(tier=@tier, options={})
    @popular_topics = tier.popular_topics({:limit => 5}.merge(options)) if tier
  end

  def do_search_recent_topics(tier=@tier, options={})
    @recent_topics = tier.recent_topics({:limit => 5}.merge(options)) if tier
  end
  
  # checks the params hash for any occurances of a tier "like" id or
  # returns nil if there is none
  # e.g. :organization_id, :company_id, :agency_id, etc.
  def tier_param_id(klass=tier_class)
    klass.self_and_subclass_param_ids.each {|id| return params[id] if params[id]}
    return params[:tier_id] if params[:tier_id]
    nil
  end

  # checks the params hash for any occurances of a topic "like" id or
  # returns nil if there is none
  # e.g. :topic_id, :product_id, :service_id
  def topic_param_id(klass=topic_class)
    klass.self_and_subclass_param_ids.each {|id| return params[id] if params[id]}
    nil
  end
  
  # hash key for session id
  def tier_session_param
    :tier_id
  end
  
  # Accesses the current tier from the session. 
  # Future calls avoid the database because nil is not equal to false.
  def current_tier
    @current_tier ||= load_tier_from_session unless @current_tier == false
  end

  # Store the given invitation in the session.
  def current_tier=(new_tier)
    session[tier_session_param] = new_tier ? new_tier.id : nil
    @current_tier = new_tier || false
  end
  
  def load_tier_from_session
    self.current_tier = Tier.find_by_id(session[tier_session_param]) if session[tier_session_param]
  end

  # used in before filter
  def clear_current_tier
    self.current_tier = nil
  end

end
