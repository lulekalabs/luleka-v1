module FrontTagHelper
  
  #--- constants
	MAX_TABS = 3
  MAX_STARS = 5
  
  #--- accessors
  attr_accessor :theme, :style_context

  #--- methods

  # Set styles for all page components
  # Grouping for uses cases and compliant with the stylesheet 
  # support force style or theme inherited.
  # Customized for actual probono.css
  # not all style names support automation
  # Suggestion : pattern for style names 
  # and refactor stylesheet <theme><style name>
  def set_theme(options = {})
    # set default options
    defaults = { :theme => :form }
    options = defaults.merge(options).symbolize_keys
    options[:type] ||= options.delete(:theme)
    self.theme = PROBONO_STYLE_THEMES[PROBONO_THEME_MAPPING[options[:type].to_sym]]
  end

  # wrapper to specifically set the theme by name and not the object
  def set_theme_name(theme_name, options={})
    set_theme(options.merge(:theme => theme_name))
  end

  # returns the current theme data structure
  def current_theme
    @theme
  end

  # returns the type of theme that is currently loaded
  # Like: :sidebar, :form, etc.
  def current_theme_name
    if @theme
      @theme[:type].to_sym if @theme[:type]
    end
  end

  # returns the color for the given theme object
  # :form -> 'turquoise'
  # :issue -> 'blue'
  # etc.
  def theme_name_color(theme_type)
    theme_translate = { :form => "turquoise", :response => "green", :case => "blue", :comment => "blue", :green => "green", :blue => "blue", :turquoise => "turquoise", :broken_content => "turquoise", :info => "turquoise", :sidebar => "turquoise" }
    theme_translate[theme_type]
  end
  
  # returns the color based on the theme object
  def theme_color(theme_object=current_theme)
    if theme_object
      return theme_object[:color].to_s.downcase if theme_object[:color]
      return theme_name_color(theme_object[:type]) if theme_object[:type]
    end
  end

  # returns the theme name given the model class
  def theme_name_for_class(klass)
    case klass
    when Kase
      :issue
    else
      :profile
    end
  end
  
  # predicts a theme name for a object, record or collection of records
  def theme_name_for(something, default=nil)
    if something.is_a?(Class)
      them_name_for_class(something)
    elsif something.is_a?(Array)
      if something.first.nil? 
        default || :profile
      else
        theme_name_for_class(something.first.class)
      end
    else
      # record object
      theme_name_for_class(something.class)
    end
  end

  # sets theme if it is not already set. if theme is already set, do nothing.
  def verify_or_set_theme(options={})
    set_theme(options) unless self.theme
  end

  # Switches to the style within the block, or from this line onwards
  # It is also possible to set the theme context, which is the 
  #
  # Usage:
  #
  #   switch_theme :theme => :issue, :context => :primary_content do 
  #     ...
  #   end 
  #   # now previous theme is active again
  #
  def switch_theme(options={}, &block)
    @save_probono_theme = self.theme
    set_theme(options)
    @save_theme_context_switch_theme = @theme_context
    @theme_context = @theme[options[:context]]
    yield
    @theme_context = @save_theme_context_switch_theme
    @theme = @save_probono_theme
  end

  # Parent of all the containers. Adds a bracket container. This is not used that often, but anyway, it's there
  #
  # Usage:
  #   :theme => :issue, :comment, etc.
  # alernatively
  #   :type => :issue
  def content_container(options={}, &proc)
    set_theme(options)
    bracket_container(options, &proc)
  end
  
  # dito, but with if condition
  def content_container_if(condition, options={}, &proc)
    content_container(options, &proc) if condition
  end

  # dito, but with unless condition
  def content_container_unless(condition, options={}, &proc)
    content_container(options, &proc) unless condition
  end

  # Nothing but a simple bracket with content directly rendered
  def simple_content_container(options={}, &proc)
    content_container(options.merge(:with_content => true), &proc)
  end

  # Selector of headline
  def headline(options={}, &proc)
    o = {:title => '', :theme => self.theme[:theme], :stars_theme => self.theme[:theme] }.merge(options)
    unless self.theme[:headline].nil?
     o = o.merge(self.theme[:headline])
    end
    o = o.merge(options)
 
    case self.theme[:type]
      when 'broken_content'
        widget_broken_container o, &proc
      when 'sidebar'
        widget_simple_container o, &proc
      when 'comment'
        unless o[:stars].nil?
         widget_container o, &proc
        else
          widget_simple_container o, &proc
        end
      when 'info'
        unless o[:stars].nil?
         widget_container o, &proc
        else
          widget_simple_profile o, &proc
        end
      when 'case', 'response'
        widget_container o, &proc
      when 'form'
        widget_form_container o, &proc
    end
  end
  
  # dito but with if condition
  def headline_if(condition, options={}, &proc)
    headline(options, &proc) if condition
  end

  # Calls the partial in partial_name, where partial_name is 'foo'
  # the partial file is _foo.rhtml, and stored in /apps/views
  # Example: block_to_partial "shared/foo" do ... end
  def block_to_partial(partial_name, options = {}, &block)
    if block_given? && !options[:body]
      options.merge!(:body => capture(&block))
      concat(render(:partial => partial_name, :locals => options))
    else
      render(:partial => partial_name, :locals => options)
    end
  end

  def bracket_container_if(condition, options={}, &proc)
    bracket_container(options, &proc) if condition
  end

  def bracket_container_unless(condition, options={}, &proc)
    bracket_container(options, &proc) unless condition
  end

  # Used in content_containers
  #
  # Options:
  #   :with_content => true   adds a div container for rendering text without any other content
  #
  def bracket_container(options={})
    defaults = {:with_content => false}
    options = defaults.merge(options).symbolize_keys
    
    with_content = options.delete(:with_content)

    verify_or_set_theme :theme => :form
    style = self.theme[:bracket_container]
    
    concat tag(:div, {:id => options[:id]}, true) if options[:id]
    concat content_tag(:div, '' , {:class => "bracketBox#{style}Top"})
    concat tag(:div, {:class => "bracketBox#{style}Middle"}, true)
    concat tag(:div, {:class => "bracketBoxContent"}, true) if with_content
    yield
		concat "</div>" if with_content
    concat div_tag(:class => 'clearClass')
		concat "</div>"
    concat content_tag(:div,'', { :class => "bracketBox#{style}Bottom" })
		concat "</div>" if options[:id]
  end

	def widget_simple_container(options = {})
    # set default options
    o = { :class => "#{self.theme[:theme]}Top", :title => ''}.merge(options)
		title = o.delete(:title)    
		concat tag(:div, o , true)
    concat title
		yield
		concat "</div>"
	end

	def widget_broken_container(options = {})
    # set default options
    o = { :class => "#{self.theme[:theme]}Top"}.merge(options)
		concat tag(:div, o , true)
		yield
		concat "</div>"
	end

	def widget_simple_profile(options = {}, &proc)
    # set default options
    o = { :title => '', 
              :theme => 'turquoiseBox'}.merge(options)


    theme = o.delete(:theme)

    o[:class_header] ||= "#{theme}Header"
    o[:class_header_inner] ||= "#{theme}HeadlineInner"
    o[:class_header_content] ||= "#{theme}HeadlineInnerContent"


    title = o.delete(:title)
    class_header = o.delete(:class_header)
    class_header_inner = o.delete(:class_header_inner)
    class_header_content = o.delete(:class_header_content)
    
    
    concat tag(:div, {:class => class_header} , true)
    concat tag(:div, {:class => class_header_inner} , true)
    concat tag(:span, {:class => class_header_content},true)
    concat title
		yield
		concat "</span>"
		concat "</div>"
		concat "</div>"
	end

	def widget_form_container(options = {}, &proc)
    # set default options
    o = { :class1=>'bracketBoxContent', :class2=>'formBox'}.merge(options)
		concat tag(:div, {:class => o[:class1]} , true)
		concat tag(:div, {:class => o[:class2]}, true)
		yield
		concat "</div>"
		concat "</div>"
	end

  def widget_container(options = {}, &proc)
    # set default options
    o = { :stars => nil, :title => 'Untitled', :stars_comments => nil, :theme => 'tabBoxBlue', :stars_theme => 'tabBoxBlueHeadRating' }.merge(options)
    theme = o.delete(:theme)

    o[:class_header] ||= "#{theme}Header"
    o[:class_header_inner] ||= "#{theme}HeadlineInner"
    o[:class_header_content] ||= "#{theme}HeadlineInnerContent"


    title = o.delete(:title)
    stars = o.delete(:stars)
    class_header = o.delete(:class_header)
    class_header_inner = o.delete(:class_header_inner)
    class_header_content = o.delete(:class_header_content)
		stars_theme = o.delete(:stars_theme)
    stars_comments = o.delete(:stars_comments)
    
    unless stars.nil?
      stars = stars.to_i
      active_stars = (stars > MAX_STARS) ? MAX_STARS : stars 
      inactive_stars = MAX_STARS - stars 
    end
    
    concat tag(:div, {:class => class_header} , true)
    concat tag(:div, {:class => class_header_inner} , true)
    concat tag(:h2, {:class => class_header_content},true)
    concat title
    yield
    concat "</h2>"
    concat "</div>"
    #stars
    unless stars.nil?  
      concat tag(:div, {:class => "#{theme}HeadRating"} , true)
      active_stars.times {
        concat tag(:span, {:class => "#{stars_theme}StarActive"},true)
        concat '&nbsp;'
        concat "</span>"
      } 
      inactive_stars.times {
        concat tag(:span, {:class => "#{stars_theme}StarInactive"},true)
        concat '&nbsp;'
        concat "</span>"
      } 
      #comments
      unless stars_comments.nil?
        concat tag(:br)
        concat tag(:div, {:class => "#{theme}HeadComment"} , true)
        concat stars_comments
        concat "</div>"
      end
      concat "</div>" # end div stars
    end
    concat "</div>" # end div #{theme}Header
  end

	def widget_footer(options = {}, &proc)
    # set default options
    o = { :class => 'listBoxFooter' }.merge(options)
		concat tag(:div, o , true)
		yield
		concat "</div>"
		concat clearClass
	end

  def info_container(options = {}, &proc)
   # set default options
   o = {:step => '1', 
            :title => 'Title', 
            :text => 'Text',
            :type => 'Normal',
            :header => 'Header'}.merge(options)
  
    case o[:type].capitalize
      when "Warning"
        o[:theme] = 'Yellow'
        o[:icon] = '/images/css/icon_warning.png'
        o[:icon_small] = '/images/css/icon_warning_small.png'
      when "Error"
        o[:theme] = 'Red'
        o[:icon] = '/images/css/icon_error.png'
        o[:icon_small] = '/images/css/icon_error_small.png'
      else
      #Normal
        o[:theme] = 'Turquois'
        o[:icon] = '/images/css/icon_notice.png'
        o[:icon_small] = '/images/css/icon_notice_small.png'
    end

    concat div_tag({:class=>"box#{o[:theme]}Top"})
    concat tag(:div, {:class => "box#{o[:theme]}Middle"} , true)
    concat tag(:div, {:class => "colouredBoxColumn"} , true)
    concat probono_image({:src => o[:icon], :alt=>"", :width=>"16", :height=>"16"})
    concat '</div>'
    concat tag(:div, {:class => "colouredBoxColumn"} , true)
    concat tag(:div, {:class => "colouredBoxHeadline"} , true)
    concat "#{o[:header]} "
    concat probono_image({:src => o[:icon_small], :alt => o[:type], :width=>"12", :height=>"12"})
    concat '</div>'
    concat o[:title]
    concat '</div>'
    concat div_tag({:class=>"clearClass"})
    concat '</div>'
    concat div_tag({:class=>"box#{o[:theme]}Bottom"})
    concat tag(:div, {:class => "bracketBoxContent"} , true)
    concat tag(:div, {:class => "numberHeadlineNumber"} , true)
    concat div_tag({:class=>"step#{o[:step]}"})
    concat '</div>'
    concat tag(:div, {:class => "numberHeadlineText"} , true)
    concat o[:text]
    concat '</div>'
    yield
    concat div_tag({:class=>"clearClass"})
    concat '</div>'
  end

  # Adds a line to seperate content in overview sections
  def widget_overview_delimiter
    div_tag( :style => "border-top:1px solid;margin:5px 0 5px -5px" )
  end

  # This tag is used to declare a div area for the overview sections on top
  # of the issue, reponse and profile. 
  # The default set theme is used if not otherwise declared in options.
  # Usage: content_overview_container :type => :issue
  def content_overview_container(options={}, &proc)
    verify_or_set_theme(options)
    @save_theme_context_contact_container = @theme_context
    @theme_context = self.theme[:contact_container]
    div_tag :class => @theme_context[:class], &proc
    @theme_context = @save_theme_context_contact_container
  end


  #---------------------------------------------------------------------------------------------------------------------------------
  # content helpers
  #---------------------------------------------------------------------------------------------------------------------------------

  # main content area
  def content_left
    concat tag(:div, {:id => 'contentColumnLeft'}, true)
      concat tag(:div, { :class => 'contentContainerLeft' }, true)
        yield
      concat '</div>'
    concat '</div>'
  end

  # main content for modal dialog
  def content_modal(content=nil, &block)
    @uses_modal = true
    content ||= capture(&block)
    html = tag(:div, {:id => 'contentColumnModal'}, true)
      html += tag(:div, { :class => 'contentContainerLeft' }, true)
        html += content
      html += '</div>'
    html += '</div>'
    if block_given? 
      concat html
    else
      html
    end
  end

  def content_modal_with_content(content)
    @uses_modal = true
    html = tag(:div, {:id => 'contentColumnModal'}, true)
      html += tag(:div, { :class => 'contentContainerLeft' }, true)
        html += content
      html += '</div>'
    html += '</div>'
  end

  # sidebar area
  def content_right
    # set default options
    concat tag(:div, {:id => 'contentColumnRight'}, true)
      concat tag(:div, {:class => 'contentContainerRight'}, true)
        yield
      concat '</div>'
    concat '</div>'
  end

  # used in layout for search bar...i think
  def content_top(options = {})
    concat tag(:div, {:id => "contentTopRow"}, true)
    yield
    concat '</div>'
  end

  # list container for sidebar actions
  def sidebar_actions_elements(options= {}, &proc)
    concat tag(:ul, {:class => "sideBarActionElements"}, true)
		yield
    concat '</ul>'
  end

  # Provides a sidebar menu container for actions, e.g. "Send invitation"
  # Options:
  #   :title => "Action"
  #   
  def sidebar_actions_container(options={}, &proc)
    partial_name = 'shared/sidebar_actions_container'
    if block_given? && !options[:body] && body = capture(&proc)
      unless body.blank?
        options.merge!(:body => body)
        concat(render(:partial => partial_name, :locals => options))
      end
    else
      render(:partial => partial_name, :locals => options)
    end
  end
  
  # Provides a context, like person profile, and a secondary container for actions, 
  # like "Send invitation".
  #
  # e.g.
  #
  #   <% sidebar_context_actions_container(:partial => 'people/sidebar_item_content',
  #     :object => person, :locals => {}) do %>
  #      ...
  #   <% end %>
  #   
  def sidebar_context_actions_container(options={}, &proc)
    context = nil
    if partial_name = options.delete(:partial)
      object = options.delete(:object)
      locals = options.delete(:locals) || {}
      context = render(:partial => partial_name, :object => object, :locals => locals)
    end
    options.merge!(:context => context)
    block_to_partial('shared/sidebar_context_actions_container', options, &proc)
  end

  # dito with if
  def sidebar_context_actions_container_if(condition, options={}, &proc)
    sidebar_context_actions_container(options, &proc) if condition
  end

  # dito with unless
  def sidebar_context_actions_container_unless(condition, options={}, &proc)
    sidebar_context_actions_container(options, &proc) unless condition
  end

  # Offers a link_to function for actions in the sidebar action container
  # Options:
  #   :icon => :plus | :minus | :action
  #
  # <li class="sideBarActionElement">
  #  <div class="actionButtonBox">
  #    <div class="buttonActionTurquoise"><a href="#"></a></div>
  #  </div>
  # <a href="#"></a>
  # </li>
  def sidebar_action_link_to(name, options={}, html_options={})
    html_defaults = {:icon => :action, :link_method => :link_to}
    html_options = html_defaults.merge(html_options).symbolize_keys

    button_class = case html_options.delete( :icon )
      when :minus then 'buttonMinusTurquoise'
      when :plus then 'buttonPlusTurquoise'
      else 'buttonActionTurquoise'
    end 

    link_method = html_options.delete(:link_method) || :link_to

    button_html = content_tag(:div, send(link_method, '', options, html_options), :class => button_class)
    link_html = send(link_method, name, options, html_options)

    html = ''
    html << tag(:li, {:class => 'sideBarActionElement', :id => html_options.delete(:id)}, true)
      html << content_tag(:div, button_html, :class => 'sideBarActionElementLeft')
      html << content_tag(:div, link_html, :class => 'sideBarActionElementRight')
      html << content_tag(:div, '', :class => 'clearClass')
    html << '</li>'
  end
  
  # same as dito but with a link to facebox, used in kases/show send email
  def sidebar_action_remote_facebox_link_to(name, options = {}, html_options={})
    sidebar_action_link_to(name, options, {:link_method => :link_to_remote_facebox}.merge(html_options))
  end

  # adds condition to sidebar_action_link_to
  def sidebar_action_link_to_if(condition, name, options = {}, html_options={})
    sidebar_action_link_to(name, options, html_options) if condition 
  end
  
  def sidebar_action_link_to_unless(condition, name, options = {}, html_options={})
    sidebar_action_link_to(name, options, html_options) unless condition 
  end

  # Offers a mail_to function for actions in the sidebar action container
  # usage is similar to sidebar_action_link_to and mail_to
  def sidebar_action_mail_to(name, email_address, options = {}, html_options={})
    html_defaults = {:icon => :action}
    html_options = html_defaults.merge(html_options).symbolize_keys

    button_class = case html_options.delete( :icon )
      when :minus then 'buttonMinusTurquoise'
      when :plus then 'buttonPlusTurquoise'
      else 'buttonActionTurquoise'
    end 

    button_html = content_tag(:div, mail_to(email_address, '', options), :class => button_class)
    link_html = mail_to(email_address, name, options)

    html = ''
    html << tag(:li, {:class => 'sideBarActionElement', :id => html_options.delete(:id)}, true)
    html << content_tag(:div, button_class, :class => 'sideBarActionElementLeft')
    html << content_tag(:div, link_html, :class => 'sideBarActionElementRight')
    html << '</li>'
  end

  # remote link for sidebar actions
  def sidebar_action_link_to_remote(name, options = {}, html_options={})
    html_defaults = { :icon => :action }
    html_options = html_defaults.merge(html_options).symbolize_keys

    button_class = case html_options.delete( :icon )
      when :minus then 'buttonMinusTurquoise'
      when :plus then 'buttonPlusTurquoise'
      else 'buttonActionTurquoise'
    end 

    html = ''
    html << tag(:li, {:class => 'sideBarActionElement', :id => html_options.delete(:id)}, true)
      html << content_tag(:div, content_tag(:div,
        link_to_remote('', options, html_options),
        :class => button_class
      ), :class => 'actionButtonBox')
      html << link_to_remote(name, options, html_options)
    html << '</li>'
  end

  # adds condition to sidebar_action_link_to
  def sidebar_action_link_to_remote_if(condition, name, options = {}, html_options={})
    sidebar_action_link_to_remote(name, options, html_options) if condition 
  end
  
  def sidebar_action_link_to_remote_unless(condition, name, options = {}, html_options={})
    sidebar_action_link_to_remote(name, options, html_options) unless condition 
  end

  # addes a horizontal separator
  def sidebar_action_separator(options={})
    content_tag(:div, '', { :class => "sideBarActionSeparator" }.merge(options) )
  end

	def broken_content(options = {}, &proc)
    # set default options
    o = {:class=>'contentColumnLeftTwoColumnBox'}.merge(options)
    concat tag(:div, o, true)
    unless o[:partial].nil?
      concat render(:partial => o[:partial])
    end
		yield
    concat '</div>'		
    concat div_tag({:class => 'clearClass'})
  end

  def broken_content_left(options = {}, &proc)
    # set default options
    o = {:class=>'contentColumnLeftColumnLeft'}.merge(options)
    concat tag(:div, o, true)
    yield
