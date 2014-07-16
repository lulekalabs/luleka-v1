module PeopleHelper

  # outputs a "CEO at IBM" type of output, with links to each title and company by default
  def person_professional_title_at_company_in_words(person, options={}, html_options={})
    defaults = {:mask => "%{professional_title} at %{company}".t}
    options = defaults.merge(options).symbolize_keys
    mask = options.delete(:mask)

    professional_title_link = tag_list_link_to(person.professional_titles, options.merge(:url => :people_tag_path), html_options)
    company_link = '' # link_to(person.company.to_s, company_url(person.company))

    unless professional_title_link.empty?
      unless company_link.empty?
        return options[:mask] % {:professional_title => professional_title_link, :company => company_link}
      end
      return professional_title_link
    else
      unless company_link.empty?
        return company_link
      end
    end
  end
  
  # shows text the number of visits to profile
  #
  # e.g.
  #
  #   no visit
  #   1 visit
  #   30 visits
  #
  def person_profile_visits_in_words(person, options={})
    link_to("%d visit" / person.visits_count, visitors_person_path(person)) if person.visits_count > 0
  end

  # displays the number of confirmed contacts
  #
  # e.g.
  #
  #   no contacts
  #   1 contact
  #   30 contacts
  #
  def person_confirmed_contacts_in_words(person, options={})
    friends_count = person.friends.count
    result = "%d contact" / friends_count
    result = link_to(result, contacts_url) if friends_count > 0
    result
  end
  
  # "2 vistors and 5 confirmed contacts" with links
  def person_confirmed_contacts_and_visits_in_words(person, options={})
    [
      person_confirmed_contacts_in_words(person, options),
      person_profile_visits_in_words(person, options)
    ].compact.to_sentence.strip_period
  end

  # Displays "Partner since about 3 months ago"
  def person_member_status_since_in_words(person, options={})
    "%{member} since %{time} ago".t % {
      :member => link_to(person.current_state_t.titleize, {}),
      :time => time_ago_in_words(person.partner? ? person.partner_at || person.created_at : person.created_at)
    }
  end
  
  # E.g. 5 reputations
  def person_reputation_points_in_words(person)
    html = content_tag(:span, "#{person.reputation_points}", :class => "reputationPointsHighlight") + "&nbsp;"
    html += I18n.t("total reputation", :count => person.reputation_points)
    html
  end

  # returns the employment status in words
  def person_employed_at_in_words(person)
    result = []
    person.employments.each do |employment|
      result << "%{role} at %{employer}".t % {
        :role => employment.role.blank? ? "employed" : h(employment.role),
        :employer => link_to(h(employment.employer.name), tier_path(employment.employer))
      }
    end
    result.empty? ? nil : result.to_sentence.strip_period
  end

  # adds a div with a space
  def spacer(options={})
    div_tag ' ', {:style => "height:3px;"}.merge(options)
  end

  # Used for in-place avatar upload.
  # creates a hidden iframe to submit the uploaded file into.
  def form_iframe_tag(url_for_options = {}, options = {}, &proc)
    upload_id = options[:id] || "form_in_place_id"  # new_upload_id
    options.merge!({:id => upload_id})

    form_html =  form_tag(url_for_options, options.merge({
      :target => "upload_target_iframe_#{upload_id}", :multipart => true
    }))
    
    iframe_html = content_tag(:iframe, "", {
      :id => "upload_target_iframe_#{upload_id}",
      :name => "upload_target_iframe_#{upload_id}",
      :src => "",
      :style => "width:1px;height:1px;border:0;"
    })

    if block_given?
      concat form_html, proc.binding
      yield
      concat "</form>", proc.binding
      concat iframe_html, proc.binding
    end
  end

  # Provides a container for seperating content from each other
  def profile_grouper(name, options={}, &proc)
    if block_given?
      block_content = capture(&proc)
      unless block_content.blank?
        concat content_tag(:div, name, :class => 'profileListSeparator'), proc.binding
        concat tag(:div, options , true), proc.binding
        concat block_content, proc.binding
        concat '</div>', proc.binding     
      end
    else
      content_tag(:div, name, :class => 'profileListSeparator')
    end
  end
  
  # if condition for grouper
  def profile_grouper_if(condition, name, options={}, &proc)
    profile_grouper(name, options, &proc) if condition
  end

  # if condition for grouper
  def profile_grouper_unless(condition, name, options={}, &proc)
    profile_grouper(name, options, &proc) unless condition
  end

  # Takes a person instance and returns the source path.
  #
  # Options:
  #   :name => 'thumb' || 'profile'
  #   :size => '35x35'
  #
  def image_avatar_path(person, options={})
    options = {:name => :thumb, :anonymous => false}.merge(options).symbolize_keys
    source = options.delete(:source)
    return source if source 
    name = options.delete(:name)
    anonymous = options.delete(:anonymous)

    if person && !anonymous && person.avatar.file?
      source = person.avatar.url(name)
    end
    if source.blank?
      if :profile == name.to_sym
        source = person && person.is_female? ? image_path('icons/avatars/female_large_turquoise.png') : image_path('icons/avatars/male_large_turquoise.png')
      else
        if person && person.partner?
          source =  person.is_male? ? image_path('icons/avatars/male_green.png') : image_path('icons/avatars/female_green.png')
        else
          source = person && person.is_female? ? image_path('icons/avatars/female_blue.png') : image_path('icons/avatars/male_blue.png')
        end
      end
    end
    source
  end

  # Takes person instance. Provide the name for the image.
  # Options are like image_tag + options for image_avatar_path
  def image_avatar_tag(person, options={})
    options = {:size => '35x35', :anonymous => false}.merge(options).symbolize_keys
    anonymous = !!options.delete(:anonymous)
    image_tag(image_avatar_path(person, {:anonymous => anonymous}.merge(options)), 
      {:alt => person ? (anonymous ? "" : h(person.username_or_name)) : "", 
        :title => person ? (anonymous ? "" : h(person.username_or_name)) : ""}.merge(options))
  end
  
  # link with the person's image avatar
  def avatar_link_to(person, image_options={}, link_options={})
    link_to(image_avatar_tag(person, image_options),
      person_path(person), {:title => "#{h(person ? person.name : '')}".strip}.merge(link_options)) if person
  end

  def profile_link_to(name, person, options = {}, html_options = nil, *parameters_for_method_reference)
    person ? link_to(name, person_path(person), html_options, *parameters_for_method_reference) : name
  end
  
  # adds link to person with person.name
  def profile_name_link_to(person, options = {}, html_options = nil, *parameters_for_method_reference)
    link_to(h(person.name), person_path(person), html_options, *parameters_for_method_reference)
  end

  #--- property view helpers

  # Generates the table col's for label, property and if 
  # :editable is true also the additional column for the edit button
  #<col width="140"></col>
  #<col width="329"></col>
  #<col width="11"></col>
  def profile_property_columns_tag(options={})
    defaults = {:editable => false, :width => 480, :edit_control_width => 11}
    options = defaults.merge(options).symbolize_keys
    html = ''
    if options[:editable]
      html << content_tag(:col, '', :width => "#{options[:width] - options[:edit_control_width]}")
      html << content_tag(:col, '', :width => "#{options[:edit_control_width]}")
    else
      html << content_tag(:col, '', :width => "#{options[:width]}")
    end
    html
  end

  # Provides a container for each of the property elements
  def profile_property_element(options={}, &proc)
    defaults = {:type => :table, :editable => false, :update => false}
    options = defaults.merge(options).symbolize_keys

    concat tag(:div, {:id => options[:id], :style => options[:style]}.merge(:class => "row"), true), proc.binding
    case options[:type]
    when :table
      concat tag(:table, {:cellpadding => "0", :cellspacing => "0"}, true), proc.binding
        concat profile_property_columns_tag(options), proc.binding
        concat tag(:tr, {}, true), proc.binding
          yield
        concat "</tr>", proc.binding
      concat "</table>", proc.binding
    when :form
      concat tag(:table, {:cellpadding => "0", :cellspacing => "0"}, true), proc.binding
        concat tag(:tr, {}, true), proc.binding
          concat content_tag(:td, '', :style => "vertical-align:top;width:80px;" ), proc.binding
          concat tag(:td, {:style => "vertical-align:top;width:400px;"}, true), proc.binding
            yield
          concat "</td>", proc.binding
        concat "</tr>", proc.binding
      concat "</table>", proc.binding
    else
      yield
    end
    concat "</div>", proc.binding
  end

  # Adds condition parameter to profile_property_element
  def profile_property_element_if(condition, options={}, &proc)
    profile_property_element(options, &proc) if condition
  end

  # Adds condition parameter to profile_property_element
  def profile_property_element_unless(condition, options={}, &proc)
    profile_property_element(options, &proc) unless condition
  end

  # container for value (right) element
  def profile_property_column(options={}, &proc)
    td_options = {:style => "vertical-align:top;"}
    if block_given?
      concat tag(:td, options.merge(td_options), true), proc.binding
      yield
      concat "</td>", proc.binding
    else
      html = ""
      html << tag(:td, options.merge(td_options), true)
      html << options.delete( :content )
      html << "</td>"
    end
  end 

  # generic in place property editor
  # 
  # e.g.
  #
  #   profile_property :person, :interest, "Interest", 
  #     :partial => 'form_interest', :object => ...
  #
  # options:
  #   :editable => true | false
  #   :label    => "text"
  #   :partial  => "a partial to use for editing or displaying"
  #   :locals   => {:for => :partial, ...}
  #   :object   => overrides object passed into partial
  #   :url      => hash_for_..._path() || {}
  #
  def profile_property(object_name, method_name, text=nil, options={})
    defaults = {:editable => false, :label => {}, :display => true, :edit => false}
    options = defaults.merge(options).symbolize_keys

    options[:label].merge!(:position => :left)
    if options.has_key?(:object)
      object = options.delete(:object)
    else
      object = instance_variable_get("@#{object_name}")
    end
    options[:label].merge!(text.is_a?(Hash) ? text : {:text => text, :auto => false, :lock => options[:editable]})
    
    render :partial => 'people/profile_property_in_place', :object =>  object, :locals => {
      :object_name => object_name.to_sym,
      :method_name => method_name.to_sym,
      :locals => (options.delete(:locals) || {}).merge({
        :object_name => object_name.to_sym,
        :method_name => method_name.to_sym,
      })
    }.merge(options) if object
  end

  def profile_property_if(condition, object_name, method_name, text=nil, options={})
    profile_property(object_name, method_name, text, options) if condition
  end

  def profile_property_unless(condition, object_name, method_name, text=nil, options={})
    profile_property(object_name, method_name, text, options) unless condition
  end

  # Creates a link to a VoIP phone service, like Skype
  def phone_link_to(number, options={})
    defaults = {:service => :skype}
    options = defaults.merge(options).symbolize_keys

  #  link_to("test", "callto://#{number.to_s}")
    content_tag(:a, number, :href => "callto:#{number}" )
  end

  def collect_personal_status_for_select(select=true)
    PersonalStatus.find(:all, :order => "#{PersonalStatus.localized_facet(:name)} ASC").map {|s| [s.name, s.id]}.reject {|s| !s.first}.insert(0, select ? ["Select...".t, nil] : nil).compact
  end

  # collects tags and adss a link 
  def property_tags(object_name, method_name, options={})
    object_name = if object_name.is_a?(String) || object_name.is_a?(Symbol)
      instance_variable_get("@#{object_name}")
    else
      object_name
    end
    method_name = if method_name.is_a?(String) || method_name.is_a?(Symbol)
      object_name.send(method_name.to_s.pluralize)
    else
      method_name
    end
    result = method_name.map do |t|
      if t.is_a?(Tagging)
        span_tag(link_to(h(t.name ? t.name : t.tag.name), tag_url([Person], t.tag)))
      else
        span_tag(link_to(h(t.to_s), tag_url([Person], t)))
      end
    end
    result.empty? ? '---' : result.to_sentence.strip_period
  end
  
  # prints the languages in a comma separated way
  def property_spoken_languages(object_name, options={})
    object = if object_name.is_a?(String) || object_name.is_a?(Symbol)
      instance_variable_get("@#{object_name}")
    else
      object_name
    end
    result = object.spoken_languages.reject {|l| !l.name}.map {|l| link_to(l.name.to_s.humanize, tag_url([Person], Tag.new(:name => l.name)))}
    result.empty? ? '---' : result.to_sentence.strip_period
  end
  
  # returns a property summary text marked up with markdown
  def property_summary(object_name, method_name, options={})
    object = if object_name.is_a?(String) || object_name.is_a?(Symbol)
      instance_variable_get("@#{object_name}")
    else
      object_name
    end
    result = object.send("#{method_name}")
    unless result.blank?
      markdown(result)
    else
      '---'
    end
  end

  # prints education
  # <academic_degrees> from <universities>
  #
  # e.g.
  #
  #   MBA from Stanford University
  #   MBA from Stanford University and MSc from Columbia University
  #   Stanford University
  #   MBA
  #   MBA from Stanford University and MSc
  #
  def property_education(object_name, options={})
    options = {:blank => '---'}.merge(options).symbolize_keys
    object = if object_name.is_a?(String) || object_name.is_a?(Symbol)
      instance_variable_get("@#{object_name}")
    else
      object_name
    end
    degrees = object.academic_degree_taggings
    universities = object.university_taggings

    result = []
    if degrees.size >= universities.size
      degrees.each_with_index do |degree, i|
        if universities[i]
          result << "%{degree} from %{university}".t % {
            :degree => link_to(degrees[i].name ? degrees[i].name : degrees[i].tag.name, tag_url([Person], degrees[i].tag)),
            :university => link_to(universities[i].name ? universities[i].name : universities[i].tag.name, tag_url([Person], universities[i].tag))
          }
        else
          result << link_to(degrees[i].name ? degrees[i].name : degrees[i].tag.name, tag_url([Person], degrees[i].tag))
        end
      end
    else
      universities.each_with_index do |university, i|
        if degrees[i]
          result << "%{degree} from %{university}".t % {
            :degree => link_to(degrees[i].name ? degrees[i].name : degrees[i].tag.name, tag_url([Person], degrees[i].tag)),
            :university => link_to(universities[i].name ? universities[i].name : universities[i].tag.name, tag_url([Person], universities[i].tag))
          }
        else
          result << link_to(universities[i].name ? universities[i].name : universities[i].tag.name, tag_url([Person], universities[i].tag))
        end
      end
    end
    result.empty? ? options[:blank] : result.to_sentence.strip_period
  end
  
  # alias for property_education
  def education_display(person, options={})
    property_education(person, {:blank => ''}.merge(options))
  end

  # prints work
  # <personal_status> <professions> working as <professional_titles> at <company> in the field of <industries>
  #
  # e.g.
  #
  #   Freelance Programmer working as President at 47Signals in he field of IT
  #
  def property_work(object_name, options={})
    options = {:blank => '---'}.merge(options).symbolize_keys
    object = if object_name.is_a?(String) || object_name.is_a?(Symbol)
      instance_variable_get("@#{object_name}")
    else
      object_name
    end
    components = []
    
    # personal status
    components << link_to(object.personal_status.name, 
      tag_url([Person], Tag.new(:name => object.personal_status.name))) if object.personal_status

    # professional title  
    components << object.profession_taggings.map {|t| link_to(t.name ? t.name : t.tag.name, 
      tag_url([Person], t.tag))}.to_sentence.strip_period
      
    if !object.professional_title.blank? && !object.organizations.empty?
      components << "working as %{title} at %{name}".t % {
        :title => object.professional_title_taggings.map {|t| link_to(t.name ? t.name : t.tag.name, tag_url([Person], t.tag))}.to_sentence.strip_period,
        :name => object.organizations.map {|o| link_to(o.name, tier_root_url(o))}.to_sentence.strip_period
      }
    elsif !object.professional_title.blank? && object.organizations.empty?
      components << "working as %{title}".t % {
        :title => object.professional_title_taggings.map {|t| link_to(t.name ? t.name : t.tag.name, tag_url([Person], t.tag))}.to_sentence.strip_period
      }
    elsif object.professional_title.blank? && !object.organizations.empty?
      components << "working at %{name}".t % {
        :name => object.organizations.map {|o| link_to(o.name, tier_root_url(o))}.to_sentence.strip_period
      }
    end
    components << "in the field of %{industry}" % {
      :industry => object.industry_taggings.map {|t| link_to(t.name ? t.name : t.tag.name, tag_url([Person], t.tag))}.to_sentence.strip_period
    } unless object.industry.blank?
    components.reject! {|c| c.blank?}
    components.empty? ? options[:blank] : components.join(' ')
  end
  
  # alias for property_work
  def work_display(person, options={})
    property_work(person, options.merge({:blank => ''}))
  end
  
  # dom_id for property
  def property_dom_id(object, property_name, prefix=nil)
    return dom_id(object, "#{property_name}_#{prefix}") if prefix
    dom_id(object, "#{property_name}")
  end

  # returns a hash array of all available bands for sidebar_contacts partial
  def sidebar_contacts_bands(profile, options={})
    bands = [{
      :title => "%{name} (%{count})" % {
        :name => link_to("Contacts".t, contacts_person_path(profile)),
        :count => "#{@contacts_count}"
      },
      :short_title => "Shared Contacts".t,
      :records => options[:contacts] || @contacts,
      :url => hash_for_contacts_person_path(:id => profile, :sidebar => '1')
    }, {
      :title => "%{name} (%{count})" % {
        :name => link_to("Shared Contacts".t, shared_contacts_person_path(profile)),
        :count => "#{@shared_contacts_count}"
      },
      :short_title => "Shared Contacts".t,
      :records => options[:shared_contacts] || @shared_contacts,
      :url => hash_for_shared_contacts_person_path(:id => profile, :sidebar => '1')
    }, {
      :title => "%{name} (%{count})" % {
        :name => link_to("Followers".t, followers_person_path(profile)),
        :count => "#{@followers_count}"
      },
      :short_title => "Followers".t,
      :records => options[:followers] || @followers,
      :url => hash_for_followers_person_path(:id => profile, :sidebar => '1')
    }, {
      :title => "%{visitors} (%{count})" % {
        :visitors => link_to("Recent Visitors".t, visitors_person_path(profile)),
        :count => "#{@visitors_count}"
      },
      :short_title => "Recent Visitors".t,
      :records => options[:visitors] || @visitors,
      :url => hash_for_visitors_person_path(:id => profile, :sidebar => '1')
    }]
    bands.reject {|b| b[:records].blank?}
  end

  # checks to see if the bands array in sidebar_contacts holds any information
  def sidebar_contacts_bands_blank?(bands)
    return true if bands.blank?
    bands.each {|b| return false if b[:records]}
    true
  end
  
  # returns the first title of bands
  def sidebar_contacts_first_title(bands)
    bands.each {|b| return b[:title] if b[:records]}
  end
  
  def sidebar_contacts_last_band?(band, bands)
    bands.each {|b| return b[:title] if b[:records]}
    false
  end

  def overview_list_person_kases_count(person, options={})
    html = div_tag("#{person.kases_count}", :class => 'first stats')
    text = I18n.t("concern", :count => person.kases_count)
    if false && person.kases_count > 0
      html << div_tag(link_to(text, 
        collection_path([person, Kase]), :title => "#{text}"), :class => 'second')
    else
      html << div_tag(text, :class => 'second')
    end
    overview_list_item(html, options)
  end
  
  def overview_list_person_responses_count(person, options={})
    html = div_tag("#{person.responses_count}", :class => 'first stats')
    html << div_tag(I18n.t("advice", :count => person.responses_count), :class => 'second')
    overview_list_item(html, options)
  end
  
  def overview_list_person_votes_count(person, options={})
    html = div_tag("#{person.received_up_votes_count}", :class => 'first stats')
    html << div_tag(I18n.t("vote", :count => person.received_up_votes_count), :class => 'second')
    overview_list_item(html, options)
  end
  
  def overview_list_person_followers_count(person, options={})
    html = div_tag("#{person.followers_count}", :class => 'first stats')
    html << div_tag(I18n.t("follower", :count => person.followers_count), :class => 'second')
    overview_list_item(html, options)
  end

  def overview_list_person_friends_count(person, options={})
    html = div_tag("#{person.friends_count}", :class => 'first stats')
    html << div_tag(I18n.t("contact", :count => person.friends_count), :class => 'second')
    overview_list_item(html, options)
  end
  
  def overview_list_person_visits_count(person, options={})
    html = div_tag("#{person.visits_count}", :class => 'first stats')
    html << div_tag(I18n.t("visitor", :count => person.visits_count), :class => 'second')
    overview_list_item(html, options)
  end

  def overview_list_person_reputation_points(person, options={})
    html = div_tag("#{person.reputation_points}", :class => 'first stats')
    html << div_tag(I18n.t("reputation", :count => person.reputation_points), :class => 'second')
    overview_list_item(html, options)
  end
  
end
