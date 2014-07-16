module FrontApplicationHelper
  include FrontTagHelper
  include WizardFormHelper
  
  #--- constants
  PLURAL_OBJECT_TO_CONTROLLER_NAMES = {'issues' => 'cases'}

  #--- helpers

  # dummy wrapper for markdown, overrides Rails standard wrapper
  #
  # e.g.
  #
  #   BlueCloth.new("shoot!").to_html
  #
  def markdown(text, options={})
    text.blank? ? "" : BlueCloth.new(text).to_html
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
    defaults = {
      :priority => [],
      :attr_names => {},
      :defaults => true,
      :header => options[:concise] ? "Errors".t : "The following errors occured".t,
      :sub_header => '',
      :type => :error,
      :unique => false,
      :concise => false
    }
    options = defaults.merge(options).symbolize_keys
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
        :object => object_names.collect { |i| i.to_s.humanize.t }.join(", ")
      }
      html = ''
      if errors_count > 0
        switch_theme :theme => current_theme_name do
          if block_given?
            html = block_to_partial('shared/form_error_messages_for', options, &block) 
          else
            # i need to do the following because i want to use this method in controllers and views.
            # i want to avoid a double render exception. therefore, in the controller this will use
            # the render_to_string and when this function is used in the view, it will use the render
            # method.
            if respond_to?(:render_to_string)
              html = render_to_string :partial => 'shared/form_error_messages_for', :locals => options
            else
              html = render :partial => 'shared/form_error_messages_for', :locals => options
            end
          end
        end
      end
      html
    end
  end
  
  # returns true if current logged in user is person or user
  # This is used in profile views where the own profile looks different from other
  # peoples profiles.
  #
  # e.g.
  #
  #   current_user_me? @person  #-> true if @person is me as a logged in user(.person)
  #
  # or
  #
  #   current_user_me?(@person || @user) do
  #     ...
  #   end
  #
  def current_user_me?(user_or_person)
    if user_or_person && current_user
      if user_or_person.is_a?(User)
        yield if block_given? && current_user == user_or_person
        return current_user == user_or_person
      elsif user_or_person.is_a?(Person)
        yield if block_given? && current_user && current_user.person == user_or_person
        return current_user && current_user.person == user_or_person
      end
    end
    false
  end

  # returns true if the current user is a contact of given user/person
  def current_user_friends_with?(user_or_person)
    if user_or_person && current_user
      if user_or_person.is_a?(User)
        yield if block_given? && self.current_user && self.current_user.person.is_friends_with?(user_or_person.person)
        return self.current_user && self.current_user.person.is_friends_with?(user_or_person.person)
      elsif user_or_person.is_a?(Person)
        yield if block_given? && self.current_user && self.current_user.person.is_friends_with?(user_or_person)
        return self.current_user && self.current_user.person.is_friends_with?(user_or_person)
      end
    end
    false
  end

  # returns true if the current user is following given user/person
  def current_user_following?(followable)
    if followable && current_user
      if followable.is_a?(User)
        yield if block_given? && self.current_user && self.current_user.person.following?(followable.person)
        return self.current_user && self.current_user.person.following?(followable.person)
      elsif followable.respond_to?(:followers)
        yield if block_given? && self.current_user && self.current_user.person.following?(followable)
        return self.current_user && self.current_user.person.following?(followable)
      end
    end
    false
  end
  
  # Similar to current_user_me?, this function will check if the given kase, comment, etc.
  # is owned by the currently logged in user
  #
  # e.g.
  #
  #   current_user_my?(@kase)  # -> returns true if this it the case I posted
  #
  #   current_user_my?(@response) do
  #     ...
  #   end
  #
  def current_user_my?(object, &block)
    if object
      if object.is_a?(Kase)
        return current_user_me?(object.person, &block)
      elsif object.is_a?(Response)
        return current_user_me?(object.person, &block)
      elsif object.is_a?(Comment)
        return current_user_me?(object.sender, &block)
      end
    end
    false
  end
  
  # 'added 15 hours ago'
  def added_time_ago_display(object, options={})
    "added %{time} ago".t % {:time => time_ago_in_words(object.created_at)} if object.respond_to?(:created_at) && object.send(:created_at)
  end

  # View helper block to be executed if base_language_only
  def base_language_only
    yield if I18n.default_locale?
  end

  # View helper block to be executed when not base language
  def not_base_language
    yield unless I18n.default_locale?
  end

  #--- asset helpers
  
  # returns a image path source based on the file name passed in
  #
  # e.g.
  #
  #   "test.pdf"  -> "images/icons/file-types/pdf-icon-32x32.gif"
  #   "pdf"       -> "images/icons/file-types/pdf-icon-32x32.gif"
  #
  def file_icon_image_path(file_name=nil, options={})
    defaults = {:size => "32x32", :extension => nil}
    options = defaults.merge(options).symbolize_keys

    if ext = Utility.uniq_file_extname(file_name)
      size = options.delete(:size)
      size = '32x32' unless ['16x16', '32x32'].include?(size)
      source = image_path("icons/file-types/original/#{ext}-icon-#{size}.gif")
    end
  end

  # Returns an image tag <img> based on the filename (extension) passed to
  def file_icon_image_tag(file_name, options={})
    path = file_icon_image_path(file_name, options)
    options.delete(:extension)
    image_tag(path, options)
  end

  # Returns an image path for the graphical representation for asset!
  # As assets are protected by ACLs, they must be retrieved using a
  # action in the controller TODO: def asset() ???. Use :icon => true
  # if you want to force an icon representation of the file. Use
  # :preview => true if you would like to get a preview (if available)
  # otherwise, it will default to and icon.
  #
  # NOTE: This helper requires an action "asset()" present in the 
  #       controller context, if :preview => true.
  #    
  # Options:
  #   :source
  #   :size => '16x16' | '32x32' | etc.
  #   :name => 'preview' | 'icon_16x16' if you have a named file_column
  #   :preview => true   ... returns the source path to a preview 
  #   :crop => '1:1' (default) or whatever rmagick supports
  #   :icon => true ... 
  #   :preview => true, which will display a icon orrepresentation
  #
  def image_asset_path(asset, options={})
    defaults = { :size => '32x32', :preview => false, :crop => "1:1" }
    options = defaults.merge(options).symbolize_keys
    options[:preview] = !options.delete(:icon) if options[:icon]

    size = options[:size]
    crop = options.delete(:crop)
    preview = options.delete( :preview )
    icon = options.delete( :icon )
    source = options.delete( :source )

    return source unless source.to_s.empty?

    if asset.file?
      if preview && !icon && asset.image? && asset.id
        if options[:name].nil?
          case options[:size]
          when /32x32/, /16x16/
            options[:name] = 'icon'
          when /35x35/
            options[:name] = 'thumb'
          when /250x250/
            options[:name] = 'preview'
          else
            size=options[:size].to_s.split('x')
            if size.first.to_i>250 || size.last.to_i>250
              begin 
                # Have RMagick generate a new size
                @image_for_asset_tag_asset = asset
                url_for_image_column( @image_for_asset_tag_asset, "file", :size => "#{size}#{crop.nil? ? '>' : '!'}", :crop => crop, :name => "preview_#{size}" )
                options[:name] = "preview_#{options[:size]}"
              rescue
                options[:name] = 'preview'
              end
            else
              options[:name] = 'preview'
            end
          end
          options.delete(:size)
        end
        source = url_for(
          { :action => 'asset',
            :id => asset.id
          }.merge(options) )
      end  

      if source.to_s.empty? && !asset.file_ext.to_s.empty?
        if ext = Utility.uniq_file_extname(asset.file_ext)
          size = '32x32' unless ['16x16', '32x32'].include?(size)
          source = image_path "icons/file-types/original/#{ext}-icon-#{size}.gif"
        end
      end
    end
    # still empty?
    if source.to_s.empty?
      size = '32x32' unless ['16x16', '32x32'].include?(size)
      source = image_path "icons/file-types/original/blanco-icon-#{size}.gif"
    end
    source
  end

  # Returns an image link of the graphical representation for asset
  # Options:
  #   :size => "<w>x<h>"
  #   see image_for_asset_path options
  #
  def image_asset_tag(asset, options={})
    defaults = { :size => '16x16', :preview => false }
    options = defaults.merge(options).symbolize_keys

    source = image_asset_path(asset, options)
    options.delete( :crop )
    options.delete( :icon )
    options.delete( :preview )
    options.delete( :name )

    # image_tag
    options[:src] = source # image_path( source )
    options[:alt] ||= asset.name
    if options[:size]
      options[:width], options[:height] = options[:size].split("x") if options[:size] =~ %r{^\d+x\d+$}
      options.delete(:size)
    end
    tag("img", options)
  end

  # Provides link to an asset
  def asset_url_for(asset, options={})
    source = options.delete(:source)
    return source unless source.to_s.empty?
    if asset.file?
      source = url_for( :action => 'asset', :id => asset.id, :only_path => false)
    end
    if asset.url?
      source = asset.url
    end
    source
  end

  #--- list helpers

  # returns a unique dom id for the entire list
  #   :kind => unique identifier for the list, e.g. 'received_invitations'
  #   :dom_class => label to override the automatic label, e.g. :dom_class = 'person'
  def list_dom_id(class_or_records, options={})
    options[:dom_class] = dom_class(option[:class]) if options[:class]
    prefix = options[:kind] ? "list_#{options[:kind]}".to_sym : :list
    if options[:dom_class]
      "#{prefix}_#{options[:dom_class]}"
    else
      if class_or_records.is_a? Array
        class_or_records.first.nil? ? "#{prefix}" : dom_class(class_or_records.first, prefix)
      else
        dom_class(class_or_records, prefix)
      end
    end
  end
  
  # provides a unique dom id for the message on top of a list
  # currently there is only one message per list allowed
  #   :kind => unique identifier for the list
  def list_message_dom_id(class_or_records, options={})
    prefix = options[:kind] ? "message_#{options[:kind]}".to_sym : :message
    if class_or_records.is_a? Array
      class_or_records.first.nil? ? "#{prefix}" : dom_class(class_or_records.first, prefix)
    else
      dom_class(class_or_records, prefix)
    end
  end

  # Switches between two states and calls remote
  def expander_remote_link_to(name, options={})
    defaults = { 
      :position => :top,
      :expanded => false,
      :html_options => {}
    }
    options = defaults.merge(options).symbolize_keys
    html_options = options.delete(:html_options)
    html_options = html_options.merge(:rel => "nofollow")
    expanded = options.delete(:expanded)
    # id's
    id = options.delete(:id) || "#{name.to_s.shortcase}"
    id_label   = "#{id}_label"
    id_loading = "#{id}_loading"
    # labels
    open_label    = options.delete(:open_label) || "open"
    loading_label = options.delete(:loading_label) || "loading..."
    close_label   = options.delete(:close_label) || "close"
    # remote options
    options = { :loading => update_page do |page|
      page[id_label].hide
      page[id_loading].show
    end }.merge(options)
    
    remote_link = content_tag(:div, link_to_remote(expanded ? close_label : open_label, options, html_options), 
      :id => id_label)
    loading = content_tag(:div, loading_label, :id => id_loading, :style => 'display:none;')
    remote_link + loading
  end
  
  # shows the list item expander, renders depending on theme
  def list_item_expander(object, expanded=false, options={})
    controller_name = PLURAL_OBJECT_TO_CONTROLLER_NAMES[plural_class_name(object)] || plural_class_name(object)
    name = object.respond_to?(:title) ? h(object.title) : (object.respond_to?(:name) ? h(object.name) : '')
    url = options.delete(:url) || {}
    if url.is_a?(Hash)
      url = {:controller => controller_name, :action => 'list_item_expander', 
        :id => object, :expanded => expanded ? "1" : "0"}.merge(url)
    end
    
    content_tag(:div,
      expander_remote_link_to(
        dom_id(object, "#{dom_class(object)}_expander"),
        :open_label    => image_tag("icons/circles/plus_#{theme_color}_small.gif", :alt => "#{name}", :title => "#{"More about".t} #{name}", :size => "14x15"),
        :loading_label => image_tag("icons/circles/spin_#{theme_color}_small.gif", :alt => "#{name}", :title => "#{"Loading more about".t} #{name}", :size => "14x15"),
        :close_label   => image_tag("icons/circles/cross_#{theme_color}_small.gif", :alt => "#{name}", :title => "#{"Less about".t} #{name}", :size => "14x15"),
        :expanded => expanded,
        :url => url, 
        :method => :get,
        :update => {:success => dom_id(object), :failure => dom_class(object, :message)},
        :position => :replace
      ),
      :class => "listBoxRightItem"
    )
  end
  
  # dito, but with condition
  def list_item_expander_if(condition, object, expanded=false, options={})
    list_item_expander(object, expanded, options)
  end
  
  #--- list sort helpers

  # container where all list element live in
  # used in _items_list_content partial
  def list_elements_container(options={}, &proc)
    ul_tag({ :class => 'listBoxElements'}.merge(options), &proc)
  end

  # This is used for hosting the sort options for lists. This container is 
  # independent of the used theme
  # used in _items_list_content partial
  def list_overview_container(options={}, &proc)
    verify_or_set_theme(options) # needed for ajax updates
    div_tag( { :class => 'listBoxSubHeader' }.merge(options), &proc ) + probono_clear_class
  end

  # Sort options UL inside lists
  # ul_tag :class => "listBoxSortOptions" do
  def list_sort_options(options={}, &proc)
    ul_tag :class => self.theme[:sort_control][:class], &proc
  end

  # if condiation for list_sort_options
  def list_sort_options_if(condition, options={}, &proc)
    list_sort_options( options, &proc ) if condition
  end
  
  # customized version for sort_link_tag
  # sort_link_tag "Subject".t, 'subject', :html_active_link_options => { :style => 'color: #009ee0;text-decoration: underline;' }
  def list_sort_link_to(text, param, options={})
    defaults = {
      # icons
      :arrow_img_path      => self.theme[:sort_control][:arrow_img_path],
      :arrow_up_active     => self.theme[:sort_control][:up][:image_active],
      :arrow_up_inactive   => self.theme[:sort_control][:up][:image_inactive], # 'icon_arrow_up_over.gif',
      :arrow_down_active   => self.theme[:sort_control][:down][:image_active], # 'icon_arrow_down.gif',
      :arrow_down_inactive => self.theme[:sort_control][:down][:image_inactive], #'icon_arrow_down_over.gif',
      # active
      :html_active_link_options => self.theme[:sort_control][:active]
    }
    options = defaults.merge(options).symbolize_keys
    sort_link_tag(text, param, options)
  end
  
  # Returns the sort link to select sort options
  # text is the "Header" and param the parameter to use for sorting (=column/attr name)
  def sort_link_tag(text, param, options={})
    defaults = { 
      :tag => :li,
      :namespace => nil,
      :html_link_options => {},
      :html_active_link_options => {},
      :html_tag_options => {},
      :html_active_tag_options => {},
      # icons
      :arrow_img_path      => 'css/',
      :arrow_up_active     => 'icon_arrow_up.gif',
      :arrow_up_inactive   => 'icon_arrow_up_over.gif',
      :arrow_down_active   => 'icon_arrow_down.gif',
      :arrow_down_inactive => 'icon_arrow_down_over.gif',
      # remote
      :url => {:action => 'list'},
      :update => 'table',
      :before => "Element.show('#{options[:update] || 'table'}_spinner')",
      :success => "Element.hide('#{options[:update] || 'table'}_spinner')"
    }
    options = defaults.merge(options).symbolize_keys
    # setup
    param = param.to_s
    tag = options.delete(:tag)
    html_link_options = options.delete(:html_link_options)
    html_active_link_options = options.delete(:html_active_link_options)
    html_tag_options = options.delete(:html_tag_options)
    html_active_tag_options = options.delete(:html_active_tag_options)
    # add namespace either :page or :person_page to indicate the page in params
    sort_namespace = options.delete(:namespace)
    page_namespace = sort_namespace
    sort_namespace = ( sort_namespace.to_s.empty? ? :sort : "#{sort_namespace}_sort".to_sym )
    page_namespace = ( page_namespace.to_s.empty? ? :page : "#{page_namespace}_page".to_sym )
    # image setup
    arrow_img_path    = options.delete(:arrow_img_path)  # 'css/'
    arrow_up_active   = image_tag( "#{arrow_img_path}#{options.delete(:arrow_up_active)}" )
    arrow_up_inactive = image_tag( "#{arrow_img_path}#{options.delete(:arrow_up_inactive)}" )
    arrow_down_active = image_tag( "#{arrow_img_path}#{options.delete(:arrow_down_active)}" )
    arrow_down_inactive = image_tag( "#{arrow_img_path}#{options.delete(:arrow_down_inactive)}" )
    # setup
    if active=!(params[sort_namespace].to_s.index(param).nil?) # active?
      arrow_up = params[sort_namespace].to_s.index(/reverse/) ? arrow_up_inactive : arrow_up_active
      arrow_down = params[sort_namespace].to_s.index(/reverse/) ? arrow_down_active : arrow_down_inactive
    else
      arrow_up = arrow_up_inactive
      arrow_down = arrow_down_inactive
    end
    # core
    key = param
    key += "_reverse" if params[sort_namespace] == param
    
    # merge all parameters, (not do this! except those that are already define in :url options)
    options[:url].merge!(:params => params.merge(sort_namespace => key, page_namespace => nil).reject {|k,v| 
      [:action, :controller].include?(k.to_sym)})
    options[:url].delete(:use_route)
    options[:url][:subdomains] = params[:subdomains]
    options[:url][:tier_id] = params[:tier_id]
    options[:url][:only_path] = false
    
    html_options = {
      :title => "Sort by '{field}'".t.gsub(/\{field\}/, text),
      :href => url_for(options[:url]) # url_for(:action => 'list', :params => params.merge(sort_namespace => key, :page => nil))
    }.merge(html_link_options).merge(active ? html_active_link_options : {})
    
    # tag
    content_tag(
      tag,
      arrow_up + "&nbsp;" + link_to_remote(text, options.merge(:method => :get), html_options) + "&nbsp;" + arrow_down,
      html_tag_options.merge(active ? html_active_tag_options : {})
    )
  end
  
  #--- list pagination helpers
  
  # :class => 'listBoxFooterNumberNavi'    "listBoxBlueFooterNumberNavi"
  # <%= pagination_remote_links(
  #   @issue_pages,
  #   :tag => :li,
  #   :html_active_tag_options => {:class => 'listBoxFooterNumberNaviActive'}
  # ) -%>
  def list_paginator(collection, options={})
    options = options.symbolize_keys.merge(:renderer => "FrontApplicationHelper::RemoteLinkRenderer",
      :previous_label => "&larr; #{"Previous".t}",
        :next_label     => 'Next &rarr;')
    if collection.respond_to?(:total_pages)
      will_paginate(collection, options)
    end
  end
  
  # dito, but with if condition
  def list_paginator_if(condition, collection, options={})
    list_paginator(collection, options) if condition
  end
  
  class FrontApplicationHelper::RemoteLinkRenderer < WillPaginate::LinkRenderer

    # remove some attributes for the container
    def html_attributes
      html_options = super
      html_options.delete(:update)
      html_options.delete(:url)
      html_options.delete(:before)
      html_options.delete(:success)
      html_options
    end
    
    protected

    def page_link(page, text, attributes = {})
      link_options = {:url => url_for(page), :method => :get,
        :before => "Element.show('#{@options[:update] || 'table'}_spinner')",
          :success => "Element.hide('#{@options[:update] || 'table'}_spinner')",
            :update => @options[:update] || "table"}
            
      attributes = attributes.merge(:href => url_for(page))
      @template.link_to_remote text, link_options, attributes
    end

    private
  
    def param_name
      namespace = @options[:namespace]
      @param_name ||= namespace.blank? ? @options[:param_name].to_s : "#{namespace}_#{@options[:param_name].to_s}".to_s
    end
  end

  #--- form helpers

  # Options:
  #   :header => 'the title'
  #   :type  => :notice | :warning | :error
  #   :spacer => true || false (space after box)
  def message_container(options={}, &block)
    default = {:theme => current_theme_name}
    options = default.merge(options).symbolize_keys
    block_to_partial( 'shared/message_container', options, &block )
  end

  # dito but with condition
  def message_container_if(condition, options={}, &block)
    message_container(options, &block) if condition
  end

  # dito but with unless condition
  def message_container_unless(condition, options={}, &block)
    message_container(options, &block) unless condition
  end
  
  # Used when steplet is set to :step => :auto to initialize and
  # increment the steplet counter
  def steplet_step_increment
    if instance_variable_get( "@probono_wizard_steplet_step" ).nil?
      @probono_wizard_steplet_step = 1
    else
      @probono_wizard_steplet_step += 1
    end
  end

  # Returns the current step if steplet was set to :auto
  # oterwise return nil
  def steplet_step
    unless instance_variable_get( "@probono_wizard_steplet_step" ).nil?
      @probono_wizard_steplet_step
    end
  end

  # Formlets are the steps which each form is broken up into
  # Optionns:
  #   :title => "Describe your case"
  #   :description => "We will always..."
  #   :step => :auto | 1 | 2 | ... | 5 | nil = (check) | :question = (questionmark)
  #
  def steplet(options={}, &block)
    defaults = {:id => nil, :step => :check, :title => nil, :description => nil, :markup => false}
    options = defaults.merge(options).symbolize_keys

    options[:description] = markdown(options[:description]) if options[:markup]
    options[:step] = steplet_icon_css_selector(options[:step]) 
    block_to_partial('shared/steplet', options, &block)
  end
  
  # for a given name return the css selector class
  def steplet_icon_css_selector(name)
    case name
    when :auto
      # wizard_current_step
      steplet_step_increment
      "step#{steplet_step}"
    when :check
      "stepCheck"
    when :prompt
      "stepPrompt"
    when :warning
      "stepWarning"
    when :question
      "stepQuestion"
    when :idea
      "stepIdea"
    when :problem
      "stepProblem"
    when :praise
      "stepPraise"
    when 1..5
      "step#{name}"
    else 
      nil
    end
  end

  def form_fields_for(name, object=nil, options=nil, &proc)
    fields_for(name, object,
      (options || {}).merge(:builder => WizardFormBuilder, :table => true), &proc)
  end

  # <div class="buttonBox">
  # <%= body %>
  # </div>
  # <div class="clearClass"></div>
  def form_button_container(options={}, &block)
    defaults = {}
    options = defaults.merge(options).symbolize_keys

    concat( tag(:div, { :id => options[:id], :class => 'formButtonBox', :style => options[:style] }, true))
    concat capture(&block)
    concat( probono_clear_class )
    concat( "</div>" )
  #  concat( tag(:div, { :class => 'clearClass' }, true) )
  #  concat( "</div>" )
  #  block_to_partial( 'shared/button_container', options, &block )
  end

  # <div class="profileButtonBox">
  # <%= body %>
  # </div>
  # <div class="clearClass"></div>
  def content_button_container(options={}, &block)
    defaults = {}
    options = defaults.merge(options).symbolize_keys

    concat( tag(:div, { :class => 'contentButtonBox' }.merge(options), true))
    concat capture( &block )
    concat( probono_clear_class )
    concat( "</div>" )
  end

  # dito, but with condition
  def content_button_container_if(condition, options={}, &block)
    content_button_container(options, &block) if condition
  end

  # similar to rails from_button helper but with probono styles
  def form_button(value = "Save changes", options = {})
    defaults = {:label => value, :url => {}, :html => {}, :type => :active}
    options = defaults.merge(options).symbolize_keys
    if !options[:url].empty?
      options[:href] = url_for(options[:url])
    end
    probono_button(options)
  end

  # Same as the RoR submit_tag helper but with probono styles
  # 
  #   :name => 'form_name'
  #   :form_id => 'user_form'
  #   :helper => :probono_button
  #   :type => :active, passive
  #   :position => :left, :right
  #   :property => :save, :preview, :cart etc.
  #
  def form_submit_button(text = "Save changes", options = {})
    defaults = {:label => text, :type => :active, :helper => :probono_button}
    options = defaults.merge(options).symbolize_keys

    # setup
    html = ""
    js = ""
    form_name = options[:name] ? options[:name] : (@probono_form ? @probono_form[:name] : nil)
    form_id = options[:form_id] ? options[:form_id] : (@probono_form ? @probono_form[:id] : nil)
    property = options.delete(:property)
    remote = options[:remote] ? options.delete(:remote) : (@probono_form ? @probono_form[:remote] : false)
    id = options[:id] = options[:id] ? options[:id] : "#{form_id}_button"
    hidden_id = "#{id}_hidden"
    url = @probono_form[:options][:url]
    method = (@probono_form[:options][:html] ? @probono_form[:options][:html][:method] : :post) || :post
    spinner_id = "#{form_id}_spinner"
    
    # add property hidden field if necessary
    # What is this?
    unless @form_submit_button_hidden_property
      @form_submit_button_hidden_property = hidden_field_tag(:_property, "", :id => '_property_key')
      html += @form_submit_button_hidden_property
    end

    # adding hidden property to simulate submit_tag "Submit", :name => "add"
    html += hidden_field_tag(property, "") if property
    
    # "regular" or remote form button?
    if remote
      # remote submit
      options[:function] = update_page do |page|
        page << options[:function] if options[:function]
        page << (property ? "Luleka.Form.submit('#{form_name}', '#{property}');" : "Luleka.Form.submit('#{form_name}');")
      end

      js += <<-JS
