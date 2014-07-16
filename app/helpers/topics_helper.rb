module TopicsHelper

  def collect_topic_languages_for_select(selected=nil)
    collect_supported_languages_for_select(with_select=true)
  end
  
  def collect_topic_countries_for_select(selected=nil)
    collect_countries_for_select(false, "Multiple regions".t)
  end
  
  # returns the image path for the given topic, versions :thumb, :profile, :invoice
  def topic_image_path(topic, options={})
    tier_image_path(topic, options)
  end
  
  # returns image tag for the given topic, :name => :thumb | :profile | :invoice
  def topic_image_tag(topic, options={})
    tier_image_tag(topic, options)
  end
  
  # link with topic image
  def topic_image_link_to(topic, options={})
    link_to(topic_image_tag(topic, options), member_path([topic.tier, topic])) if topic
  end
  
  def overview_list_topic_kases_count(topic, options={})
    html = div_tag("#{topic.kases_count}", :class => 'first stats')
    if topic.kases_count > 0
      html << div_tag(link_to(I18n.t("concern", :count => topic.kases_count), 
        collection_path([@tier, topic, Kase]), 
          :title => "#{h(topic.name)} #{"cases".t}"), :class => 'second')
    else
      html << div_tag(I18n.t("concern", :count => topic.kases_count), 
        :class => 'second')
    end
    overview_list_item(html, options)
  end
  
  def overview_list_topic_people_count(topic, options={})
    html = div_tag("#{topic.people_count}", :class => 'first stats')
    if topic.people_count > 0
      html << div_tag(link_to(I18n.t("person", :count => topic.people_count), collection_path([@tier, topic, Person]),
        :title => "#{h(topic.name)} #{I18n.t("person", :count => 2)}"), :class => 'second')
    else
      html << div_tag(I18n.t("person", :count => topic.people_count), :class => 'second')
    end
    overview_list_item(html, options)
  end

end
