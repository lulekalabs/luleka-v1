module Widgets::FeedbacksHelper
  
  # renders a button similar to a turquoise button but slightly higher and larger font
  def fat_turquoise_button_link_to(text, *args)
    inner_html  = <<-HTML 
<div class="turquoiseButtonFatLeft" style="background-color:#ececec"></div>
<div class="turquoiseButtonFatText">#{text}</div>
    HTML
    <<-HTML
<div class="turquoiseButtonFat">
  #{link_to(inner_html, *args)}
</div>  
    HTML
  end

  # renders a button similar to a turquoise button but slightly higher and larger font
  def fat_turquoise_button_link_to_remote(text, options={}, html_options={})
    inner_html  = <<-HTML 
<div class="turquoiseButtonFatLeft" style="background-color:#ececec"></div>
<div class="turquoiseButtonFatText">#{text}</div>
    HTML
    <<-HTML
<div class="turquoiseButtonFat #{html_options.delete(:class)}" id="#{html_options.delete(:id)}" style="#{html_options.delete(:style)}">
  #{link_to_remote(inner_html, options, html_options)}
</div>  
    HTML
  end

  # renders a button similar to a turquoise button but slightly higher and larger font
  def fat_turquoise_button_link_to_function(text, *args)
    html_options = args.extract_options!.symbolize_keys
    
    inner_html  = <<-HTML 
<div class="turquoiseButtonFatLeft" style="background-color:#ececec"></div>
<div class="turquoiseButtonFatText">#{text}</div>
    HTML
    <<-HTML
<div class="turquoiseButtonFat #{html_options.delete(:class)}" id="#{html_options.delete(:id)}" style="#{html_options.delete(:style)}">
  #{link_to_function(inner_html, *args)}
</div>  
    HTML
  end
  
  # renders a start kase button, used in search bar
  def form_submit_button(text="Continue".t, *args)
    fat_turquoise_button_link_to(text, "#{member_path([@tier, @topic, Kase], :new)}")
  end

  # "7 replies"
  def replies_count_in_words(record)
    "%d reply" / record.responses_count
  end

  # e.g. "1 vote"
  def votes_count_in_words(record)
    "%d vote" / record.votes_count
  end

  # e.g. "vote" for 1 vote or "votes" for 2 or more
  def votes_count_localized_word(record)
    votes_count_in_words(record).split(' ').last
  end

  # e.g. "5 people like this idea"
  def followers_count_in_words(kase)
    case kase.kind
    when :idea then ("%{people} like this idea" % {:people => "%d person" / kase.followers_count})
    when :question then ("%{people} have this question" % {:people => "%d person" / kase.followers_count})
    when :question then ("%{people} have this problem" % {:people => "%d person" / kase.followers_count})
    when :praise then ("%{people} gave same praise" % {:people => "%d person" / kase.followers_count})
    end
  end

  # e.g.
  #   "Share an idea" or
  #   "Share an idea about MacBook Pro"
  def kase_action_with_topic_in_words(kase_or_kind, topic)
    kind = kase_or_kind.is_a?(Kase) ? kase_or_kind.kind : kase_or_kind
    result = if topic
      case kind
        when :idea then "share an idea".t + ' ' + ("about %{topic}".t % {:topic =>truncate(h(topic.name.titleize))})
        when :problem then "report a problem".t + ' ' + ("about %{topic}".t % {:topic =>truncate(h(topic.name.titleize))})
        when :question then "ask a question".t + ' ' + ("about %{topic}".t % {:topic =>truncate(h(topic.name.titleize))})
        when :praise then "give praise".t + ' ' + ("about %{topic}".t % {:topic =>truncate(h(topic.name.titleize))})
      end
    else
      case kind
        when :idea then "share an idea".t
        when :problem then "report a problem".t
        when :question then "ask a question".t
        when :praise then "give praise".t
      end
    end
    result.firstcase
  end

  # returns value or if nil or false, default value
  def boolean_default(value, default=false)
    if value.is_a?(TrueClass)
      true
    elsif value.is_a?(FalseClass)
      false
    else
      default
    end
  end

  # switcher for more form elements
  #
  # options:
  #   :open =>  true   -> open by default
  #   :sticky => true  -> action label remains visble when open, default: false
  #   :icon => true    -> show icon or hide it
  #
  def switcher_link_to(text, options={}, html_options={}, &block)
    id = html_options.delete(:id) || "lm-#{rand(1000000)}"
    inner_id = id + '_more'
    link_id = id + '_link'
    action_id = id + '_action'
    icon = boolean_default(options.delete(:icon), true)
    action_icon_id = id + '_action_icon'
    action_label_id = id + '_action_label'
    css_class = html_options.delete(:class)
    style = html_options.delete(:style)
    inner_css_class = html_options.delete(:inner_class)
    open = options.delete(:open) || false
    sticky = boolean_default(options.delete(:sticky), false)
    
    function = update_page do |page|
      page << "if ($('#{inner_id}').style.display == 'none') {"
        page[inner_id].visual_effect :blind_down, {:duration => 0.3}
        if sticky 
          page << "$('#{action_icon_id}').removeClassName('closed');"
          page << "$('#{action_icon_id}').addClassName('opened');"
        else
          page[action_id].hide
        end
      page << "} else {"
        page[inner_id].visual_effect :blind_up, {:duration => 0.3}
        page[link_id].show
        if sticky 
          page << "$('#{action_icon_id}').removeClassName('opened');"
          page << "$('#{action_icon_id}').addClassName('closed');"
        else
          page[action_id].show
        end
      page << "}"
    end

    onclick = "#{"#{html_options[:onclick]}; " if html_options[:onclick]}#{function}; return false;"
    href = html_options[:href] || '#'
    
    html = <<-HTML