Event.observe('#{form_id}', 'submit:loading', function(event) {
  if ($('#{id}')) $('#{id}').hide();
  if ($('#{spinner_id}')) $('#{spinner_id}').show();
});
      
Event.observe('#{form_id}', 'submit:complete', function(event) {
  if ($('#{id}')) $('#{id}').show();
  if ($('#{spinner_id}')) $('#{spinner_id}').hide();
});
      JS
    else
      # regular submit
      options[:function] = update_page do |page|
        page << options[:function] if options[:function]
        # Note: Following used to work in Safari/WebKit 4
        # page << "$('#{form_id}').simulate('submit');"
        # page << "$('#{hidden_id}').simulate('click');"
        page << (property ? "Luleka.Form.submit('#{form_name}', '#{property}');" : "Luleka.Form.submit('#{form_name}');")
      end

      js += <<-JS
Event.observe('#{form_id}', 'submit:loading', function(event) {
  if ($('#{id}')) $('#{id}').hide();
  if ($('#{spinner_id}')) $('#{spinner_id}').show();
});
      JS
    end
    # generate button html + js
    html += send(options.delete(:helper) || :probono_button, options.merge(:href => url))
    html += submit_tag(text, :id => hidden_id, :style => "position:absolute;top:-10000px;left:-10000px;")
    html += div_tag(progress_spinner(:id => spinner_id),
      :style => "float:#{options[:position] ? options[:position] : 'right'};margin-right:10px;")
    html += javascript_tag(js)
    html
  end

  # Wizard field helper
  # <table class="formBoxTwoColumnsTable">
  #	  <tr>
  #     ...
  #	  </tr>
  # </table>
  def form_table_fields_for(name, object = nil, options = {}, html_options = {}, &proc)
    reset_cycle('form_box_two_columns')
    concat tag("table", html_options.merge({:class => "formBoxTwoColumnsTable", 
      :cellpadding => "0", :cellspacing => "0"}), true)
    fields_for(name,
      object,
      (options || {}).merge(:builder => WizardTableFormBuilder, :table => true),
      &proc)
    concat "</table>"
  end

  # Defines a table, when entry_fields need to be in a table like structure
  # <% form_table do %>
  #   <% form_table_row do %>
  #     <% form_table_delimiter %>
  #       ...
  #     <% end %>
  #   <% end %>
  # <% end %>
  def form_table(options={}, &block)
    reset_cycle('form_box_two_columns')
    block_to_partial('shared/form_table', options, &block)
  end

  def form_table_row(options = {}, &block)
    raise "No block given for 'form_table_row' helper" unless block_given?
    reset_cycle( 'form_box_two_columns' )
    content = capture(&block)
    concat tag("tr", options, true)
    concat content
    concat "</tr>"
  end

  # content_tag( "td", super, { :class => "formBoxTwoColumnsTableColumn" } )
  def form_table_delimiter(options = {}, &block)
    defaults = { :id => '', :style => '' }
    options = defaults.merge(options).symbolize_keys
    raise "No block given for 'form_table_delimiter' helper" unless block_given?
    content = capture( &block )
    options[:class] = options[:class].to_s + ' ' + cycle( 'formBoxTwoColumnsLeftColumn', 'formBoxTwoColumnsRightColumn', :name => 'form_box_two_columns' ) 
    concat tag( "td", options, true )
    concat content
    concat "</td>"
  end

  # custom form error message for payment object, used in
  # partner/payment and account/bank/deposit/payment
  # NOTE: method cannot be called form_error_messages_for_payment_object
  #   due to suspected ruby parser bug
  def form_error_messages_on_payment_object
    form_error_messages_for(:payment_object, :unique => true, :attr_names => {
  	  :balance => "Account Balance".t,
  	  :available_balance => "Account Balance".t,
  	  :number => "Credit Card Number".t,
  	  :verification_value => "Verification Code".t,
  	  :month => "Expiration Date".t,
  	  :year => "Expiration Date".t,
  	  :type => "Credit Card Type".t
	  })
  end

  # form_radio_group
  # Options:
  # :title => "This is a radiougroup"
  # :data => []
  def form_radio_group(options={})
    render :partial => 'shared/form_radio_group', :locals => options
  end

  # div contain for the radio / or check box group
  def radio_group(options={}, &block)
    defaults = { :id => '', :class => "radioGroup", :style => '' }
    options = defaults.merge(options).symbolize_keys

    if block_given?
      concat tag(:div, options , true)
      yield
      concat '</div>'
    else
      content_tag(:div, '', options)
    end
  end

  def form_radio_element_tag(name, options={})
    defaults = {:name => name, :button => 'button', :label => 'label text'}
    options = defaults.merge(options).symbolize_keys

    help_options = options.delete(:help) if options[:help].is_a?(Hash)
    label_options = options.delete(:label) if options[:label].is_a?(Hash)
    options[:label] = label_tag(name, label_options.delete(:text), label_options) if label_options
    if help_options
      options[:help] = help_link_tag(name, help_options)
      options[:help_text] = help_text_tag(name, help_options[:text], help_options.merge(:display => false))
    end
  	render :partial => 'shared/form_radio_element', :locals => options
  end

  #--- wizard helpers

  # Renders the chevron in the views
  # 
  # e.g.
  #
  #   :data => USER_SIGNUP | EXPERT_SIGNUP
  #   :step => :user (as the action) or 1 | 2 (as a number)
  #
  def wizard_chevron(an_action_name=nil, a_wizard_name=nil, options={})
    render :partial => 'shared/chevron', :locals => {
      :data => wizard_data(a_wizard_name),
      :step => current_wizard_step(an_action_name, a_wizard_name)
    }.merge(options)
  end

  # Wizard form helper
  #
  # e.g.
  #
  #   wizard_form_for :user, @user, :url => url, :html => {:method => :post, :name => 'wow_form'} do |f|
  #   ...
  #
  # options:
  #
  #   :remote => true|false
  #   :method => :post|:put etc.
  #   :url => url_for(...)
  #
  def wizard_form_for(name, object = nil, options = nil, &proc)
    options = {:html => {}}.merge(options ? options : {}).symbolize_keys
    options[:html] = {}.merge(options[:html])

    @probono_form = {}
    @probono_form[:remote] = !!options.delete(:remote)
    @probono_form[:name] = options[:html][:name] = options[:html][:name] || name
    @probono_form[:id] = options[:html][:id] = options[:html][:id] || "#{@probono_form[:name]}_form_#{rand(1000000)}"
    @probono_form[:options] = options
    
    # this is done due to FireFox not resetting the form on reload
    if @probono_form[:name]
      concat javascript_tag("Event.observe(window, 'dom:loaded', function() { Luleka.Form.reset('#{@probono_form[:name]}'); });")
    end
    
    # remote or regular post
    if @probono_form[:remote]
      options[:before] = "$('#{@probono_form[:id]}').fire('submit:before');#{options[:before]}"
      options[:loading] = "$('#{@probono_form[:id]}').fire('submit:loading');#{options[:loading]}"
      options[:complete] = "$('#{@probono_form[:id]}').fire('submit:complete');#{options[:complete]}"
      html = remote_form_for(name, object, options.merge(:builder => WizardFormBuilder), &proc)
    else
      options[:html][:onsubmit] = "$('#{@probono_form[:id]}').fire('submit:before');" +
        "$('#{@probono_form[:id]}').fire('submit:loading');#{options[:html][:onsubmit]};return true;"
      html = form_for(name, object, options.merge(:builder => WizardFormBuilder), &proc)
    end
    
    @probono_form = {}
    html
  end
  
  # returns the current form name inside the form block
  #
  #   wizard_form_for(@name, :name => "foo") do
  #     ..
  #     current_form_name -> "foo"
  #     ..
  #   end
  #
  def current_form_name
    @probono_form[:name] if @probono_form
  end

  # similar to current_form_name
  def current_form_id
    @probono_form[:id] if @probono_form
  end
  
  # wizard_form_fields_for
  def wizard_form_fields_for(name, object = nil, options = nil, &proc)
    fields_for(name,
      object,
      (options || {}).merge(:builder => WizardFormBuilder, :table => true),
      &proc)
  end

  #--------------------------------------------------------------------------------------------------
  # Payment view / controller helpers
  #--------------------------------------------------------------------------------------------------

  # Returns the payment label either as image (default) or text, like a Visa or Paypal symbol or text
  # Exptects:
  #   mode = :payment || :deposit
  #   type = :visa, :mastercard, etc.
  #   options = :image = true (default), :text = true
  def form_payment_deposit_tag(mode, type, options={})
    defaults = {:image => :true}
    options = defaults.merge(options).symbolize_keys
    if options[:text]
      return mode == :payment ? PaymentMethod.caption(type) : DepositMethod.caption(type)
    elsif options.delete(:image)
      return image_tag(mode == :payment ? PaymentMethod.image(type) : DepositMethod.image(type), options )
    end
  end

  # Returns a label as link to Paypal
  # Todo: depending on the user country, it needs to link to www.paypal.de, etc.
  def link_to_paypal(caption, options={})
    defaults = { :popup => true }
    options = defaults.merge(options).symbolize_keys

    link_to caption, "http://www.paypal.com/#{current_language_code}", :popup => options[:popup]
  end

  #--------------------------------------------------------------------------------------------------
  # Toggle functions
  #--------------------------------------------------------------------------------------------------

  # Add JS functionality to the page the allows to have a given block be 
  # open and closed with a link.
  #
  # Options:
  #   :display => true | false ... if the block is visible or not
  #   :position => :top | :bottom   ... where the flipper text appears relative to the block
  #   :duration => in seconds on how fast the section closes
  #   :open_text for the text to display for prompting the user to open
  #   :close_text => dito, but to close
  #   :open_image => as :open_text
  #   :close_image => as :close_text
  #   :link_function => :link_to_function | :probono_button | etc.
  #   :spacing => "15px" between image and text
  #   :after_open => JS stuff to execute when opening 
  #   :after_close => JS stuff to execute when closing 
  #   :open_js, close_js => Overrides entire JavaScript
  def flipper_link_to(name, options={}, &block)
    defaults = {
      :duration => 0.3,
      :display => true,
      :scope => :content,
      :effect => :toggle_blind,
      :after_open => '',
      :after_close => ''
    }
    options = defaults.merge(options).symbolize_keys
    return flipper_with_method(name, options, &block)
  end

  def flipper_remote_link_to(name, options={}, &block)
    defaults = {:duration => 0.3, :position => :top, :display => true,
      :open_effect => :blind_down, :close_effect => :blind_up,
      :image_options => {}, :html_options => {}, :method => :get
    }
    options = defaults.merge(options).symbolize_keys
    # id's
    id = options.delete(:id) || "#{name.to_s.shortcase}"
    id_open = "#{id}_open"
    id_opening = "#{id}_opening"
    id_close = "#{id}_close"
    id_closing = "#{id}_closing"
    # strip options
    open_text     = options.delete(:open_text) || name.to_s.humanize
    open_image    = options.delete(:open_image)
    opening_text  = options.delete(:opening_text) || open_text
    opening_image = options.delete(:opening_image) || open_image
    close_text    = options.delete(:close_text) || open_text
    close_image   = options.delete(:close_image)
    closing_text  = options.delete(:closing_text) || close_text
    closing_image = options.delete(:closing_image) || close_image
    # labels
    open_label    = open_image  ? table_cells_tag( image_tag( open_image, options[:image_options] ) , open_text ) : open_text
    opening_label = opening_image  ? table_cells_tag(image_tag(opening_image, options[:image_options]), opening_text) : opening_text
    close_label   = close_image ? table_cells_tag( image_tag( close_image, options[:image_options] ), close_text ) : close_text
    closing_label = closing_image  ? table_cells_tag( image_tag( closing_image, options[:image_options] ) , closing_text ) : closing_text
    # effect jf
    effect = update_page do |page|
      page << "if (!Element.visible('#{id}')) {"
      page.visual_effect options[:open_effect], id, :duration => options[:duration]
      page << "} else {"
      page.visual_effect options[:close_effect], id, :duration => options[:duration]
      page << "}"
    end
    # remote options
    options = {:loading => update_page do |page|
      page[id_open].hide
      page[id_opening].show
      page[id_close].hide
      page[id_closing].hide
    end }.merge(options)
    options = {:complete => update_page do |page|
      page[id_open].hide
      page[id_opening].hide
      page[id_close].show
      page[id_closing].hide
      page << effect
    end }.merge(options)

    open = div_tag(link_to_remote(open_label, options, options[:html_options]),
      :id => id_open, :display => !options[:display])
    opening = div_tag(opening_label, :id => id_opening, :display => false)
    close = div_tag(link_to_function( close_label, nil) do |page|
      page << effect
      page[id_open].show
      page[id_opening].hide
      page[id_close].hide
      page[id_closing].hide
    end, :id => id_close, :display => options[:display])
    closing = div_tag(closing_label, :id => id_closing, :display => false)

    if !block_given?
      return open + opening + close + closing
    else
      # Block
      concat(open + opening + close + closing ) if :top==options[:position]
      concat(tag('div', {:id=>id, :style=> options[:display] ? '' : 'display:none;'}, true))
      yield
      concat('</div>')
      concat(open + opening + close + closing) if :bottom == options[:position]
    end
  end

  # Provides a flipper function that allows to supply a method name for rendering
  # a link
  def flipper_with_method(name, options={}, &block)
    options = { 
      :duration => 0.3,
      :position => :top,
      :display => true,
      :open_effect => :blind_down,
      :close_effect => :blind_up,
      :image_options => {},
      :html_options => {},
      :method => :link_to_function,
      :method_options => {},
      :after_open => '',
      :after_close => ''
    }.merge(options).symbolize_keys
    # id's
    id = options.delete(:id) || "#{name.to_s.shortcase}"
    id_open = "#{id}_open"
    id_close = "#{id}_close"
    # strip options
    open_text     = options.delete(:open_text) || name.to_s.humanize
    open_image    = options.delete(:open_image)
    close_text    = options.delete(:close_text) || open_text
    close_image   = options.delete(:close_image)
    # labels
    open_label    = open_image  ? table_cells_tag( image_tag( open_image, options[:image_options] ) , open_text ) : open_text
    close_label   = close_image ? table_cells_tag( image_tag( close_image, options[:image_options] ), close_text ) : close_text
    # effect jf
    effect = update_page do |page|
      page << "if (!Element.visible('#{id}')) {"
      page << probono_visual_effect(options[:open_effect], id, :duration => options[:duration]) if options[:open_effect]
      page.show id unless options[:open_effect]
      page << "} else {"
      page << probono_visual_effect(options[:close_effect], id, :duration => options[:duration]) if options[:close_effect]
      page.hide id unless options[:close_effect]
      page << "}"
    end
    native_method = [:link_to_function, :link_to_remote].include?(options[:method])
    open_function = update_page do |page|
      page << effect
      if native_method 
        page[id_open].hide
        page[id_close].show
      else
        page << probono_visual_effect(:blind_up, id_open, :duration => 0.0)
        page << probono_visual_effect(:blind_down, id_close, :duration => 0.0)
      end
      page << options[:after_open]
    end
    close_function = update_page do |page|
      if native_method 
        page[id_close].hide
      else
        page << probono_visual_effect(:blind_up, id_close, :duration => 0.0)
      end
      page << effect
      if native_method 
        page[id_open].show
      else
        page << probono_visual_effect(:blind_down, id_open, :duration => 0.0)
      end
      page << options[:after_close]
    end

    case options[:method]
    when :link_to_function
      open_link  = link_to_function( open_label, open_function, options[:html_options] )
      close_link = link_to_function( close_label, close_function, options[:html_options] )
    when :link_to_remote
    else
      open_link  = open_label.to_s.empty? ? "" : send( options[:method], options[:method_options].merge(:label => open_label, :function => open_function) )
      close_link = close_label.to_s.empty? ? "" : send( options[:method], options[:method_options].merge(:label => close_label, :function => close_function) )
    end

    open  = content_tag( :div, open_link, :id => id_open, :style => options[:display] ? 'display:none' : '' )
    close = content_tag( :div, close_link, :id => id_close, :style => options[:display] ? '' : 'display:none' )

    if !block_given?
      return open + close
    else
      # Block
      concat( open + close ) if :top==options[:position]
      concat( tag('div', { :id=>id, :style=> options[:display] ? '' : 'display:none;' }, true) )
      yield
      concat('</div>')
      concat( open + close ) if :bottom==options[:position]
    end
  end

  # force the flipper to open
  def open_flipper_function(name, options={})
    toggle_flipper_function(name, options.merge(:action => :open))
  end

  # force the flipper to close
  def close_flipper_function(name, options={})
    toggle_flipper_function(name, options.merge(:action => :close))
  end

  # Provide a trigger JavaScript function to externally control the flipper
  # Options:
  #   :duration => time in seconds
  #   :open_effect, :close_effect => :blind, etc.
  #   :scope => :all | :content | :control
  #   :method => defines the method the original toggle uses (used to determine the effect to hide link)
  def toggle_flipper_function(name, options={})
    defaults = { :duration => 0.5,
      :open_effect => :blind_down,
      :close_effect => :blind_up,
      :method => :link_to_function,
      :scope => :all,
      :action => :toggle
    }
    options = defaults.merge(options).symbolize_keys
    # id's
    id = options.delete(:id) || "#{name.to_s.shortcase}"
    id_open = "#{id}_open"
    id_close = "#{id}_close"

    function = ""
    native_method = [:link_to_function, :link_to_remote].include?(options[:method])
    # effect jf
    function = update_page do |page|
      page << "if (!Element.visible('#{id}')) {" if :toggle == options[:action]
      # open
      if [:toggle, :open].include?(options[:action])
        if [:all, :control].include?(options[:scope])
          if native_method
            page[id_open].hide
          else
            page << visual_effect(:fade, id_open, :queue => 'front', :duration => 0.0)
          end
        end
        if [:all, :content].include?(options[:scope])
          page << probono_visual_effect(options[:open_effect], id, :duration => options[:duration])
        end
        if [:all, :control].include?(options[:scope])
          if native_method
            page[id_close].show
          else
            page << visual_effect(:appear, id_close, :queue => 'end', :duration => 0.0 )
          end
        end
      end
      page << "} else {" if :toggle == options[:action]
      # close
      if [:toggle, :close].include?(options[:action])
        if [:all, :control].include?( options[:scope] )
          if native_method
            page[id_close].hide
          else
            page << visual_effect(:fade, id_close, :queue => 'front', :duration => 0.0 )
          end
        end
        if [:all, :content].include?( options[:scope] )
          page << probono_visual_effect( options[:close_effect], id, {}.merge(:duration => options[:duration]) )
        end
        if [:all, :control].include?( options[:scope] )
          if native_method
            page[id_open].show
          else
            page << visual_effect(:appear, id_open, :queue => 'end', :duration => 0.0 )
          end
        end
      end
      page << "}" if :toggle == options[:action]
    end
    function
  end

  # country select for address
  def collect_countries_for_address_select
    collect_countries_for_select(true, true)
  end

  # returns a select array of academic titles
  def collect_academic_titles_for_select(with_select=true)
    AcademicTitle.find(:all, 
      :order => "#{AcademicTitle.localized_facet(:name)} ASC").collect {|a| [a.name, a.id]}.insert(0, with_select ? ["No Title".t, 0] : nil).compact
  end
  
  # used for select gender salutation
  def collect_salutation_genders_for_select(with_select=true)
    result = [["Mr".t, 'm'], ["Ms".t, 'f']]
    result.insert(0, ["Select...".t, nil]) if with_select
    result
  end
    
  # This helper is like link_to, but it will register the link through happening on probono
  def link_through_to(name, options = {}, html_options=nil, *parameters_for_method_reference)
    link_to(name, options, html_options, *parameters_for_method_reference)
  end

  # Formats an address instance correctly in profile and overviews
  def address_display(address, options={})
    defaults = {:kind => address.kind}
    options = defaults.merge(options).symbolize_keys

    unless fields = options[:fields]
      fields = case options[:kind]
      when :personal, :business then [:street, :city, :country, :spacer, :phone, :mobile, :fax]
      when :billing then [:company, :name, :street, :city, :country]
      else
        [:street, :city, :country]
      end
    end
    # only for fields who's attributes don't correnspondend
    attribute_translation = {
      :company => :company_name,
      :name    => :salutation_and_name,
      :city    => :city_postal_and_province,
      :country => :country_or_country_code,
      :spacer  => "&nbsp;"
    }
    default_field_options = {
      :phone => {
        :format => content_tag(:span, "Phone".t, {:style => 'width:45px;float:left;padding-right:5px'}) + content_tag(:span, '{phone}', {}),
        :helper => :phone_link_to,
        :helper_options => {},
        :options => { :style => "" }
      },
      :mobile => {
        :format => content_tag(:span, "Mobile".t, {:style => 'width:45px;float:left;padding-right:5px'}) + content_tag(:span, '{mobile}', {}),
        :helper => :phone_link_to
      },
      :fax => {
        :format => content_tag(:span, "Fax".t, {:style => 'width:45px;float:left;padding-right:5px'}) + content_tag(:span, '{fax}', {})
      },
      :spacer => {
        :options => { :style => "height:3px;" }
      }
    }

    html = ""
    if address
      fields.each do |f|
        case f.class.name
        when /Hash/
          field_name = attribute_translation[f.to_a.flatten[0].to_sym] ? attribute_translation[f.to_a.flatten[0].to_sym] : f.to_a.flatten[0]
          field_options = f.to_a.flatten[1]
        when /String/, /Symbol/
          field_name = attribute_translation[f.to_sym] ? attribute_translation[f.to_sym] : f
          field_options = default_field_options[f] || {}
        end

        if field_name.is_a?(String)
          value = field_name
        else
          if (value = address.respond_to?(field_name) ? address.send(field_name) : "").blank?
            value = nil
          end
        end

        if value
          value = field_options[:helper] ? send(field_options[:helper], value, field_options[:helper_options] || {})  : value
          html << tag(:div, field_options[:options] , true)
          html << (field_options[:format] ? field_options[:format].gsub("{#{f}}", value) : value)
          html << '</div>'
        end
      end
    end
    html
  end

  # Wrap two pieces of information in a left and right cell of a table.
  # Reason for this: we can vertically align the content in respect to each other,
  # which is extremely difficult to do with <div> tags
  # Example:
  #   table_cells_tag "one", {:html => options}, "two"
  #   where options for each cell are optionally :-)
  #
  def table_cells_tag(*cells)
    table_cells_with_options_tag({:style => 'vertical-align:middle;'}, *cells)
  end

  # Same as table_cells_tag, but adds generic options for each table cell
  def table_cells_with_options_tag(options={}, *cells)
    defaults = {:style => 'vertical-align: middle;'}
    options = defaults.merge(options).symbolize_keys

    return '' if cells.empty?
    content_tag( :table,
      content_tag( :tr,
        content_cells_tag(:td, options, *cells),
      { } ),
    { :cellpadding => "0", :cellspacing => "0" } )
  end


  # Similar to table cells tag, but takes
  #
  # Exammple:
  #   content_cells_tag :span, { :join => '|', :class => 'cssClass' }, 'cell 1', 'cell 2', 'cell 3'
  #
  # Output:
  # <span class="cssClass">cell 1</span>|<span class="cssClass">cell 2</span>|<span class="cssClass">cell 3</span>
  #
  # Usage:
  #   name => name a tag to wrap each cell with :td, :div, :span, etc.
  #   options:
  #     :join => " | " whatever in between
  #     :style => or other html options will be used for each cell, e.g. :style => 'vertical-align:middle'
  #
  def content_cells_tag(name, options={}, *cells)
    return '' if cells.empty?
    tds = ""
    index = 0
    join = options.delete(:join)
    cells.reverse!
    while !cells.empty?
      content = cells.pop
      cell_options = cells.pop
      if cell_options.nil?
        tds << ( name.to_s.empty? ? join : content_tag( name, join, options ) ) if join && index>0
        tds << ( name.to_s.empty? ? content : content_tag( name, content, options ) )
      elsif cell_options.is_a?( Hash )
        tds << ( name.to_s.empty? ? join : content_tag( name, join, options ) ) if join && index>0
        tds << ( name.to_s.empty? ? content : content_tag( name, content, options.merge( cell_options ).symbolize_keys ) )
      else
        tds << ( name.to_s.empty? ? content : content_tag( name, content, options ) )
        tds << ( name.to_s.empty? ? join : content_tag( name, join, options ) ) if join
        tds << ( name.to_s.empty? ? cell_options : content_tag( name, cell_options, options ) )
      end
      index += 1
    end
    tds
  end

  # Provide a number of effects, which will be done in parallel
  # Options:
  #   :duration => duration in seconds
  def probono_parallel_effect(*args)
    parallel = "new Effect.Parallel( [ "

    effects = []
    options = { :duration => 0.5}

    args.each do |arg|
      case arg.class.name
      when 'Hash'
        options.merge! arg
      else
        effects << arg.gsub(";", "")
      end
    end
    if effects.size > 0
      parallel << effects.join(", ")
      parallel << "], { duration: #{options[:duration]} } );"
      return parallel
    end
    ""
  end

  # Adds additional parallel effects to Rails standard visual_effect
  # :appear_and_blind_up | :appear_and_blind_down | :toggle_appear_and_blind
  # :control => true makes sure that e.g. a blind down is not executed
  # if the elemnt is already visible.
  def probono_visual_effect(name, element_id, options = {} )
    defaults = {:duration => 0.3, :control => true}
    options = defaults.merge(options).symbolize_keys

    if name.to_s.index(/appear_and_blind/)

      up = %( new Effect.Parallel(
                [ new Effect.BlindUp('#{element_id}', { sync: true }),
                  new Effect.Opacity('#{element_id}', { sync: true, to: 0.0, from: 1.0 } ) ],
                { duration: #{options[:duration]} }
              );
            )

      dw = %( new Effect.Parallel(
                [ new Effect.Opacity('#{element_id}', { sync: true, to: 1.0, from: 0.0 } ),
                  new Effect.BlindDown('#{element_id}', { sync: true }) ],
                { duration: #{options[:duration]} }
              );
            )

      fi = %( if ( Element.visible(#{element_id}) ) {
                #{up}
              } else {
                #{dw}
              }
            ) 

      case name.to_sym
      when :appear_and_blind_up
        up
      when :appear_and_blind_down
        dw
      when :toggle_appear_and_blind
        fi
      end
    else
      if name.to_s.index(/down/)
        update_page do |page|
          page << "if (!Element.visible('#{element_id}')) {"
          page << visual_effect( name, element_id, options )
          page << "}"
        end
      elsif name.to_s.index(/up/)
        update_page do |page|
          page << "if (Element.visible('#{element_id}')) {"
          page << visual_effect( name, element_id, options )
          page << "}"
        end
      else
        visual_effect(name, element_id, options)
      end
    end
  end

  # Fixes a bug if auto complete field is used multiple times in the form.
  # Usage:
  #   probono_text_field_with_auto_complete( :person, :name, { :index => index } )
  #
  def probono_text_field_with_auto_complete(object, method, tag_options = {}, completion_options = {})
    defaults = { :regexp_for_id => '(\d+)$', :after_update_element => 'Prototype.emptyFunction' }
    completion_options = defaults.merge(completion_options).symbolize_keys

    if (tag_options[:index])
      tag_name = "#{object}_#{tag_options[:index]}_#{method}"
    else
      tag_name = "#{object}_#{method}"
    end

    after_update_element = <<-JS.gsub(/\s+/, ' ')
    function(element, value) {
        var model_id = /#{completion_options[:regexp_for_id]}/.exec(value.id)[1];
        $("#{tag_name}_id").value = model_id;
        element.model_auto_completer_cache = element.value;
        (#{completion_options[:after_update_element]})(element, value, $("#{tag_name}_id"), model_id);
    }
    JS

    completion_options.update( {
      :after_update_element => after_update_element
    } )

    html = ""
    html << (completion_options[:skip_style] ? "" : probono_auto_complete_stylesheet( :style => tag_options[:style] ) )
  #  html << hidden_field_tag("#{tag_name}", '', :id => "#{tag_name}_id")
    html << hidden_field(object, 'id', tag_options.merge( :id => "#{tag_name}_id", :value => completion_options[:value_id] ))
    html << text_field(object, method, tag_options)
    html << content_tag("div", "", :id => tag_name + "_auto_complete", :class => "auto_complete")
    html << auto_complete_field(tag_name, { :url => { :action => "auto_complete_for_#{object}_#{method}" } }.update(completion_options))
  end

  def probono_auto_complete_stylesheet(options={})
    defaults = { :style => 'width:350px' }
    options = defaults.merge(options).symbolize_keys

    content_tag('style', <<-EOT, :type => 'text/css')
      div.auto_complete {
        background: #fff;
        #{options[:style]}
      }
      div.auto_complete ul {
        border:1px solid #888;
        margin:0;
        padding:0;
        width:100%;
        list-style-type:none;
      }
      div.auto_complete ul li {
        margin:0;
        padding:3px;
      }
      div.auto_complete ul li.selected { 
        background-color: #ffb; 
      }
      div.auto_complete ul strong.highlight { 
        color: #800; 
        margin:0;
        padding:0;
      }
    EOT
  end

  # used to wrap flash and error message
  def messages_container_without_bracket(options={}, &block)
    concat tag(:div, {:class => 'messageBoxWithoutBracket'}.merge(options), true)
    yield
    concat "</div>"
  end

  # adds condition to message block
  def messages_container_without_bracket_if(condition, options={}, &block)
    messages_container_without_bracket(options, &block) if condition
  end
  
  # View helper to output string of tags linked to the appropriate URL
  # 
  #
  # Options:
  #   tag_list, is the list of tags as an array
  #   :delimiter => ' + ' || ', ' || ' ' 
  #
  # Usage:
  #   tag_list_link_to list, :url => :tag_people_url     # where id is used to call function
  #   tag_list_link_to list, :url => { :action => 'tag' } # where :id will be merged in
  #
  # or as block
  # 
  #  tag_list_link_to list do |tag|
  #    tag_profiles_url :tag
  #  end 
  #
  def tag_list_link_to(tag_list, options={}, html_options={}, &block)
    options = {:delimiter => ','}.merge(options).symbolize_keys
    delimiter = options.delete(:delimiter)
    if block_given?
      link_list = tag_list.collect do |tag|
        tag_link_to tag, options.merge(:url => yield(tag)), html_options
      end
      concat link_list.join(delimiter)
    else
      tag_list.map {|tag| tag_link_to(tag, options.merge(:id => tag.to_s.parameterize), html_options)}.compact.uniq.join("#{delimiter} ")
    end
  end
  
  # View helper to output string of a single tag linked to the appropriate URL
  # Options:
  #   :url => { :action => '...' }
  #
  def tag_link_to(tag, options={}, html_options={})
    if url = case options.class.name
      when /Hash/ then options.merge(:id => tag.to_s.parameterize)
      else nil
      end
    else
      klass = controller_name_to_class
      # e.g. tier_kase_tag_path :tier_id => @tier, :id => "rent" -> http://apple.luleka.com/problems/tags
      member_path([@tier, klass, :tag], nil, :id => tag.parameterize)
    end
    link_to(h(tag.to_s), url, html_options) unless tag.to_s.empty?
  end

  # shows a tag list for taggable object
  # is :edit option, the tag list will be editable
  def tag_list(taggable, options={})
    render(:partial => 'shared/tag_list', :object => taggable, 
      :locals => {:editable => false, :edit => false, :context => nil}.merge(options).symbolize_keys)
  end
  
  # returns a sentence saying, 
  #
  # e.g.
  #
  #   "PNG, GIF and JPG files only"
  #
  def allowed_files_in_words(file_ext_array)
    "%{extensions} files only please".t % {
      :extensions => file_ext_array.map(&:upcase).to_sentence_with_or.chop_period
    }
  end

  # returns sentence with generally allowed file extension
  def allowed_image_files_in_words(file_ext_array=Utility::VALID_IMAGE_FILE_EXTENSIONS)
    allowed_files_in_words(file_ext_array)
  end
  
  # returns a sentence about max file size, e.g. "Max size 100 KB"
  def allowed_file_size_in_words(size_in_kb)
    "Max size %{size_in_kb} KB".t % {:size_in_kb => size_in_kb.loc}
  end

  # collection of search classes
  def collect_search_classes_for_select
    collection = [["Cases".t, 'Kase'], ["People".t, 'Person'], ["Communities".t, 'Tier']]

    if kase_class = Kase.self_and_subclasses.find {|c| c.controller_name == controller.controller_name}
      collection.insert(0, [kase_class.human_name(:count => 2).titleize, kase_class.name]) unless collection.find {|c| c[1] == kase_class.name}
    elsif tier_class = Tier.self_and_subclasses.find {|c| c.controller_name == controller.controller_name}
      collection.insert(0, [tier_class.human_name(:count => 2).titleize, tier_class.name]) unless collection.find {|c| c[1] == tier_class.name}
    elsif topic_class = Topic.self_and_subclasses.find {|c| c.controller_name == controller.controller_name}
      collection.insert(0, [topic_class.human_name(:count => 2).titleize, topic_class.name]) unless collection.find {|c| c[1] == topic_class.name}
    end
    
    collection
  end
  
  # search options for select_tag in search partial
  def search_options_for_select
    options_for_select(collect_search_classes_for_select, selected_for_search_options_for_select)
  end

  # selects which option in search select is active
  def selected_for_search_options_for_select
    if kase_class = Kase.self_and_subclasses.find {|c| c.controller_name == controller.controller_name}
      kase_class.name
    elsif tier_class = Tier.self_and_subclasses.find {|c| c.controller_name == controller.controller_name}
      tier_class.name
    elsif topic_class = Topic.self_and_subclasses.find {|c| c.controller_name == controller.controller_name}
      topic_class.name
    elsif controller.controller_name =~ /people/i
      Person.name
    else
      Kase.name
    end
  end

  # returns translated abbreviated month names array used in date selectors
  def collect_abbreviated_month_names_for_select
    I18n.t("date.abbr_month_names").compact
  end

  def collect_month_names_for_select
    I18n.t("date.month_names").compact
  end

  # generic helper to return javascript for closing the lightbox
  def close_modal_javascript
    "Luleka.Modal.close()"
  end

  # wrapper around sidebar stats
  def sidebar_stats(&block)
    html = capture(&block)
    unless html.blank?
      concat tag(:div, {:id => sidebar_stats_dom_id}, true)
      concat html
      concat "</div>"
    end
  end

  # sidebar stats dom id
  def sidebar_stats_dom_id
    "sidebarStats"
  end
  
  # prints a stats pair
  # e.g. "5 replies received"
  #
  def sidebar_stats_pair(count, text, options={})
    html = ''
    last = options.delete(:last)
    unless (count = count.to_i) == 0
      count_s = case count
      when 1..999 then "#{count}"
      when 1000..999999 then "%{count}k".tn(:stats) % {:count => Float(Integer((Float(count.to_i) / Float(1000)) * 10)) / 10}
      when 1000000..999999999 then "%{count}m".tn(:stats) % {:count => Float(Integer((Float(count.to_i) / Float(1000000)) * 10)) / 10}
      else "%{count}b".tn(:stats) % {:count => Float(Integer((Float(count.to_i) / Float(1000000000)) * 10)) / 10}
      end

      html << "<dl class=\"#{last ? 'last' : ''} clearfix\">"
        html << content_tag(:dt, count_s,
          :class => count_s.size < 3 ? 'large' : ("#{count_s}".size < 5 ? 'medium' : 'small'))
        html << content_tag(:dd, text)
      html << "</dl>"
    end
    html
  end
  
  # returns the pluralized word using globalize
  #
  # e.g.
  #
  #   pluralize_word(2, "vote")  ->  "votes"
  #   pluralize_word(1, "vote")  ->  "vote"
  #
  def pluralize_word(count, singular, plural=nil)
    if plural
      case count
      when 0 then plural
      when 1 then singular
      else plural
      end
    else
      I18n.t(singular, :count => count)
    end
  end

  # renders a button similar to a turquoise button but slightly higher and larger font
  def button_start(text, *args)
    html = '<div class="turquoiseButtonFat">'
    
    inner_html  = '<div class="turquoiseButtonFatLeft"></div>'
    inner_html << '<div class="turquoiseButtonFatText">' + text + '</div>'
    
    html << link_to(inner_html, *args)
    html << '</div>'
  end

  # renders a start kase button, used in search bar
  def button_start_kase(text="Start".t, *args)
    klass = controller.is_a?(KasesController) ? kase_class : Kase
    button_start(text, "#{member_path([@tier, @topic, klass], :new)}")
  end

  # added to the flipper 
  def flipper_label(text, html_options={})
    html = span_tag('»&nbsp;', :class => "flipperSwitch")
    html << span_tag(text, {:class => "flipperLabel"}.merge(html_options))
    html
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
    id = html_options.delete(:id) || "lm_#{rand(1000000)}"
    inner_id = html_options.delete(:inner_id) || "#{id}_more"
    link_id = html_options.delete(:link_id) || "#{id}_link"
    action_id = html_options.delete(:action_id) || "#{id}_action"
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
  <div id="#{action_id}" class="switcherAction" style="#{open && !sticky ? 'display:none;' : ''}">
    #{tag(:a, html_options.merge(:id => link_id, :href => href, :onclick => "#{escape_once(onclick)};return false;"), true)}
      <span id="#{action_icon_id}" class="actionIcon #{open ? 'opened' : 'closed'}" style="#{icon ? '' : 'display:none;'}"></span>
      <span id="#{action_label_id}" class="actionLabel">#{text}</span>
    </a>
  </div>
  <div id="#{inner_id}" class="#{inner_css_class}" style="#{open ? '' : 'display:none;'}">
    #{capture(&block)}
  </div>
</div>
    HTML
    concat(html)
  end

  # switcher for more form elements with remote
  #
  # options:
  #   :url => "/..."
  #   :open =>  true   -> open by default
  #   :sticky => true  -> action label remains visble when open, default: false
  #   :icon => true    -> show icon or hide it
  #
  def switcher_link_to_remote(text, options={}, html_options={}, &block)
    id = html_options.delete(:id) || "lm_#{rand(1000000)}"
    inner_id = html_options.delete(:inner_id) || "#{id}_more"
    link_id = html_options.delete(:link_id) || "#{id}_link"
    action_id = html_options.delete(:action_id) || "#{id}_action"
    icon = boolean_default(options.delete(:icon), true)
    action_icon_id = id + '_action_icon'
    action_label_id = id + '_action_label'
    css_class = html_options.delete(:class)
    style = html_options.delete(:style)
    inner_css_class = html_options.delete(:inner_class)
    open = options.delete(:open) || false
    sticky = boolean_default(options.delete(:sticky), false)

    function = update_page do |page|
      page << "if ($('#{inner_id}').style.display == 'none' && (typeof #{id} == 'undefined' || (typeof #{id} != 'undefined' && #{id} != true))) {"
        page << remote_function({
          :update => "#{inner_id}",
          :success => update_page do |p|
            p << "var #{id} = true;"
            p[inner_id].visual_effect :blind_down, {:duration => 0.3}
            if sticky 
              p << "$('#{action_icon_id}').removeClassName('closed');"
              p << "$('#{action_icon_id}').addClassName('opened');"
            else
              p[action_id].hide
            end
          end
        }.merge(options))
      page << "} else if ($('#{inner_id}').style.display == 'none' && !(typeof #{id} == 'undefined') && #{id}) {"
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
  <div id="#{action_id}" class="switcherAction" style="#{open && !sticky ? 'display:none;' : ''}">
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
    concat(html)
  end

  # provides list container for kase statuses, e.g. "expires in 4 days", "$5 offer", etc.
  def overview_list(&block)
    concat tag(:ul, {:class => "overviewList clearfix"}, true)
    concat capture(&block)
    concat "</ul>"
    concat probono_clear_class
  end

  # one status list item
  def overview_list_item(*args, &block)
    text, options = filter_tag_args(*args)
    text = capture(&block) if block_given?
    
    options[:class] ? options[:class] += " last" : options[:class] = "last" if options.delete(:last)
    options[:class] ? options[:class] += " right" : options[:class] = "right" if options.delete(:right)
    
    html = ''
    html << content_tag(:li, text, options)
    
    if block_given?
      concat html
    else
      html
    end
  end

  # used for feature matrix
  def chart_feature(check)
    if check.is_a?(String)
      # display as string
      check
    elsif check.is_a?(TrueClass)
      image_tag("icons/checkmark.gif", :title => "", :alt => "")
    else
      "&nbsp;"
    end
  end

  def horizontal_center(&block)
html = <<-HTML
<table cellspacing="0" cellpadding="0" style="width:100%">
  <colgroup>
    <col>
    <col width="75">
    <col>
  </colgroup>
  <tbody>
    <tr>
      <td style="">&nbsp;</td>
      <td style="padding:0;">
        #{capture(&block)}
      </td>
      <td style="">&nbsp;</td>
    </tr>
  </tbody>
</table>
HTML
    concat(html)
  end

  # converts to local time
  # http://www.caboo.se/articles/2007/2/23/adding-timezone-to-your-rails-app
  def tz(time_at)
    Time.zone.utc_to_local(time_at.utc)
  end

  # tabs
  def tab_header(html_options={}, &block)
    concat tag("div", {:class => "tabHeader"}.merge(html_options), true)
    concat tag("ul", {:class => "tabs"}, true)
    yield
    concat "</ul>"
    concat "</div>"
  end
  
  # Creates the tab html code for the header tab
  #
  # E.g.
  #
  #  header_tab :index => 0, :active_index => 0, :size => 2 do
  #    link_to
  #  end 
  #
  #  header_tab :index => 0, :active_index => 0, :size => 2, :content => "foo"
  #
  def header_tab(options={}, &block)
    options.symbolize_keys!

    # setup tab begin separator
    size = options.delete(:size).to_i
    index = options.delete(:index).to_i
    active_index = options.delete(:active_index).to_i
    active = (active_index == index)
    first = (index == 0)
    last = (index == size - 1)
    
    begin_separator_class = "separator"
    if first
      begin_separator_class += " first"
      begin_separator_class += " active" if active
    else
      begin_separator_class += " inactiveActive" if active
      begin_separator_class += " activeInactive" if index > 0 && active_index == index - 1
    end
    
    # setup tab end separator
    end_separator_class = nil
    if last
      end_separator_class = "separator"
      end_separator_class += " last"
      end_separator_class += " active" if active
    end
    
    # setup tab item 
    item_class = "#{active ? 'active' : ''} #{options.delete(:class)}"
    item_class += " first" if first
    item_class += " last" if last
    
    # html
    content = block_given? ? capture(&block) : options.delete(:content)
    
    html = ""
    html += content_tag("li", '', :class => begin_separator_class) if begin_separator_class
    html += tag("li", {:class => item_class}.merge(options) , true)
      html += "<h2>"
        html += content if content
      html += "</h2>"
    html += "</li>"
    html += content_tag("li", '', :class => end_separator_class) if end_separator_class
    
    block_given? ? concat(html) : html
  end

  # Regular link in tab
  #
  # E.g.
  #
  #   header_tab_link_to("Question", "/questions", :icon => :problem)
  #
  def header_tab_link_to(text, options={}, html_options={})
    text = "#{text}" + content_tag("div", "", :class => "icon #{html_options.delete(:icon).to_s.downcase}") if html_options[:icon]
    header_tab({:content => link_to(text, options)}.merge(html_options))
  end

  # Remote link in tab, all options like link_to_remote
  #
  # E.g.
  #
  #   header_tab_link_to_remote("Question", {:url => "/", :method => :get}, {:icon => :problem})
  #
  def header_tab_link_to_remote(text, options={}, html_options={})
    text = "#{text}" + content_tag("div", "", :class => "icon #{html_options.delete(:icon).to_s.downcase}") if html_options[:icon]
    header_tab({:content => link_to_remote(text, options)}.merge(html_options))
  end

  # Link to function in tab, all options like link_to_function
  #
  # E.g.
  #
  #   header_tab_link_to_function("Question", "alert('bla')", {:icon => :problem})
  #
  def header_tab_link_to_function(text, function, html_options={})
    text = "#{h(text)}" + content_tag("div", "", :class => "icon #{html_options.delete(:icon).to_s.downcase}") if html_options[:icon]
    # link_to_function(text, function)
    header_tab({:content => link_to_function(text, ""), 
      :onclick => function}.merge(html_options))
  end

  # e.g. 
  #
  #   returns Username "(5-200 characters)" for labels
  #
  def characters_inclusion(min, max, leading_space=true)
    content_tag(:span, (leading_space ? "&nbsp;" : '') + "(" + "%d&ndash;%d %s" % [min, max, "characters".t] + ")", 
      :class => "normal inclusion")
  end
  
  # dito, but adding " (or something)"
  def or_something_inclusion(something, leading_space=true)
    content_tag(:span, (leading_space ? "&nbsp;" : '') + "(" + "or %s".t % [something] + ")", 
      :class => "normal inclusion")
  end

  # Creates a "Read >" 
  def more_link_to(name, options, html_options={})
    name = "#{name}&nbsp;<b>&rsaquo;</b>"
    link_to(name, options, html_options)
  end

  # Creates a "Read >" 
  def more_link_to_function(name, function, html_options={})
    name = "#{name}&nbsp;<b>&rsaquo;</b>"
    link_to_function(name, function, html_options)
  end

  # JS for text area autogrow observer hook
  def text_area_autogrow_javascript(id_or_element=nil)
    if id_or_element
      "Widget.Textarea.observe('#{id_or_element}');"
    else
      "Widget.Textarea.observe();"
    end
  end

  # wrapper to auto_link adding nofollow
  def auto_link_with_nofollow(text, &block)
    auto_link(text, :all, {:rel => "nofollow"}, &block)
  end
  
end
