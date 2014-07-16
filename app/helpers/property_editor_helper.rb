module PropertyEditorHelper

  # generic in place property editor
  # 
  # e.g.
  #
  #   property_editor :kase, :description
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
  def property_editor(object_name, method_name, options={})
    defaults = {:editable => false, :label => false, :display => true, :edit => false, :lock => false}
    options = defaults.merge(options).symbolize_keys

    unless object = options.delete(:object)
      object = instance_variable_get("@#{object_name}")
    end
    if options[:label].is_a?(Hash)
      options[:label].merge!(:position => :left)
      options[:label].merge!(options[:text].is_a?(Hash) ? options[:text] : {:text => options[:text], :auto => false, :lock => options[:lock]})
    end
    
    render :partial => 'shared/property_in_place', :object => object, :locals => {
      :object_name => object_name.to_sym,
      :method_name => method_name.to_sym,
      :locals => (options.delete(:locals) || {}).merge({
        :object_name => object_name.to_sym,
        :method_name => method_name.to_sym,
      })
    }.merge(options) if object
  end

  def property_editor_if(condition, object_name, method_name, options={})
    property_editor(object_name, method_name, options) if condition
  end

  def property_editor_unless(condition, object_name, method_name, options={})
    property_editor(object_name, method_name, options) unless condition
  end
  
  # dom_id for property
  def property_dom_id(object, property_name, prefix=nil)
    return dom_id(object, "#{property_name}_#{prefix}") if prefix
    dom_id(object, "#{property_name}")
  end

  # container for value (right) element
  def property_column(options={}, &proc)
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

  # Generates the table col's for label, property and if 
  # :editable is true also the additional column for the edit button
  #<col width="140"></col>
  #<col width="329"></col>
  #<col width="11"></col>
  def property_columns_tag(options={})
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
  #
  # e.g.
  #
  #   :type => :table  2 column
  #   :type => :full   1 column
  #   :type => :form   2 column
  #
  def property_element(options={}, &proc)
    defaults = {:type => :table, :editable => false, :update => false}
    options = defaults.merge(options).symbolize_keys
    css_class = "row #{options[:class]}"
    concat tag(:div, {:id => options[:id], :style => options[:style], :class => "row #{options[:class]}"}, true), proc.binding
    case options[:type]
    when :table, :full
      concat tag(:table, {:cellpadding => "0", :cellspacing => "0"}, true), proc.binding
        concat property_columns_tag(options), proc.binding
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

  # Adds condition parameter to property_element
  def property_element_if(condition, options={}, &proc)
    property_element(options, &proc) if condition
  end

  # Adds condition parameter to property_element
  def property_element_unless(condition, options={}, &proc)
    property_element(options, &proc) unless condition
  end

end