#    concat div_tag({:class => 'clearClass'})
    concat '</div>'		
  end

  def broken_content_right(options = {}, &proc)
      broken_content_left({:class=>'contentColumnLeftColumnRight'}.merge(options), &proc)
  end

  # primary content defines the main content withing a content_container
  def primary_content(options = {}, &proc)
    @save_theme_context_primary_content = @theme_context
    @theme_context = @theme[:primary_content]
    defaults = {:class => @theme_context[:class]}
    html_class = options.delete(:class)
    options = defaults.merge(options).symbolize_keys
    last = !!options.delete(:last)
    
    options[:class] = "#{options[:class]} #{html_class}"
    options[:style] = "padding-bottom:0px;#{options[:style]}" if last
    
    # set default options
    concat tag(:div, options, true)
    yield
    concat probono_clear_class
    concat '</div>'
    concat( content_tag(:div, '', @theme_context[:bottom]) ) if last
    @theme_context = @save_theme_context_primary_content
  end

  # secondary content defines all content that is shows in tabs 'below' the primary content
  def secondary_content(options = {}, &proc)
    @save_theme_context_secondary_content = @theme_context
    @theme_context = @theme[:secondary_content]
    # set default options
 		o = {}.merge(@theme_context).merge(options)

    o[:href] ||= '#'
    o[:key] ||= 'subcontent'
    @secondary_content_index = (o[:index] ||= @secondary_content_index ? @secondary_content_index += 1 : 0)
    o[:class] ||= "tabBox#{o[:theme]}ContentSub"
    o[:id] ||= "#{o[:theme].downcase}#{o[:key]}#{o[:index]}"
    o[:display] ||= o[:open] || false
    o[:style] = ("#{o[:display] ? '' : 'display:none'};" ) + "#{o[:style]}"

    concat tag(:div, {:class => o[:class], :id => o[:id],
      :style => o[:style]} , true) 
    yield
    concat probono_clear_class
    concat '</div>'
    @theme_context = @save_theme_context_secondary_content
  end
  
  # Slider control substituting the tabs
  def slider_control(options={}, &block)
    defaults = {:index => @secondary_content_index || 0, :last => true, :open => false}
    options = defaults.merge(options).symbolize_keys

    secondary_content=self.theme[:secondary_content]
    slider_control = self.theme[:slider_control]
    circle_color = self.theme[:color].downcase

    control_id = options[:control_id] ||= "#{secondary_content[:theme].downcase}subcontent#{options[:index]}"
    html_class = slider_control[:class] || "commentsSliderControl"
    last = !!options.delete(:last)
    html_style = last ? 'border-bottom:0px;' : 'padding-bottom:5px;'
    content = capture(&block)
    open_circle_image_tag = content_tag(:div, image_tag( "icons/circles/plus_#{circle_color}_small.gif", :title => "open".t ), :style => "float:right;")
    close_circle_image_tag = content_tag(:div, image_tag( "icons/circles/cross_#{circle_color}_small.gif", :title => "close".t ), :style => "float:right;")
    opening_circle_image_tag = content_tag(:div, image_tag( "icons/circles/spin_#{circle_color}_small.gif" ), :style => "float:right;")
  	open_text = content +	open_circle_image_tag
  	close_text = content + close_circle_image_tag
  	opening_text = content + opening_circle_image_tag

  	# content
    concat(tag(:div, {:id => options[:id], :class => html_class, :style => html_style}, true) )
    if options[:url]
      concat(
        flipper_remote_link_to(control_id, {
      		:open_text => open_text,
      		:close_text => close_text,
      		:opening_text => opening_text,
      		:closing_text => opening_text,
      		:display => options[:open],
      		:url => options[:url],
      		:update => control_id,
      		:position => :replace,
      		:duration => 0.3
      	}.merge(options))
      )
    else
      concat(
        flipper_link_to(control_id, {
      		:open_text => open_text,
      		:close_text => close_text,
      		:display => options[:open], 
      		:duration => 0.3
      	}.merge(options))
      )
    end
    concat(probono_clear_class)
    concat('</div>')

    # add rounded bottom
    concat content_tag(:div, '', secondary_content[:bottom]) if last
  end

  # returns an image for the slider control description
  def slider_control_image(source)
    content_tag(:div, image_tag(source, :size => "18x18"), :style => "float:left; padding-right: 5px;")
  end

  # returns the text label for the slider control description
  def slider_control_label(text)
    content_tag(:div, text, :style => "float:left; padding-right: 5px;font-weight:bold;")
  end

  # Keep this, this is used inside the comments for issue
	def bubble_top(options = {}, &proc)
    # set default options
    o = { :text => '', :info => ''}.merge(options)
		text = o.delete(:text)
    concat content_tag(:div, '', { :class => 'bubbleBoxTop' }) 
    concat tag(:div, { :class => 'bubbleBoxMiddle' } , true) 
    concat tag(:div, { :class => 'bubbleBoxContent' } , true) 
    concat text  
		yield
		unless o[:info].empty?
      concat content_tag(:div, o[:info], {:class => 'bubbleBoxInfo'}) 
    end
    concat '</div>'  
    concat '</div>'  
	end

  # Keep this, it is used to display a comment bubble
	def bubble_bottom(options = {}, &proc)
    # set default options
    o = { :text => '', :info => ''}.merge(options)
		text = o.delete(:text)
    concat tag(:div, {:class => 'bubbleBoxMiddle'} , true) 
    concat tag(:div, {:class => 'bubbleBoxContent'} , true) 
    concat text  
		yield
		unless o[:info].empty?
      concat content_tag(:div, o[:info], { :class => 'bubbleBoxInfo' }) 
    end
    concat '</div>'  
    concat '</div>'  
    concat content_tag(:div, '', { :class => 'bubbleBoxTurnedBottom' })
	end

  # this is used in the comment
	def stars_rank_bubble(options = {}, &proc)
    # set default options
    o = { :stars => 0, :align => :right }.merge(options)
		o[:star_img_path] ||= '/images/css/'
		o[:star_img_inactive] ||= 'star_comment_small.png'
		o[:star_img_active] ||= 'star_comment_small_highlight.png'
		stars = o.delete(:stars).to_i
		star_active =  "#{o[:star_img_path]}#{o[:star_img_active]}"
		star_inactive =  "#{o[:star_img_path]}#{o[:star_img_inactive]}"
		active_stars = (stars > MAX_STARS) ? MAX_STARS : stars 
    inactive_stars = MAX_STARS - stars 
		unless o[:align].eql?(:right)
	    concat tag(:div, {:class => 'bubbleBoxTurnedTop'} , true) 
	    concat tag(:div, {:class => 'bubbleBoxTurnedTopContent'} , true) 
		else
	    concat tag(:div, {:class => 'bubbleBoxBottom'} , true) 
		end
		yield
    #stars
   	active_stars.times {
        concat probono_image({:src => star_active, :alt => '', :style => 'vertical-align: middle;' })
        concat '&nbsp;'
    } 
    inactive_stars.times {
        concat probono_image({:src => star_inactive, :alt => '', :style => 'vertical-align: middle;'})
        concat '&nbsp;'
    } 
		unless o[:align].eql?(:right)
	   	concat '</div>'
		end    
		concat '</div>'  	
	end

  # This is just the info container coming out of the bubble, meaning a single comment
  # Options:
  #   :align => :left | :right
	def comment_info_container(options = {}, &proc)
    # set default options
    o = { :align => :right }.merge(options)
		unless o[:align].eql?(:right)
	    concat tag(:div, {:class => 'bubbleBoxTurnedTop'} , true) 
	    concat tag(:div, {:class => 'bubbleBoxTurnedTopContent'} , true) 
		else
	    concat tag(:div, {:class => 'bubbleBoxBottom'} , true) 
		end
		# yield
		concat capture(&proc) 
		unless o[:align].eql?(:right)
	   	concat '</div>'
		end    
		concat '</div>'  	
	end

  # this is used in the comment. will only show the stars but does not do any
  # javascript magic for rating, use star_rate_tag and star_rate_remote_tag instead
	def stars_tag(options = {}, &proc)
    # set default options
    o = { :stars => 0, :tag => :div }.merge(options)
		o[:star_img_path] ||= 'css/'
		o[:star_img_inactive] ||= 'star_comment_small.png'
		o[:star_img_active] ||= 'star_comment_small_highlight.png'
		tag_name = o.delete(:tag)
		stars = o.delete(:stars).to_i
		star_active =  "#{o[:star_img_path]}#{o[:star_img_active]}"
		star_inactive =  "#{o[:star_img_path]}#{o[:star_img_inactive]}"
		active_stars = (stars > MAX_STARS) ? MAX_STARS : stars 
    inactive_stars = MAX_STARS - stars 
    # generate stars
    html = ''
   	active_stars.times {
        html << image_tag(star_active, :alt => '', :style => 'vertical-align: middle;')
        html << '&nbsp;'
    } 
    inactive_stars.times {
        html << image_tag(star_inactive, :alt => '', :style => 'vertical-align: middle;')
        html << '&nbsp;'
    } 
    if block_given?
      concat tag(tag_name, options , true)
      concat html
      yield
  		concat "</#{tag_name}>"
    else
      content_tag(tag_name, html, options)
    end
	end

  # Uses the stars_rate_field_tag and wraps it with a from tag in order
  # to make an interactive star rating with submit to remote function
  # Options:
  # options are the same as star_rate_field_tag
  # remote_options are the same as with remote_function
  def stars_rate_remote_tag(name, value, remote_options={}, options={}, &proc)
    defaults = { :form_id => "#{name}_form" }
    options = defaults.merge(options).symbolize_keys
    remote_defaults = { :submit => options[:form_id] }
    remote_options = remote_defaults.merge(remote_options).symbolize_keys
    form_id = remote_options[:submit]
    html = ''
    html << form_tag({}, { :id => form_id })
    html << stars_rate_field_tag(name, value, options.merge( :function => remote_function(remote_options) ), &proc )
    html << "</form>"
    html
  end

  # Taken from star_rate
  # Usage:
  #   name => name for the tag
  #   value => 1..5
  # Options:
  #   :tag => tag name to wrap (rest of options work towards that tag)
	def stars_rate_field_tag(name, value, options = {}, &proc)
    # set default options
    o = {
      :tag => :div,
      :star_img_inactive => 'star_comment.png',
      :star_img_path => '/images/css/',
      :star_img_active => 'star_comment_highlight.png'
		}.merge(options)
		stars = value.to_i
		star_active =  "#{o[:star_img_path]}#{o.delete(:star_img_active)}"
		star_inactive =  "#{o[:star_img_path]}#{o.delete(:star_img_inactive)}"
		o.delete(:star_img_path)
		tag_name = o.delete(:tag)
		active_stars = (stars > MAX_STARS) ? MAX_STARS : stars 
    inactive_stars = MAX_STARS - stars 
    # function
    if o[:function]
      o[:onclick] = "javascript:#{o[:function]};"
      o.delete(:function)
    end
		# js
		onclick = <<-EOS
      e = getElementsByName('#{name}star');
      for(i=0;i<e.length;i++){
        if(e[i].getAttribute('index')<= this.getAttribute('index') )
          {e[i].src = '#{star_active}'}
        else{e[i].src = '#{star_inactive}'}
          e[i].onmouseover='';//For compatibility IE;
          e[i].removeAttribute('onmouseover');
          getElementById('#{name}_value').value = parseInt(this.getAttribute('index'))+1;
          };
    EOS
    
    onmouseover = <<-EOS
      e = getElementsByName('#{name}star');
      for(i=0;i<e.length;i++){
        if(e[i].getAttribute('index')<= this.getAttribute('index') )
          {e[i].src = '#{star_active}'}
        else{e[i].src = '#{star_inactive}'}
          };
    EOS
    # stars
    html = ''
    MAX_STARS.times do |t|
      html << probono_image(
                  :index => "#{t}",
                  :name => name+'star',
                  :src => t>active_stars-1 ? star_inactive : star_active,
                  :alt => '',
                  :style => 'cursor:pointer;vertical-align: middle;',
                  :onclick => onclick,
                  :onmouseover => onmouseover
              )
      html << '&nbsp;'
    end
    html << hidden_field_tag("rating", stars, :id => "#{name}_value")
		
    if block_given?
      concat tag(tag_name, o , true)
      concat html
  		concat "</#{tag_name}>"  	
      if content=capture(&proc)
        concat content
      end
    else
      content_tag(tag_name, html, o)
    end
	end

  # This is used to rate a response, for example (remember, large stars)
  # Not sure what the difference is to the stars_rate????
  # TODO: this becomes obsolete as it is replaced by stars_tag
	def stars_rate(options = {}, &proc)
    # set default options
    o = { :stars => 0,
							:name => 'stars_rate',
							:class => 'commentsStarBox',
							:style => '',
							:star_img_inactive => 'star_comment.png',
							:star_img_path => '/images/css/',
							:star_img_active => 'star_comment_highlight.png'}.merge(options)
		stars = o.delete(:stars)		
		star_active =  "#{o[:star_img_path]}#{o[:star_img_active]}"
		star_inactive =  "#{o[:star_img_path]}#{o[:star_img_inactive]}"
		active_stars = (stars > MAX_STARS) ? MAX_STARS : stars 
    inactive_stars = MAX_STARS - stars 
    concat tag(:div, { :class => o[:class], :style => o[:style] } , true)
		yield
    #stars
   	active_stars.times do |t|
        concat probono_image({:index => "#{t}", :name => 'star',  :src => star_active, :alt => ''})
        concat '&nbsp;'
    end 
    inactive_stars.times do |t|
        concat probono_image({:index => "#{t}", :name => 'star', :src => star_inactive, :alt => '', :style => 'cursor:pointer;',
																								:onclick => "e = getElementsByName('star');
																																			for(i=0;i<e.length;i++){
																																				if(e[i].getAttribute('index')<= this.getAttribute('index') )
																																					{e[i].src = '#{star_active}'}
																																				else{e[i].src = '#{star_inactive}'}
																																				e[i].onmouseover='';//For compatibility IE;																																			
																																				e[i].removeAttribute('onmouseover');
																																				getElementById('#{o[:name]}').value = parseInt(this.getAttribute('index'))+1;																																			
																																			};",
																								:onmouseover => "e = getElementsByName('star');
																																			for(i=0;i<e.length;i++){
																																				if(e[i].getAttribute('index')<= this.getAttribute('index') )
																																					{e[i].src = '#{star_active}'}
																																				else{e[i].src = '#{star_inactive}'}
																																			};"})
        concat '&nbsp;'
    end 
		concat hidden_field_tag(o[:name],stars)
		concat '</div>'  	
	end

  # this is used for displaying a bracket over assets, basically to group
  # private, public assets, not sure if this will go away
  def top_bracket_content(options = {}, &proc)
    # set default options
    o = { :title => 'untitled:'}.merge(options)
    concat tag(:ul, { :class => "topBracketBox"} , true) 
    concat "<h4>#{o[:title]}</h4>"     
    concat "<h5>"     
    concat tag(:div, { :class => "topBracketBoxLeft"} , true) 
    concat '</div>'     
    concat "</h5>"     
    yield
    concat tag(:div, {:class => "clearClass"} , true)
    concat '</div>'
    concat '</ul>'     
  end 
 
  # Provide the image as components of :img_path and :icon or 
  # submit the entire image tag as :image
  # Options:
  #   :id => ID reference
  #   :href => Reference to the resource this item points to
  #   :icon_img => Representation of item (<img .../>)
  #   :icon_href => Representation of item href
  #   :delete_href => Url to call when deleting this 
  def top_bracket_items(options = {}, &proc)
    # set default options
    o = { :href => '#', :icon_href => '#' }.merge(options)
    concat tag(:li, { :id => options[:id], :style => options[:style] }, true)    
    concat o[:icon]
    if o[:delete_href]
      concat tag(:span, {:class => "buttonMinus"} , true)
      concat tag(:a, { :href => o[:delete_href] }, true)
      concat '</a>'     
      concat '</span>'     
    end
    concat tag(:div, {:class => "clearClass"} , true)
    concat '</div>'
    yield
    concat '</li>'           
  end

  # <span id="username-spinner" style="display: none ">
  # 	<%= image_tag 'spinner.gif' %>
  # </span>
  def progress_spinner(options = {})
    defaults = {
      :display => false,
      :color => (self.theme[:color] rescue "Turquoise"),
      :tag => :span,
      :img_path => 'css/'
    }
    options = defaults.merge(options).symbolize_keys
    options[:style] = ( options.delete(:display) ? '' : "display: none;" ) + "#{options[:style]};"
    unless "img"==options[:tag].to_s
      options.delete(:img_path)  # not needed here
      options[:class] = "spinner" + options.delete(:color).to_s.capitalize + " #{options[:class]}"
      content_tag( options.delete(:tag), "", { :style => 'vertical-align:middle;' }.merge(options) )
    else
      options.delete(:tag)
      image_tag( "#{options.delete(:img_path)}spinner_#{options.delete(:color).downcase}.gif", options)
    end
  end

  # Alias for progress_spinner
  def progress_spinner_tag(options = {})
    progress_spinner(options)
  end

  # renders step interface used in wizards
  def probono_step(options = {}, &proc)
    defaults = { :step => :check, :class => 'formBoxColumnLeft'}
    options = defaults.merge(options).symbolize_keys
    
    case options[:step]
    when :check, :ok
      options[:step] = "stepCheck"
    when :question, :questionmark
      options[:step] = "stepQuestion"
    when 1..5
      options[:step] = "step#{options[:step]}"
    end
    
    if block_given?
      concat tag(:div, { :class => options[:class] }, true)
      yield
      concat '</div>'
    else
      content_tag(:div, content_tag(:div, '', { :class => options[:step] } ), { :class => options[:class] })
    end    
  end

  # The button tag will take all options described below. If now :href option is given
  # it will take all of the remaining given options for an url_for.
  # Options:
  #   :label => "Post"
  #   :href => "http://probono.net"
  #   :onclick => "this.disable;"
  #   :function => javascript function
  #   :theme => :form | :case | :response | :comment ( :turquoise | :blue | :green )
  #   :type => :active | :passive ( also: :normal | :cancel )
  #   :position => :left | :right
  #   :id => Id of the Anchor element
	def probono_button(options = {}, &proc)
    verify_or_set_theme
    options = {:label => '', :href => '#', :type => :active,
      :function => '', :theme => @theme[:type].to_sym,
      :outer_div_options => {}, :anchor_options => {}, :left_inner_div_options => {}, :inner_div_options => {},
      :background_color => @theme_context ? @theme_context[:background_color] : nil
    }.merge(options).symbolize_keys
    theme_translate = { :form => "turquoise", :response => "green", :case => "blue", :comment => "blue", :green => "green", :blue => "blue", :turquoise => "turquoise", :broken_content => "turquoise", :info => "turquoise", :sidebar => "turquoise" }
    type_translate = { :normal => "Normal", :active => "Normal", :default => "Normal", :cancel => "Cancel", :passive => "Cancel" }
    content = ""
    content = capture(&proc) if block_given?
    
    # url -> href
    if options[:url]
      options[:href] = case options[:url]
      when String
        options[:url]
      when :back
        @controller.request.env["HTTP_REFERER"] || 'javascript:history.back()'
      else
        self.url_for(options[:url])
      end
    end

    # position the button left or right
    if options[:outer_div_options][:style] && options[:position]
      options[:outer_div_options][:style] = "#{options[:outer_div_options][:style]};#{options[:position].to_sym == :left ? 'float:left;' : 'float:right;'}"
    elsif options[:position]
      options[:outer_div_options][:style] = "#{options[:position].to_sym == :left ? 'float:left;' : 'float:right;'}"
    end
    
    # display
    if (display = options.delete(:display)).is_a?(FalseClass)
      if options[:outer_div_options][:style]
        options[:outer_div_options][:style] = "#{options[:outer_div_options][:style]};display:none;" if display.is_a?(FalseClass)
      else
        options[:outer_div_options][:style] = "display:none;" if display.is_a?(FalseClass)
      end
    end

    # merge the tag options
    options[:outer_div_options].merge!({:id => options[:id], :class => "#{theme_translate[options[:theme]]}Button#{type_translate[options[:type]]}"})
    options[:anchor_options].merge!({:href => options[:href]}.merge(:onclick => (options[:onclick] ? "#{options[:onclick]}; " : "") + (!options[:function].empty? ? "#{options[:function]}; return false;" : "") ))
    options[:inner_div_options].merge!({:class => "#{theme_translate[options[:theme]]}Button#{type_translate[options[:type]]}Text"})
    options[:left_inner_div_options].merge!({:class => "#{theme_translate[options[:theme]]}Button#{type_translate[options[:type]]}Left"}.merge(options[:background_color] ? {:style => "background-color: #{options[:background_color]};"} : {}))

    # create html
    html = tag(:div, options[:outer_div_options], true)
      html << tag(:a, options[:anchor_options], true)
        html << content_tag(:span, '', options[:left_inner_div_options])
        html << tag(:span, options[:inner_div_options], true)
          html << "#{options[:label]}#{content}"
        html << '</span>'
      html << '</a>'
    html << '</div>'
    html
	end

  # Generates all sorts of UI buttons as long as they have a DIV representations
  # pencilBlue, etc. CSS classes
  #
  # options:
  #   :function => "alert('hey')"
  #   :url => "http://ti.ny"
  #
  def probono_custom_button(options={}, html_options={})
    verify_or_set_theme
    options = {:function => '', :class_stem => "%{color}", :link_method => :link_to,
      :display => true, :tag => :span}.merge(options).symbolize_keys
    
    onclick = options.delete(:onclick)
    display = options.delete(:display)
    options[:style] = if options[:style]
      "#{options[:style]};#{display ? '' : 'display:none;'}"
    else
      "#{display ? '' : 'display:none;'}"
    end
    function = options.delete(:function)
    tag = options.delete(:tag)
    link_method = options.delete(:link_method) || :link_to
    
    link_html = if options[:url]
      send(link_method, '', options.delete(:url), html_options)
    else
      content_tag(:a, '', html_options.merge({:title => options.delete(:title), 
        :onclick => (onclick ? "#{onclick}; " : "") + (!function.empty? ? "#{function}; return false;" : "")}))
    end
    
    content_tag(tag, link_html, 
      options.merge(:class => options.delete(:class_stem) % {:color => self.theme[:color].to_s.capitalize}))
  end
  
  # Helper function to produce the pencil divs for initiating an in-place edit
  # pencilBlue, etc. CSS classes
  def probono_edit_button(options={}, html_options={})
    probono_custom_button({:class_stem => "pencil%{color}", :title => "Edit".t}.merge(options).symbolize_keys, html_options)
  end
  
  def probono_add_button(options={}, html_options={})
    probono_custom_button({:class_stem => "buttonPlus%{color}", :title => "Add".t}.merge(options).symbolize_keys, html_options)
  end

  def probono_remove_button(options={}, html_options={})
    probono_custom_button({:class_stem => "buttonMinus%{color}", :title => "Remove".t}.merge(options).symbolize_keys, html_options)
  end

  def probono_cancel_button(options={}, html_options={})
    probono_custom_button({:class_stem => "buttonCross%{color}", :title => "Cancel".t}.merge(options).symbolize_keys, html_options)
  end

  def probono_search_button(options={}, html_options={})
    probono_custom_button({:class_stem => "lens", :title => "Search".t}.merge(options).symbolize_keys, html_options)
  end

  def probono_action_button(options={}, html_options={})
    probono_custom_button({:class_stem => "buttonAction%{color}", :title => "Go".t}.merge(options).symbolize_keys, html_options)
  end

  # Linked tag < icon_onclick text_link icon_onclick >	
  # TODO check if obsolete
  def action_tag (options = {}, &proc)
      #Set defaults options
      o = {
        :url => {},
        :text => 'default',
        :remote => {},
        :link => {},
        :icon_left => {},
        :icon_right => {}
      }.merge(options)

      opt_icon_right = o[:icon_right]
      opt_icon_left = o[:icon_left]
      opt_remote = { :url => o[:url] }.merge( o[:remote] )
      opt_link = o[:link]

      if proc
        concat probono_icon_button(opt_icon_right)
        concat li_tagnk_to_remote(o[:text], opt_remote, opt_link)  
#        concat probono_icon_button(opt_icon_left)  
      else
        probono_icon_button(opt_icon_left) + 
        li_tagnk_to_remote(o[:text], opt_remote, opt_link) +
#        probono_icon_button(opt_icon_right)
        clearClass
      end
  
  end

  def probono_icon_button(options = {})
    o={ :href => '#',
            :onclick => '',
            :style => '',
            :class => 'buttonActionTurquoise',
            :class_container => 'actionButtonBox' }.merge(options)
    tag(:div, {:class => o[:class_container]}, true) +
    tag(:div, {:class => o[:class]}, true) +
    "<a href='#{o[:href]}' onclick='#{o[:onclick]}' ></a>" +
    '</div>' +
    '</div>'
  end 

  def ul_tag(*args, &proc)
    content, options = filter_tag_args(*args)
    clear_class = options.delete(:clear)
    if block_given?
      unless update = options.delete(:update)
        concat tag(:ul, options, true)
      end
      yield
      concat( probono_clear_class ) if clear_class
      unless update
        concat '</ul>'
      end
    else
      unless update=options.delete(:update)
        content_tag(:ul, content.to_s + ( clear_class ? probono_clear_class : '' ), options)
      else
        content.to_s
      end
    end
  end

  def ul_tag_if(condition, *args, &proc)
    ul_tag(*args, &proc) if condition
  end
  
  def ul_tag_unless(condition, *args, &proc)
    ul_tag(*args, &proc) unless condition
  end

  def li_tag(*args, &proc)
    content, options = filter_tag_args(*args)
    clear_class = options.delete(:clear)
    if block_given?
      unless update = options.delete(:update)
        concat tag(:li, options, true)
      end
      yield
      concat( probono_clear_class ) if clear_class
      unless update
        concat '</li>'
      end
    else
      unless update=options.delete(:update)
        content_tag(:li, content.to_s + ( clear_class ? probono_clear_class : '' ), options)
      else
        content.to_s
      end
    end
  end

  def li_tag_if(condition, *args, &proc)
    li_tag(*args, &proc) if condition
  end
  
  def li_tag_unless(condition, *args, &proc)
    li_tag(*args, &proc) unless condition
  end

  def probono_image(o = {})
    tag(:img,o,false)
  end  

  def probono_table(options = {}, &proc)
    defaults = { :cellspacing => 0, :cellpadding => 0, :border => 0 }
    options = defaults.merge(options).symbolize_keys
    
    concat tag(:table, options, true)
    yield
    concat '</table>'
  end

  def probono_table_row(options = {}, &proc)
    concat tag(:tr, options, true)
    yield
    concat '</tr>'
  end

  def probono_table_field(options = {}, &proc)
    concat tag(:td, options, true)
    yield
    concat '</td>'
  end

  # helper for tag helpers to filter arguments for conditions and options
  # returns content and options
  def filter_tag_args(*args)
    options = {}
    content = nil
    # filter tag options
    args.each_with_index do |arg, index|
      if arg.is_a?(Hash)
        options.merge!(arg)
      elsif arg.is_a?(String) && index == 0
        content = arg
      elsif arg.is_a?(Array) && index == 0
        content = arg
      end
    end
    content = options.delete(:content) if options[:content]
    content = content.join(options.delete(:join) || '') if content && content.is_a?(Array)
    if options.delete(:display) == false
      options[:style] ? options[:style] += ';display:none;' : options[:style] = 'display:none;'
    end
    return content, options
  end

  # wraps a div tag
  # e.g.
  #   div_tag "hello world!", :class => 'item', :id => 1  #-> <div class="item" id="1">hello world!</div>
  #   div_tag ['one', 'two'], :join => ', ', :class => 'item', :id => 1  #-> <div class="item" id="1">one, two</div>
  #   div_tag :class => do 
  #     ...
  #   end
  def div_tag(*args, &proc)
    content, options = filter_tag_args(*args)
    clear_class = options.delete(:clear)
    if block_given?
      unless update = options.delete(:update)
        concat tag(:div, options, true)
      end
      yield
      concat( probono_clear_class ) if clear_class
      unless update
        concat '</div>'
      end
    else
      unless update = options.delete(:update)
        content_tag(:div, content.to_s + ( clear_class ? probono_clear_class : '' ), options)
      else
        content.to_s
      end
    end
  end

  # div tag with if condition
  def div_tag_if(condition, *args, &proc)
    div_tag(*args, &proc) if condition
  end

  # div tag with unless 
  def div_tag_unless(condition, *args, &proc)
    div_tag(*args, &proc) unless condition
  end

  # wraps content in div tag if content is present
  def div_tag_if_content(content_as_condition, options={})
    div_tag(options.merge(:content => content_as_condition)) unless content_as_condition.blank?
  end
  alias_method :div_tag_unless_blank, :div_tag_if_content

  # wraps a span tag
  # e.g.
  #   span_tag "hello world!", :class => 'item', :id => 1  #-> <span class="item" id="1">hello world!</span>
  #   span_tag :class => 'item' do 
  #     ...
  #   end
  def span_tag(*args, &proc)
    content, options = filter_tag_args(*args)
    if block_given?
      concat tag(:span, options , true)
      yield
      concat '</span>'     
    else
      content_tag(:span, content.to_s, options)
    end
  end

  def span_tag_if(condition, *args, &proc)
    span_tag(*args, &proc) if condition
  end
  
  def span_tag_unless(condition, *args, &proc)
    span_tag(*args, &proc) unless condition
  end

  # wraps content in span tag if content is present
  def span_tag_if_content(content_as_condition, options={})
    span_tag(options.merge(:content => content_as_condition)) unless content_as_condition.to_s.empty?
  end

  # wraps an li tag
  def li_tag(*args, &proc)
    content, options = filter_tag_args(*args)
    if block_given?
      concat tag(:li, options , true)
      yield
      concat '</li>'
    else
      content_tag(:li, content.to_s, options)
    end
  end

  def li_tag_if(condition, *args, &proc)
    li_tag(*args, &proc) if condition
  end
  
  def li_tag_unless(condition, *args, &proc)
    li_tag(*args, &proc) unless condition
  end

  def probono_textarea(name, content = nil, options = {})
    text_area_tag(name, content, options)
  end 

  def clear_class
    div_tag(:class => "clearClass")
  end

  def probono_clear_class
    div_tag(:class => "clearClass")
  end

end
