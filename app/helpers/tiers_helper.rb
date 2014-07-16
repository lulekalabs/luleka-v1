module TiersHelper

  def collect_operation_countries_for_select(selected=nil)
    collect_countries_for_select(false, "Worldwide".t)
  end

  # returns the image path for the given tier, versions :thumb, :profile, :invoice
  def tier_image_path(tier, options={})
    defaults = {:name => :thumb}
    options = defaults.merge(options).symbolize_keys
    version = options.delete(:name)
    source = options.delete(:source)
    return source if source

    if tier.image.file?
      source = tier.image.url(version)
    end
    source = case version.to_s
      when /thumb/ then image_path 'icons/tiers/default_thumb.png'
      when /profile/ then image_path 'icons/tiers/default_profile.png'
      when /invoice/ then image_path 'icons/tiers/default_invoice.png'
    end unless source
    source
  end
  
  # returns image tag for the given tier, :name => :thumb | :profile | :invoice
  def tier_image_tag(tier, options={})
    defaults = case options[:name].to_s
      when /profile/ then {:size => '113x113', :title => "#{h(tier.name)}", :alt => h(tier.name)}
      else {:size => '35x35', :title => "#{h(tier.name)}", :alt => h(tier.name)}
    end
    options = defaults.merge(options).symbolize_keys
    image_tag(tier_image_path(tier, options), options)
  end
  
  # link with tier image
  def tier_image_link_to(tier, options={}, html_options={})
    link_to(tier_image_tag(tier, options), tier_path(tier), 
      {:title => h(tier.name)}.merge(html_options)) if tier
  end

  # returns the logo path for the given tier
  def tier_logo_path(tier, options={})
    version = options.delete(:name)
    source = options.delete(:source)
    return source if source
    tier.logo.url("normal") if tier.logo.file?
  end
  
  # returns image tag for the given tier, :name => :thumb | :profile | :invoice
  def tier_logo_tag(tier, options={}, html_options={})
    html_options = {:size => "300x66", :title => h(tier.name), :alt => h(tier.name)}.merge(html_options).symbolize_keys
    if path = tier_logo_path(tier, options)
      image_tag(path, html_options)
    end
  end
  
  # returns a string with links, like
  #   '12 cases powered by a growing number of people'
  #   '5 cases powered by thousands of people with help from 2 employees'
  #   'No cases, yet, associate yourself.
  def kases_powered_by_people_count_in_words(tier_or_topic)
    if tier_or_topic.respond_to?(:kases) && (kases_count = tier_or_topic.kases_count) > 0
      people_string = case kases_count
        when 0..99 then "a growing number of people".t
        when 100..999 then "hundreds of people".t
        else "thousands of people".t
      end
      if tier_or_topic.respond_to?(:members) && tier_or_topic.members_count > 0
        "%{kases} powered by %{people} with help from {members}".t % {
          :kases => link_to(I18n.t("{{count}} concern", :count => kases_count), collection_path([tier_or_topic, Kase]), :title => "#{h(tier_or_topic.name)} #{Kase.human_name(:count => kases_count)}"),
          :people => link_to(people_string, collection_path([tier_or_topic, Person]), :title => "#{h(tier_or_topic.name)} #{Person.human_name(:count => 2)}"),
          :members => link_to(I18n.t(tier_or_topic.is_a?(Organization) ? "{{count}} employee" : "{{count}} member", :count =>  tier_or_topic.members_count), collection_path([tier_or_topic, "members"]), 
            :title => "#{h(tier_or_topic.name)} #{tier_or_topic.is_a?(Organization) ? Employment.human_name(:count => tier_or_topic.members_count) : Membership.human_name(:count => tier_or_topic.members_count)}")
        }
      else
        "%{kases} powered by %{people}".t % {
          :kases => link_to(I18n.t("{{count}} concern", :count => kases_count), 
            collection_path([tier_or_topic.is_a?(Topic) ? [@tier, tier_or_topic] : tier_or_topic, :kases].flatten.uniq)),
          :people => link_to(people_string, 
            collection_path([tier_or_topic.is_a?(Topic) ? [@tier, tier_or_topic] : tier_or_topic, :people].flatten.uniq)),
        }
      end
    else
      "No concerns, yet. %{add}?".t % {:add => link_to("Add now".t, member_path([@tier, tier_or_topic, :kase].uniq, :new),
        :title => "Add now".t)}
    end
  end
  
  # e.g.
  # '23 products'
  # 'No products supported'
  def topics_count_supported_in_words(tier)
    if tier && (topics_count = tier.topics_count)
      topic_class = Topic
      "%{topics_count} supported".t % {:topics_count => link_to(
        I18n.t("{{count}} topic", :count => topics_count).firstcase, collection_path([tier, Topic])
      )}
    end
  end

  # helper for radio/check_box fields to determine if the organization
  # is equal to the selected id or instance of organization
  def selected_tier_equal?(selected, tier)
    if selected.is_a?(Array)
      return false if selected.empty?
      if selected.first.is_a?(Tier)
        return selected.include?(tier)
      else
        return selected.map(&:to_i).include?(tier.id)
      end
    else
      if selected.is_a?(Tier)
        return selected == tier
      else
        return selected.to_i == tier.id
      end
    end
  end

  # custom dom ids for better replicate it in javascript
  def tier_dom_class(prefix=nil)
    "#{prefix ? "#{prefix}_" : ''}tier"
  end
  
  def tier_dom_id(record, prefix=nil)
    "#{prefix ? "#{prefix}_" : ''}tier_#{record.id}"
  end

  private 
  
  def current_name_sym
    "name#{Utility.language_code == 'en' ? '' : '_' + current_language_code}".to_sym
  end

  # collects tier categories for select
  def collect_tier_categories_for_select(klass, select=true)
    result = klass.find_all_categories.map {|c| [c.name, c.id]}
    result.insert(0, ["Select...".t, nil])
    result
  end

  # org categories
  def collect_organization_categories_for_select(select=true)
    collect_tier_categories_for_select(Organization, true)
  end

  # group categories
  def collect_group_categories_for_select(select=true)
    collect_tier_categories_for_select(Group, true)
  end

  # href to site
  def link_to_tier_site(tier)
    link_to("http://luleka.com/#{tier.permalink}", "http://luleka.com/#{tier.permalink}", :popup => true)
  end

  #--- overview helpers
  
  def overview_list_tier_kases_count(tier, options={})
    html = div_tag("#{tier.kases_count}", :class => 'first stats')
    if (kases_count = tier.kases_count) > 0
      html << div_tag(link_to(I18n.t("concern", :count => kases_count), 
        collection_path([tier, Kase]), :title => "#{h(tier.name)} #{Kase.human_name(:count => kases_count)}"), :class => 'second')
    else
      html << div_tag(I18n.t("concern", :count => kases_count), :class => 'second')
    end
    overview_list_item(html, options)
  end

  def overview_list_tier_topics_count(tier, options={})
    html = div_tag("#{tier.topics_count}", :class => 'first stats')
    if (topics_count = tier.topics_count) > 0
      html << div_tag(link_to(I18n.t("topic", :count => topics_count), 
        collection_path([tier, Topic]), 
          :title => "#{h(tier.name)} #{Topic.human_name(:count => topics_count)}"), :class => 'second')
    else
      html << div_tag(I18n.t("topic", :count => topics_count), 
        :class => 'second')
    end
    overview_list_item(html, options)
  end

  def overview_list_tier_members_count(tier, options={})
    html = div_tag("#{tier.members_count}", :class => 'first stats')
    members_count = tier.members_count
    text = tier.class.membership_class.is_a?(Organization) ? 
      I18n.t("employee", :count => members_count) : 
        I18n.t("member", :count => members_count)
    if members_count > 0
      html << div_tag(link_to(text, 
        collection_path([tier, "members"]), 
          :title => "#{h(tier.name)} #{tier.class.membership_class.human_name(:count => members_count)}"), :class => 'second')
    else
      html << div_tag(text, :class => 'second')
    end
    overview_list_item(html, options)
  end

  def overview_list_tier_people_count(tier, options={})
    html = div_tag("#{tier.people_count}", :class => 'first stats')
    if (people_count = tier.people_count) > 0
      html << div_tag(link_to(I18n.t("person", :count => people_count), 
        collection_path([tier, Person]), 
          :title => "#{h(tier.name)} #{Person.human_name(:count => people_count)}"), :class => 'second')
    else
      html << div_tag(I18n.t("person", :count => people_count), :class => 'second')
    end
    overview_list_item(html, options)
  end
  
end
