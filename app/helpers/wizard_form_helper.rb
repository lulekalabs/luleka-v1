module WizardFormHelper
  #--- wizard form builder

  # This class extends FromBuilder to encapsulate fields and generate necessary HTML
  #
  # e.g.
  #
  # <% form_element do %>
  #	  <%= form_label :user, :username, :label => true %>
  #	  <% form_field :user, :username, :help  => {:text => "This is a help message.".t} do %>
  #		  <%= text_field :user, :username %>
  #		  <%= help_button :user, :username %>
  #	  <% end %>
  # <% end %>
  #
  class WizardFormBuilder < ActionView::Helpers::FormBuilder
    include ActionView::Helpers::TextHelper

    def cycle_class
      cycle('oddcell', 'evencell', :name => 'form_row_colors')
    end

    (field_helpers - %w(radio_button check_box hidden_field) + %w(date_select time_zone_select)).each do |field_helper|
      html = <<-SOURCE
        def #{field_helper}(method, options={}, &block)
          inner_html = block_given? ? @template.send(:capture, &block) : ''
          
          html = @template.tag(:dl, {:class => "fieldRow"}, true)
          html += @template.form_label(object_name, method, options.merge({:object => object}))
          html += @template.form_field_without_capture(object_name, method, options) do
            @template.#{field_helper}(object_name, method, sanitize_field_options(options.merge({:object => object}))) +
              inner_html
          end
          html += "</dl>"
          block_given? ? @template.send(:concat, html) : html
        end
      SOURCE
      class_eval html, __FILE__, __LINE__

      # select(object, method, choices, options = {}, html_options = {})
      def select(method, choices, options = {}, html_options = {}, &block)
        options = {:label => false}.merge(options)
        inner_html = block_given? ? @template.send( :capture, &block ) : ""
        html = @template.tag(:dl, {:class => "fieldRow"}, true)
        html += @template.form_label(@object_name, method, options.merge({:object => object}))
        html += @template.form_field_without_capture(@object_name, method, options) do
          @template.select(@object_name, method, choices, sanitize_field_options(options.merge({:object => @object})), html_options) +
            inner_html
        end
        html += "</dl>"
        block_given? ? @template.send(:concat, html) : html
      end

      def time_zone_select(method, priority_zones, options = {}, html_options = {}, &block)
        options = {:label => false}.merge(options)
        inner_html = block_given? ? @template.send( :capture, &block ) : ""

        html = @template.tag(:dl, {:class => "fieldRow"}, true)
        html += @template.form_label(@object_name, method, options.merge({:object => object}))
        html += @template.form_field_without_capture(@object_name, method, options) do
          @template.time_zone_select(@object_name, method, priority_zones, sanitize_field_options(options.merge({:object => @object})), html_options) +
            inner_html
        end
        html += "</dl>"
        block_given? ? @template.send(:concat, html) : html
      end

      # check_box
      def check_box(method, options = {}, checked_value = "1", unchecked_value = "0")
        options = {:label => false, :vertical_align => :middle}.merge(options)

        html = @template.tag(:dl, {:class => "fieldRow check"}, true)
        html += @template.content_tag(:dt,
          @template.check_box(@object_name, method, sanitize_field_options(options.merge({:object => @object})), checked_value, unchecked_value),
            {:class => "box"})
        html += @template.content_tag(:dd, 
          @template.form_label_without_wrapping(@object_name, method, options),
            {:class => "label"})
        html += "</dl>"
        block_given? ? @template.send(:concat, html) : html
      end

      def help(method, *args)
        @template.help(@object_name, method, *args)
      end

      def help_link(method, *args)
        @template.help_link(@object_name, method, *args)
      end

      def help_text(method, *args)
        @template.help_text(@object_name, method, *args)
      end
      
      private
      
      # removes unnecessary field options
      def sanitize_field_options(options={})
        options.stringify_keys.reject {|k, v| %w(vertical_align label edit req lock auto popup url position help).include?(k)}.symbolize_keys
      end

    end
  end

  # This class uses the WizardFormBuilder and wraps the fields with <td>'s,
  # so they can be used in 2 column tab format
  class WizardTableFormBuilder < WizardFormBuilder
    (field_helpers - %w(check_box radio_button hidden_field) + %w(date_select time_zone_select)).each do |field_helper|
        src = <<-SOURCE
          def #{field_helper}(method, options={}, &block)
            inner_html = block_given? ? @template.send(:capture, &block) : ""
            @template.content_tag("td", super, {:class => @template.send(:cycle, 'formBoxTwoColumnsLeftColumn', 'formBoxTwoColumnsRightColumn', :name => 'form_box_two_columns'),
              :style => "vertical-align:top;"}) + inner_html
          end
        SOURCE
      class_eval src, __FILE__, __LINE__
    end

    # select(object, method, choices, options = {}, html_options = {})
    def select(method, choices, options = {}, html_options = {})
      @template.content_tag("td", super, {:class => @template.send(:cycle, 'formBoxTwoColumnsLeftColumn', 'formBoxTwoColumnsRightColumn', :name => 'form_box_two_columns'),
        :style => "vertical-align:top;"})
    end

    def time_zone_select(method, priority_zones, options = {}, html_options = {})
      @template.content_tag("td", super, {:class => @template.send(:cycle, 'formBoxTwoColumnsLeftColumn', 'formBoxTwoColumnsRightColumn', :name => 'form_box_two_columns'),
        :style => "vertical-align:top;"})
    end

  end

  #--- form element
  
  # form_element wraps a label and input tag with <dl>
  # <dl class="fieldRow">
  # ...
  # </dl>
  def form_element(*args, &block)
    content, options = filter_tag_args(*args)
    options[:class] = if dom_class = options.delete(:class)
      "fieldRow #{dom_class}"
    else 
      "fieldRow"
    end
    if block_given? && !content
      concat content_tag(:dl, capture(&block), options)
    else
      content_tag(:dl, content, options)
    end
  end

  # form element with condition
  def form_element_if(condition, *args, &block)
    form_element(*args, &block) if condition
  end

  # form element with unless condition
  def form_element_unless(condition, *args, &block)
    form_element(*args, &block) unless condition
  end

  # wraps fields in a <td> before wrapping in <dl> tags
  def form_table_element(*args, &block)
    content, options = filter_tag_args(*args)
    options[:class] = (dom_class = options.delete(:class) ? "fieldRow #{dom_class}" : 'fieldRow')
    if block_given? && !content
      concat tag("td", 
        {:class => cycle('formBoxTwoColumnsLeftColumn', 'formBoxTwoColumnsRightColumn', :name => 'form_box_two_columns'),
          :style => "vertical-align:top;"}, true)
      concat content_tag("dl", capture(&block), options)
      concat "</td>"
    else
      content_tag("td", content_tag("dl", content, options), 
        {:class => cycle('formBoxTwoColumnsLeftColumn', 'formBoxTwoColumnsRightColumn', :name => 'form_box_two_columns')})
    end
  end

  #--- form label helpers

  # form_label is a label that includes formatting left, bottom, help, etc.
  #
  # <dt class="left">
  #	  <label for="user_username">Username <span class="lock req">*</span></label>
  #   ...
  # </dt>
  #
  # e.g.
  #
  #   :label => true | false  => <dt></dt>
  #   {:label => {:text => "So what:", :position => :top | :left}}
  #   form_label :foo, :bar, {:text => "hi!", :position => :top}
  #   form_label :foo, :bar, "hi!"
  #
  def form_label(object_name, method_name, *args)
    options = args.extract_options!
    options = normalize_form_label_options(options)
    html = ""
    text = args.first || options.delete(:text)
    if text
      html += tag(:dt, {:class => "#{options.delete(:position)}"}.merge(options.delete(:html_options) || {}), true)
      html += label(object_name, method_name, text, options)
      html += '</dt>'
    end
    html
  end

  # behaves like a normal label, except it uses the same parameter as form_label
  # omits label wrapping e.g. <dt>...</dt>
  def form_label_without_wrapping(object_name, method_name, *args)
    options = args.extract_options!
    options = normalize_form_label_options(options)
    text = args.first || options.delete(:text)
    label(object_name, method_name, text, options)
  end
  
  # <dt class="left">
  #	  <label for="user_username">Username <span class="lock req">*</span></label>
  #   ...
  # </dt>
  def form_label_tag(name, options={}, &block)
    options = normalize_form_label_options(options)
    html = tag(:dt, {:class => "#{options.delete(:position)}"}.merge(options.delete(:html_options) || {}))
    html += label_tag(name, options.delete(:text), options)
    html += capture(&block) if block_given?
    html += "</dt>"
    block_given? ? concat(html) : html
  end
  
  #--- form field helpers
  
  # form_field to wrap a form field between <dd> tags
  def form_field(object_name, method, options={}, &block)
    raise "No block given for from_field" unless block_given?
    if defined?(:capture)
      form_field_with_capture(object_name, method, options, &block)
    else
      form_field_without_capture(object_name, method, options, &block)
    end
  end

  # this is used as alias for form_field in a rails view context
  def form_field_with_capture(object_name, method, options={}, &block)
    rendered, help_options = extract_form_field_help_options(options)
    options = sanitize_form_field_options(options)
    html_options = options.delete(:html_options) || {}
    html_options[:class] = "#{html_options[:class]} clearfix"
    concat tag(:dd, html_options, true)
    concat capture(&block)
    concat "</dd>"
    #concat probono_clear_class
    # add help caption
    if !help_options.blank? && rendered
      concat help_text(object_name, method, help_options)
    elsif !help_options.blank?
      concat help(object_name, method, help_options)
    end
  end

  # this is used as alias for form_field where there is no concat available
  def form_field_without_capture(object_name, method, options={}, &block)
    rendered, help_options = extract_form_field_help_options(options)
    options = sanitize_form_field_options(options)
    html_options = options.delete(:html_options) || {}
    html_options[:class] = "#{html_options[:class]} clearfix"
    html = tag(:dd, html_options, true)
    html += String(yield)
    html += "</dd>"
    unless help_options.blank?
      html += rendered ? help_text(object_name, method, help_options) : help(object_name, method, help_options)
    end
    html
  end
  
  # <dd>
  #   ...
  # <dd>
  def form_field_tag(name, options={}, &block)
    rendered, help_options = extract_form_field_help_options(options)
    options = sanitize_form_field_options(options)

    # field
    concat tag(:dd, options[:html_options] || {}, true)
    concat capture(&block)
    concat "</dd>"
    concat probono_clear_class
    # add help caption
    if !help_options.blank? && rendered
      concat help_text_tag(name, help_options)
    elsif !help_options.blank?
      concat help_tag(name, help_options)
    end
  end

  # form_field_tag with if condition
  def form_field_tag_if(condition, name, options={}, &block)
    form_field_tag(name, options, &block) if condition
  end

  private
  
  # returns a hash with top level options for label helper and slices the rest
  #
  # e.g.
  #
  #   {:text => "hi!", :position => :left, :req => true, :lock => true, :help => true}
  #   :label => {:text => "hi!"} => {:text => "hi!", ...}
  #   :label => true
  #   :label => false
  #
  def normalize_form_label_options(options={})
    defaults = {:position => :left}
    options = (!options[:label].nil? ? options[:label] : options)

    if options.is_a?(TrueClass) || options.is_a?(NilClass)
      options = defaults
    elsif options.is_a?(FalseClass)
      options = {}
    elsif options.is_a?(Hash)
      options = defaults.merge(options.symbolize_keys)
      options.reject_keys!(:edit)
    end
    options
  end

  # clean form field options of unnecessary stuff
  def sanitize_form_field_options(options={})
    options.symbolize_keys.reject {|k,v| [:disabled, :object, :help, :edit, :label, :req, :lock].include?(k)} 
  end

  # e.g. 
  #
  #  extract :help => true   ->  false, {}
  #  extract :help => "hi!"   ->   false, {:text => "hi!"}
  #  extract :help => {:text => "hi!"}   ->   false, {:text => "hi!"}
  #  extract :label => {:help => true}   ->   true, {}
  #  extract :label => {:help => "hi!"}   ->   true, {}
  #  extract :label => {:help => {:text => "hi!"}}   ->   true, {:text => "hi!"}
  #
  def extract_form_field_help_options(options={})
    options.symbolize_keys!
    rendered = false
    result = {}
    if options[:help]
      result.merge!(options[:help].symbolize_keys) if options[:help].is_a?(Hash)
      result.merge!({:text => options[:help]}) if options[:help].is_a?(String)
    end
    if options[:label]
      rendered = true if options[:label][:help]
      result.merge!(options[:label][:help].symbolize_keys) if options[:label][:help].is_a?(Hash)
      result.merge!({:text => options[:label][:help]}) if options[:label][:help].is_a?(String)
    end
    return [rendered, result]
  end
  
end
