module KasesHelper

  # Check box to expand the content
  # e.g.
  # [ ] Add a location to this kase
  # 
  # Usage:
  #   :open => true || false  open by default
  #   :auto_hide => true, check label disappears after checking
  #   :after_open => "doSomething();"
  #   :after_close => "doSomething();"
  #
  def check_box_toggle_tag(name, options={}, &block)
    defaults = {:open => false, :auto_hide => false, :effect => false}
    options = defaults.merge(options).symbolize_keys
    
    label = observe = content = nil
    open = options.delete(:open)
    auto_hide = options.delete(:auto_hide)
    effect = options.delete(:effect)
    after_open = options.delete(:after_open)
    after_close = options.delete(:after_close)
    
    label = form_label_tag(name, :id => "#{name}_label",:position => :top, 
      :text => form_radio_element_tag("#{name}_toggle", options.merge(
        :button => check_box_tag("#{name}_toggle", '1', open)
      ))
    ) unless open && auto_hide
		observe = observe_field("#{name}_toggle",
			:function => update_page do |page|
			  page << "if($('#{name}_toggle').checked) {"
			  page.visual_effect :blind_down, name, :duration => 0.5 if effect
			  page.show name unless effect
			  page << after_open if after_open
			  page << "} else {"
			  page.visual_effect :blind_up, name, :duration => 0.5 if effect
			  page.hide name unless effect
			  page << after_close if after_close
			  page << "}"
			  page << "if($('#{name}_toggle').checked && #{auto_hide ? 'true' : 'false'}) {"
			  page << "$('#{name}_toggle').disabled = true"
#			  page.visual_effect :blind_up, "#{name}_label", :duration => 0.5
        page.hide "#{name}_label"
			  page << "}"
		  end
		) unless open && auto_hide
		content = div_tag(capture(&block), :class => 'input', :id => name, :display => open)
    concat form_element((label || '') + (observe || '') + probono_clear_class + (content || '')), block.binding
  end

  # provides a field name identifier for entry fields
  def field_name(object_name, attribute_name, postfix=nil)
    "#{object_name}_#{attribute_name}#{postfix ? '_' + postfix.to_s : nil}"
  end

  # Create link tags as a combination of link_to and image_tag
  # :theme => :form | :turquoise | :blue | etc.
  # :type = :minus | :plus | :edit 
  def button_link_tag( link, options={} )
    defaults = { :type => :minus, :color => ( self.theme ? self.theme[:color] : 'turquoise' ) || 'turquoise' }
    options = defaults.merge(options).symbolize_keys
  #  <span class="buttonMinusTurquoise"><a href="#"></a></span>
    klass = "button#{options[:type].to_s.capitalize}#{options[:color].to_s.capitalize}"

    content_tag( :span, link, options.merge( :class => klass ) )
  end

  # Prints a time label in issue_offer partial, substituts {time} in label with time
  # label could be 'expires in {time}', where {time} is substituted with time e.g. "about 12 hours" is time
  def content_time_tag(name, label, time, options={})
    html = label.gsub(/\{time\}/, content_tag(:span, time, :class => "blueBoxContactDataBlack" ))
    if name.to_s.empty?
      html
    else
      html = content_tag(name, html, options)
    end
  end

  # E.g.
  #
  #   'John shared this idea 15 minutes ago'
  #   'Susan asked this question 1 day ago'
  #
  # used in list_item_sub_content
  def person_posted_kase_time_ago_in_words(kase)
    message = case kase
      when Problem then "%{name} reported this problem %{time} ago".t
      when Question then "%{name} asked this question %{time} ago".t
      when Praise then "%{name} gave praise %{time} ago".t
      when Idea then "%{name} shared this idea %{time} ago".t
      else "%{name} posted %{time} ago".t
    end
    message % {
      :name => link_to(kase.person.username_or_name, person_path(kase.person)),
      :time => time_ago_in_words_span_tag(kase.created_at)
    }
  end

  # E.g.
  #
  #  "Problem posted 5 hours ago"
  #
  def kase_type_posted_time_ago_in_words(kase)
    "%{type} posted %{time} ago" % {:type => kase.class.human_name, 
      :time=> time_ago_in_words_span_tag(kase.created_at)}
  end

  # in kases/_description partial to provide the kind select options
  def options_for_kind_select
    [[select_string_for_kind(:problem), :problem],
     [select_string_for_kind(:question), :question],
     [select_string_for_kind(:praise), :praise],
     [select_string_for_kind(:idea), :idea],
     ["undecided...".t, nil]]
  end
  
  # returns the string rep. for each kind select option
  def select_string_for_kind(a_kind)
    case a_kind.to_s
    when /problem/ then "reporting a problem".t
    when /question/ then "asking a question".t
    when /praise/ then "giving praise".t
    when /idea/ then "sharing an idea".t
    end
  end

  # used in severity levels select 
  def options_for_severity_select(with_select=false)
    Severity.find(:all, :order => "severities.weight ASC").map {|s| [s.name, s.id]}.insert(0,
      with_select ? ["Select...".t, nil] : nil).compact
  end

  # used in severity feelings select 
  def collect_for_severity_feeling_select(with_select=false)
    Severity.find(:all, :order => "severities.weight ASC").map {|s| [s.feeling, s.id]}.insert(0,
      with_select ? ["not sure...".t, nil] : nil).compact
  end
  
  # returns the severity feeling in words
  def select_severity_feeling_in_words(object)
    case object.severity
    when nil then "not sure".t
    else object.severity.feeling
    end
  end
  
  # Either "Change how you feel about" or "Change your "
  def severity_feeling_in_words(object)
    if object.severity
      "Change feeling from %{language}".t % {
        :language => "<b>#{select_severity_feeling_in_words(object)}</b>"
      }
    else
      "How does it make you feel?".t
    end
    
  end
  
  def collect_for_native_languages_select(selected=nil)
    Utility.active_language_codes.map {|code| [I18n.t(code, :scope => 'languages'), code.to_s.downcase]}
  end
  
  # returns "Deutsch", "Español", "English" native language for language code etc.
  def select_native_language(code)
    I18n.t(code, :scope => 'languages')
  end

  # creates sentences like
  #
  #   Juergen reported this problem 1 year ago
  #   Juergen shared this idea 1 minute ago
  #
  def kase_person_verb_type_and_time_in_words(kase, options={})
    "%{name} %{verb_and_type} %{time}" % {
      :name => link_to(h(kase.person.username_or_title_and_full_name), person_path(kase.person),
        options[:pcard] ? {:class => "pcard", :rel => member_url([@tier, kase.person], :pcard)} : {}),
      :verb_and_type => case kase.kind 
        when :problem then "reported this problem".t
        when :question then "asked this question".t
        when :praise then "gave praise".t
        when :idea then "shared this idea".t
        else "posted this case".t
      end,
      :time => "%{time} ago".t % {:time => time_ago_in_words_span_tag(kase.created_at)}
    }
  end

  # returns no of comments in words "5 Comments"
  def comment_count_in_words(object)
    content_tag(:span, (I18n.t("{{count}} comment", :count => object.comments_count)).titleize)
  end

  # type of kase and time in words
  #
  # e.g.
  #
  #   Problem shared 1 year ago
  #
  def kase_type_and_time_in_words(kase)
    "%{type} %{verb} %{time}" % {
      :type => kase.class.human_name,
      :verb => case kase.kind 
        when :problem then "reported".t
        when :question then "asked".t
        when :praise then "praised".t
        when :idea then "shared".t
        else "posted".t
      end,
      :time => "%{time} ago".t % {:time => time_ago_in_words_span_tag(kase.created_at)}
    }
  end
  
  # type and time and offer
  #
  # e.g.
  #
  #   Problem shared 1 year ago, offered for [$1.00], expires in 12 minutes
  #
  def kase_type_time_and_offer_in_words(kase)
    result = []
    result << kase_type_and_time_in_words(kase)
    if kase.offers_reward?
      result << "&nbsp;"
      result << "&nbsp;"
      result << kase_price(kase)
      result << (kase.expires_at > Time.now.utc ? "offer expires in %{time}".t : "offer expired %{time} ago".t) % {
        :time => distance_of_time_in_words(Time.now.utc, kase.expires_at)
      }
    end
    table_cells_tag(*result)
  end
  
  # [$12.00] expires in 1 day 
  def kase_offer_and_expiry_time_in_words(kase)
    result = []
    if kase.offers_reward?
      result << kase_price(kase)
      result << (kase.expires_at > Time.now.utc ? "offer expires in %{time}".t : "offer expired %{time} ago".t) % {
        :time => distance_of_time_in_words(Time.now.utc, kase.expires_at)
      }
    end
    table_cells_tag(*result)
  end
  
  # provides a kase activity text
  #
  # e.g.
  #
  # "last active 1 minute ago"
  #
  def kase_activity_in_words(kase)
    "last active %{time} ago".t % {:time => ""}
  end
  
  # returns the kase html tag for status
  #
  # e.g.
  #
  #  <span class="statusGreen">Resolved</span>
  #
  def kase_status(kase, options={})
    klass = case kase.current_state
      when :new, :pending then 'statusGrey'
      when :open then 'statusYellow'
      when :assigned then 'statusRed'
      when :resolved, :solved then 'statusGreen'
      when :closed then 'statusBlack'
      when :spam, :created then 'statusTurquoise'
      when :deleted then 'statusDark'
    end
    return span_tag(kase.current_state_t.upcase, {:class => klass}.merge(options)) if klass
    ''
  end

  # returns the kase (bid) price
  #
  # e.g.
  #
  #   [$12.00]
  #
  def kase_price(*args, &proc)
    content, options = filter_tag_args(*args)
    content = capture(&proc) if block_given?
    html =  tag(:span, {:class => "statusPrice #{options[:class]}", :id => options[:id]}, true)
    html << "&nbsp;#{content}&nbsp;" if content
    html << "</span>"
    block_given? ? concat(html, proc.binding) : html
  end

  #--- status list
  
  def overview_list_kase_status(kase, options={})
    html = div_tag(kase_status(kase), :class => 'first')
    
    text = case kase.current_state
      when :open then "open".t
      when :assigned then span_tag("%{time} ago".t % {:time => time_ago_in_words_span_tag(kase.assigned_at)}, time_title_options(kase.assigned_at))
      when :closed then span_tag("%{time} ago".t % {:time => time_ago_in_words_span_tag(kase.closed_at)}, time_title_options(kase.closed_at))
      when :resolved then span_tag("%{time} ago".t % {:time => time_ago_in_words_span_tag(kase.resolved_at)}, time_title_options(kase.resolved_at))
    end
    
    html << div_tag(text, :class => 'second')
    overview_list_item(html, options)
  end

  # returns tag options for title/alt, used in time
  def time_title_options(utc_time, options={})
    if utc_time
      user_time = utc2user(utc_time)
      string_time = user_time.to_s(:long)
      {:title => string_time, :alt => string_time}.merge(options)
    else
      {}.merge(options)
    end
  end

  def overview_list_kase_price(kase, options={})
    if kase.offers_reward?
      html = div_tag(kase_price(kase.price.format, {:class => kase.alive? ? 'statusPriceGreen' : 'statusPriceRed'}),
        :class => 'first')
      text = case kase.current_state
        when :open then countdown_in_words_span_tag(kase.expires_at)
        when :resolved then "paid".t
        else "expired".t
      end
    
      html << div_tag(text, :class => 'second')
      overview_list_item(html, options)
    end
  end
  
  def overview_list_kase_responses_count(kase, options={})
    html = div_tag("#{kase.responses_count}", :class => 'first stats')
    html << div_tag(I18n.t("reply", :count => kase.responses_count), :class => 'second')
    overview_list_item(html, options)
  end

  def overview_list_kase_votes_count(kase, options={})
    html = div_tag("#{kase.votes_count}", :class => 'first stats')
    html << div_tag(I18n.t("vote", :count => kase.votes_count), :class => 'second')
    overview_list_item(html, options)
  end

  def overview_list_kase_followers_count(kase, options={})
    html = div_tag("#{kase.followers_count}", :class => 'first stats')
    html << div_tag(I18n.t("follower", :count => kase.followers_count), :class => 'second')
    overview_list_item(html, options)
  end

  def overview_list_kase_visits_count(kase, options={})
    html = div_tag("#{kase.visits_count}", :class => 'first stats')
    html << div_tag(I18n.t("visit", :count => kase.visits_count), :class => 'second')
    overview_list_item(html, options)
  end

  def overview_list_kase_tier(kase, options={})
    if kase.tier
      html = div_tag(link_to(tier_image_tag(kase.tier), tier_path(kase.tier)), :class => 'full')
      overview_list_item(html, options)
    end
  end

  # shows kase types, e.g. question mark for question, ! for problem, etc.
  def overview_list_kase_type(kase, options={})
    overview_list_item(div_tag(kase_type_icon(kase), :class => 'full'), options)
  end

  # returns a kase type icon given a kase object
  def kase_type_icon(kase)
    kase_type_icon_tag(kase.kind)
  end

  # returns a div container with an icon for the kase
  def kase_type_icon_tag(kind, options={})
    div_tag('&nbsp;', {:class => "kaseTypeIcon#{kind.to_s.camelize}"}.merge(options))
  end

  #--- content action list

  # provides action list container within a block
  def content_action_list(&block)
    concat tag(:ul, :class => "contentActionNavi"), block.binding     
    concat capture(&block), block.binding
    concat "</ul>", block.binding
    concat probono_clear_class, block.binding
  end
  
  # adds item, withing the action list
  def content_action_item(text=nil, prefix=nil, &block)
    text = capture(&block) if block_given?
    html = ''
    html << content_tag(:li, prefix, :class => 'prefix') if prefix
    html << content_tag(:li, text)
    
    if block_given?
      concat html, block.binding
    else
      html
    end
  end

  # dito, with if condition
  def content_action_item_if(condition, text=nil, prefix=nil, &block)
    content_action_item(text, prefix, &block) if condition
  end

  # prints an action item with a comment icon
  def content_comment_action_item(text=nil, &block)
    icon = content_tag(:div, '', :class => 'iconCommentSmall')
    content_action_item(text, icon, &block)
  end

  def content_comment_action_item_if(condition, text=nil, &block)
    content_comment_action_item(text, &block) if condition
  end
  
  # prints an action item with a comment reply icon
  def content_reply_comment_action_item(text=nil, &block)
    icon = content_tag(:div, '', :class => 'iconReplyCommentSmall')
    content_action_item(text, icon, &block)
  end

  def content_reply_comment_action_item_if(condition, text=nil, &block)
    content_reply_comment_action_item(text, &block) if condition
  end

  # intelligent link to comment, works for kase or response
  def content_comment_action_link(text, comment_or_id, url=nil)
    content_comment_action_item(comment_link_to_function(text, comment_or_id, url))
  end

  def comment_link_to_function(text, comment_or_id, url=nil)
    id = if comment_or_id.is_a?(Comment)
      comment_dom_id(comment_or_id)
    else
      comment_or_id
    end
    link_to_function(text, nil, {:rel => "nofollow"}) do |page|
      page << "if (Element.visible('#{id}')) {"
        page << "new Effect.ScrollTo('#{id}', {offset:-12})"
      page << "} else {"
        page.show("#{id}")
        page << "if (typeof($('#{id}').retrieve('loaded')) == 'undefined') {"
          page << remote_function(:url => url, :method => :get, 
            202 => "$('#{id}').store('loaded', true)", :complete => "document.fire('dom:updated')")
        page << "}"
      page << "}"
    end
  end
  
  def content_comment_action_link_if(condition, text, commentable)
    content_comment_action_link(text, commentable) if condition
  end

  # intelligent link to reply comment, works for kase or response
  def content_reply_comment_action_link(text, comment)
    content_reply_comment_action_item(comment_link_to_function(text, comment))
  end

  def content_reply_comment_action_link_if(condition, text, commentable)
    content_reply_comment_action_link(text, commentable) if condition
  end

  # prints an action item with a accept 
  def content_accept_action_item(text=nil, &block)
    icon = content_tag(:div, '', :class => 'iconAcceptSmall')
    content_action_item(text, icon, &block)
  end
  
  def content_accept_action_item_if(condition, text=nil, &block)
    content_accept_action_item(text, &block) if condition
  end

  # rendes a content action with edit button
  def content_edit_action_item(text=nil, &block)
    icon = content_tag(:div, '', :class => 'iconEditSmall')
    content_action_item(text, icon, &block)
  end

  # intelligent link to comment, works for kase
  def content_edit_action_link(text, object)
    content_edit_action_item(link_to_remote_facebox(text, member_url([@tier, object], :edit), {:rel => "nofollow"}))
  end
  
  def content_edit_action_link_if(condition, text, object)
    content_edit_action_link(text, object) if condition
  end
  
  # returns a descriptive title in response overview
  def response_title_in_words(response, options={})
    if response.new_record?
      "%{name} wants to add a %{type} now".t % {
        :name => response.person ? link_to(h(response.person.username_or_name),
          person_path(response.person)) : response.sender_email,
        :type => response.class.human_name,
      }
    else
      "%{name} replied %{time} ago".t % {
        :name => response.person ? link_to(h(response.person.username_or_title_and_full_name), 
          person_path(response.person), options[:pcard] ? {:class => "pcard", :rel => member_url([@tier, response.person], :pcard)} : {}) : response.sender_email,
        :type => response.class.human_name,
        :time => time_ago_in_words_span_tag(response.created_at)
      }
    end
  end

  # returns a descriptive title in comment overview
  def comment_title_in_words(comment, options={})
    "%{name} added a %{type} %{time} ago".t % {
      :name => link_to(h(comment.sender.username_or_name), person_path(comment.sender),
        options[:pcard] ? {:class => "pcard", :rel => member_path([@tier, comment.sender], :pcard)} : {}),
      :type => comment.class.human_name,
      :time => time_ago_in_words_span_tag(comment.created_at)
    }
  end

  def tags_dom_id(taggable, edit=false)
    dom_id(taggable, "#{edit ? 'edit' : 'show'}_tags")
  end
  
  # edit button
  def edit_tags_dom_id(taggable)
    dom_id(taggable, :edit_button)
  end

  def add_tag_form_dom_id(taggable, edit=false)
    dom_id(taggable, "add_tag_form")
  end

  # returns an url to adding facebook
  def share_on_facebook_url(object)
    url = member_url([@tier, @topic, object])
    "http://www.facebook.com/share.php?u=#{url}"
  end

  # returns an url to adding facebook
  def share_on_twitter_url(object)
    url = member_url([@tier, @topic, object])
    title = object.title
    "http://twitter.com/home?status=#{url}"
  end

  # "2 Responses" or "No Response"
  def kase_responses_count_in_words(kase)
    I18n.t("{{count}} recommendation", :count => kase.responses_count).titleize
  end

  # renders a star to follow and stop follow a kase
  def star_follow_control(kase, html_options={})
    html = tag(:div, {:class => 'star', :id => dom_id(kase, :star_follow)}, true)
    if current_user_following?(kase)
      html << content_tag(:span, 
        link_to_remote('', {:url => member_url([@tier, kase], :toggle_follow), :method => :put}, 
          {:rel => "nofollow", :title => ["#{"This %{type} is not similar to my %{type}".t}." % {:type => kase.class.human_name}, "Stop subscribing to this %{type}?".t % {:type => kase.class.human_name}, "#{"Click again to undo".t}."].join(" ")}), 
            :class => 'active')
    else
      html << content_tag(:span, 
        link_to_remote('', {:url => member_url([@tier, kase], :toggle_follow), :method => :put},
          {:rel => "nofollow", :title => ["#{"This %{type} is similar to my %{type}".t}." % {:type => kase.class.human_name}, "Subscribe to this %{type}?".t % {:type => kase.class.human_name}, "#{"Click again to undo".t}."].join(" ")}), 
            :class => 'inactive')
    end
    html << "</div>"
    html
  end

end