<div id="#{id}" class="switcher #{css_class}" style="#{style}">
  <div id="#{action_id}" class="switcherAction">
    <a id="#{link_id}" href="#{href}" onclick="#{escape_once(onclick)};return false;">
      <span id="#{action_icon_id}" class="actionIcon #{open ? 'opened' : 'closed'}" style="#{icon ? '' : 'display:none;'}"></span>
      <span id="#{action_label_id}" class="actionLabel">#{text}</span>
    </a>
  </div>
  <div id="#{inner_id}" class="#{inner_css_class}" style="#{open ? '' : 'display:none;'}">
    #{capture(&block)}
  </div>
</div>
    HTML
    concat(html, block.binding)
  end

  # link to enter the case details
  def link_to_enter_kase(kase=@kase)
    link_to_function("» " + "Start your case now!".t, "Luleka.Feedback.enter();")
  end

  # link to start from scratch
  def link_to_start_kase(kase=@kase)
    link_to_function("» " + "Add another case now!".t, "Luleka.Feedback.start();")
  end
  
  # link to feedback community, e.g. Apple
  def link_to_community(tier=@tier)
    link_to("» " + "Go to our Feedback Community".t, member_path([tier]), {:popup => true})
  end

  # e.g. "Existing Ideas in the Community"
  def existing_kases_list_header_in_words(kind)
    case kind
      when :idea then "Existing Ideas in the Community".t
      when :question then "Existing Questions in the Community".t
      when :problem then "Existing Problems in the Community".t
      when :praise then "Existing Praise in the Community".t
      else "Existing Cases in the Community".t
    end
  end

  # e.g. "Popular Ideas from the Community"
  def popular_kases_list_header_in_words(kind)
    case kind
      when :idea then "Popular Ideas from the Community".t
      when :question then "Frequent Questions from the Community".t
      when :problem then "Common Problems from the Community".t
      when :praise then "Recent Praise from the Community".t
      else "Popular Cases from the Community".t
    end
  end
  
  # returns an array of kase types, e.g. [:idea, :question, :problem, :praise]
  def kase_kinds
    [:idea, :question, :problem, :praise]
  end

  # which kase type is the first
  def default_kase_kind
    :idea
  end

  # link to powered by with div
  def link_to_powered_by_logo
    link_to(content_tag(:div, '', :class => "poweredByLogo fl ml10"), home_page_url, {:popup => true})
  end

  def topic_check_box_and_label(topic, selected=false)
    html = check_box_tag(
      "kase[topic_ids][]",
      topic.id, selected,
      {:id => dom_id(topic, :checkbox)}
    )
    html += <<-HTML
&nbsp;<label for="#{dom_id(topic, :checkbox)}">#{truncate(h(topic.name))}</label>
    HTML
    
    html
  end
  
  # Works just like the RoR built-in error_messages_for helper with
  # additional parameters for translation and priorities.
  #
  # Options:
  #   :header => "%{errors} on %{object}" where those will be replaced with "5 errors" and "Person" 
  #   :sub_header => "This is a serious problem!"
  #   :priority => [ :username, :password, :gender]
  #   :attr_names => { :gender => "Geschlecht", :birthdate => ... }
  #   :defaults => true  # adds default values if any
  #   :type => :error || :warning || :notice
  #
  def form_error_messages_for(object_names, options = {}, &block)
    options = {:priority => [], :attr_names => {}, :defaults => true, :type => :error, :unique => false,
      :header => "The following errors occured".t, :sub_header => nil,
    }.merge(options).symbolize_keys
    options[:attr_names].symbolize_keys!

    # Convert object name to an array of objects
    object_names = [object_names].flatten
    objects = []
    object_names.each {|name| objects << (name.is_a?(String) || name.is_a?(Symbol) ? instance_variable_get("@#{name}") : name)}
    objects.reject! {|o| o.blank?}
    options.merge!(:objects => objects)

    # add errors
    errors = []
    objects.compact.each do |object| 
      object.errors.each do |attr, val| 
        if !options[:unique] || (errors.select {|item| item[0] == attr}.empty? && options[:unique])
          errors << [attr, [object.errors.on(attr)].flatten]
        end
      end
    end
    options.merge!(:errors => errors)

    # priotize and sort
    unless errors.empty?
      unless options[:priority].empty?
        errors.sort! do |a, b|
          if options[:priority].include?(a[0]) and options[:priority].include?(b[0])
            # both columns have priority, compare accordingly
            options[:priority].index(a[0]) <=> options[:priority].index(b[0])
          elsif options[:priority].include?(a[0])
            # column a defined, stick in front of b
            -1
          elsif options[:priority].include?(b[0])
            # column b defined, stick in front of a
            1
          else
            # both columns have equal priority
            0
          end
        end
      end

      # replace errors and object if present in the header string
      errors_count = if options[:attr_names].empty?
        errors.size
      else 
        errors.select {|item| options[:attr_names].has_key? item[0].to_sym}.size
      end
      options[:header] = options[:header] % {
        :errors => "%d error" / errors_count,
        :object => object_names.collect {|i| i.to_s.humanize.t}.join(", ")
      }
      render :partial => 'widgets/feedbacks/form_error_messages_for', :locals => options if errors_count > 0
    end
  end
  
  # e.g. 1 person like this idea, 2 replies, Idea shared 4 months ago 
  def kase_description_in_words(kase)
     result = []
     result << followers_count_in_words(kase).to_s.capitalize
	   result << replies_count_in_words(kase)
	   result << kase_type_and_time_in_words(kase)
	   result.compact.map {|m| m.to_s.strip}.reject {|i| i.empty?}.join(', ')
  end
  
end
