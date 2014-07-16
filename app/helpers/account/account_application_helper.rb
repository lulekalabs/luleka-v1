module Account::AccountApplicationHelper

  # Provides a container for the settings
  def account_settings_container(options={}, &proc)
    defaults = { :type => :column, :editable => false, :class => "turquoiseBoxSquaresTable" }
    options = defaults.merge(options).symbolize_keys

    @first_account_setting_row = true

    case options[:type].to_sym
    when :column
      concat tag(:table, { :cellpadding => "0", :cellspacing => "0" }.merge( :class => options[:class] ), true), proc.binding
  #    concat tag(:tr, {}, true), proc.binding
      yield
  #    concat "</tr>", proc.binding
      concat "</table>", proc.binding
    when :full
      concat tag(:table, { :cellpadding => "0", :cellspacing => "0" }.merge( :class => options[:class] ), true), proc.binding
      concat tag(:tr, {}, true), proc.binding
      concat tag(:td, { }, true), proc.binding
      yield
      concat "</td>", proc.binding
      concat "</tr>", proc.binding
      concat "</table>", proc.binding
    else
      yield
    end
  end

  # same as account_setting but with if condition
  def account_setting_if(condition, options={}, &proc)
    account_setting(options, &proc) if condition
  end

  # provides a container for each account setting 
  def account_setting(options={}, &proc)
    defaults = { :position => :auto, :type => :column, :first => :auto }
    options = defaults.merge(options).symbolize_keys

    if :column==options[:type]
      if :auto==options[:position]
        options[:position] = cycle(:left, :right, :name => 'left_right_column_cycler' ).to_sym
      end

      if :column==options[:type]
        if :left==options[:position]
          concat tag(:tr, {}, true), proc.binding
          concat tag(:td, { :class=>"turquoiseBoxSquaresTableLeft" }, true ), proc.binding
        elsif :right==options[:position]
          concat tag(:td, { :class=>"turquoiseBoxSquaresTableRight" }, true ), proc.binding
        end
      end
      if first_row=@first_account_setting_row
        concat tag(:div, { :class=>"turquoiseBoxSquaresTableContentFirstRow" }, true), proc.binding
        @first_account_setting_row = false if :right==options[:position]
      else
        concat tag(:div, { :class=>"turquoiseBoxSquaresTableContent" }, true), proc.binding
      end
      if options[:title]
        concat content_tag(:span, options[:title], { :class=>"turquoiseBoxSquaresTableContentHeader" }), proc.binding
      end
      yield
      concat "</div>", proc.binding
      if :column==options[:type]
        concat "</td>", proc.binding
        if :right==:position
          concat "</tr>", proc.binding
        end
      end
    else
      concat tag(:div, { :class=>"turquoiseBoxSquaresTableContent" }, true), proc.binding
      if options[:title]
        concat content_tag(:span, options[:title], { :class=>"turquoiseBoxSquaresTableContentHeader" }), proc.binding
      end
      yield
      concat "</div>", proc.binding
    end
  end

  # provides a container for account setting action
  def account_setting_button_container(options={}, &proc)
    concat tag(:div, {}, true), proc.binding
    yield
    concat "</div>", proc.binding
  end

  # It is the action button
  # Later refactor into tag library
  def account_setting_action_button(options={})
    defaults = { :href => '#', :function => '', :title => "" }
    options = defaults.merge(options).symbolize_keys

    if options[:url]
      options[:href]=url_for(options[:url])
    end

    html = ""
    html << tag(:div, { :class => 'turquoiseBoxSquaresActionBox' }, true)
    html << tag(:div, { :class => 'actionButtonBox' }, true)
    html << tag(:div, { :class => 'buttonActionTurquoise' }, true)

    html << content_tag(:a, '', { :href => options[:href], :onclick => (options[:onclick] ? "#{options[:onclick]}; " : "") + (!options[:function].empty? ? "#{options[:function]}; return false;" : "") } )

    html << "</div>"  # buttonActionTurquoise
    html << "</div>"  # actionButtonBox
    html << content_tag(:a, options[:label], { :href => options[:href], :onclick => (options[:onclick] ? "#{options[:onclick]}; " : "") + (!options[:function].empty? ? "#{options[:function]}; return false;" : "") } )
    html << "</div>"  # turquoiseBoxSquaresActionBox
    html
  end

  # Adds a spacer | 
  def account_setting_action_spacer
    div_tag('|', :class => "turquoiseBoxSquaresActionBox")
  end
  
end
