# Is the base application controller for all widgets
class Widgets::WidgetApplicationController < ApplicationController
  include TiersControllerBase
  helper 'front_tag'

  #--- filters 
  prepend_before_filter :set_locale
  
  protected
  
  def ssl_required?
    false
  end
  
  def ssl_allowed?
    true
  end

  def user_class
    User
  end
  
  def user_session_param
    :user_id
  end
  
  def return_to_param
    :return_to
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
  
  # loads topics if there is a @tier but no @topic selected
  def load_topics
    if @tier && !@topic
      @topics = @tier.topics.active
    end
  end

  # override and do nothing for widgets
  def store_previous
  end
  
end
