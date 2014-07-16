# Extending action view helpers
module ActionView
  module Helpers
    module PrototypeHelper

      # override from vendor/rails/actionpack/lib/action_view/helpers/prototype_helper.rb
      # to support :position => :replace to do an Ajax.Replacer call, which is extended in
      # public/javascripts/prototype_ext.js
      def remote_function(options)
        options.delete(:position) if options[:position] && options[:position].to_sym == :replace
        javascript_options = options_for_ajax(options)

        update = ''
        if options[:update] && options[:update].is_a?(Hash)
          update  = []
          update << "success:'#{options[:update][:success]}'" if options[:update][:success]
          update << "failure:'#{options[:update][:failure]}'" if options[:update][:failure]
          update  = '{' + update.join(',') + '}'
        elsif options[:update]
          update << "'#{options[:update]}'"
        end

        function = update.empty? ?
          "new Ajax.Request(" :
          "new Ajax.Updater(#{update}, "

        url_options = options[:url]
        url_options = url_options.merge(:escape => false) if url_options.is_a?(Hash)
        function << "'#{escape_javascript(url_for(url_options))}'"
        function << ", #{javascript_options})"

        function = "#{options[:before]}; #{function}" if options[:before]
        function = "#{function}; #{options[:after]}"  if options[:after]
        function = "if (#{options[:condition]}) { #{function}; }" if options[:condition]
        function = "if (confirm('#{escape_javascript(options[:confirm])}')) { #{function}; }" if options[:confirm]

        return function
      end
      
    end
    
    module FormHelper

      #--- help form helpers
      
      # renders the help link, a help icon, with a help text container
      # text container only if the text is not nil
      #
      # e.g. 
      #
      #  help(:user, :login, "This is the username", :type => :error)
      #
      def help(object_name, method, *args)
        InstanceTag.new(object_name, method, self, extract_options(*args)[:object]).to_help_tag(*args)
      end

      # renders a help link icos (?)
      def help_link(object_name, method, options={})
        InstanceTag.new(object_name, method, self, options.delete(:object)).to_help_link_tag(options)
      end

      # renders only the help link
      # 
      # e.g.
      #
      #   help_text :foo, :bar, "hi!", {:display => true}
      #   help_text :foo, :bar, {:text => "hi!", :display => true}
      #  
      def help_text(object_name, method, *args)
        InstanceTag.new(object_name, method, self, extract_options(*args)[:object]).to_help_text_tag(*args)
      end
      
      private
      
      def extract_options(*args)
        args.last.is_a?(::Hash) ? args.last : {}
      end

    end
    
    module FormTagHelper
      include ActionView::Helpers::TextHelper   # markdown
      include ActionView::Helpers::ScriptaculousHelper   # visual_effect
      
      #--- label tag helpers
      
      # intercepts with standard label_tag
      # we are adding a required (*), lock (lock symbol) and a help button to the label
      # if we encounter :req and :lock in the options or embedded :label => {} parameter
      #
      # e.g.
      #
      #   label_tag :foo, "bar", {:req => true, :lock => true, :help => true}
      #
      def label_tag_with_icons(name, text = nil, options = {})
        # filter html
        options.stringify_keys!
        req_html = options['req'] || options['all'] ? content_tag(:span, "*", :class => 'req') : nil
        lock_html = options['lock'] || options['all'] ? content_tag(:span, "&nbsp;", :class => 'lock') : nil
        help_html = options['help'] ? help_link_tag(name, normalize_help_tag_options(options)) : nil

        # expand text
        text ||= name.to_s.humanize
        text += lock_html if text && lock_html
        text += req_html if text && req_html
        text += help_html if text && help_html

        options = sanitize_label_tag_options(options)
        label_tag_without_icons(name, text, options)
      end

      #--- help tag helpers
      
      # e.g.
      #
      #   help_tag :foo, "hi!", {:type => :info}
      #   help_tag :foo, {:text => "hi!", :type => :info}
      #   help_tag :foo, true  -> render a help link only
      #
      def help_tag(*args)
        name, text, options = extract_and_sanitize_help_tag_arguments(*args)
        html = help_link_tag(options['id'] || name, options)
        html += help_text_tag(options['id'] || name, text, options) unless text.blank?
        html
      end

      def help_link_tag(name, options={})
        help_link_to_function(
          visual_effect(:toggle_blind, help_text_tag_id(options['id'] || name), :duration => 0.3),
          {:id => help_link_tag_id(options['id'] || name)})
      end

      # renders the help container with text
      #
      # e.g.
      #  
      #   help_text_tag :foo, "hi!"
      #   help_text_tag :foo, {:text => "hi!", :escape => true}
      #
      def help_text_tag(*args)
        name, text, options = extract_and_sanitize_help_tag_arguments(*args)
        unless text.nil?
          text = h(text) if options.delete('escape').is_a?(TrueClass)
          text = markdown(text)
          render_help_text(text, {'id' => help_text_tag_id(name)}.merge(options))
        else
          ''
        end
      end

      private 

      # parses the help tag args
      def extract_help_tag_arguments(*args)
        name = args.delete_at(0)
        text = nil
        options = {}
        args.each do |arg|
          if arg.is_a?(TrueClass)
            text = nil
          elsif arg.is_a?(String)
            text = arg
          elsif arg.is_a?(Hash)
            options.merge!(arg)
          end
        end
        options.stringify_keys!
        text ||= options.delete('text') unless options['text'].is_a?(TrueClass)
        return [name, text, options]
      end

      # performs both parsing and sanitizing
      def extract_and_sanitize_help_tag_arguments(*args)
        name, text, options = extract_help_tag_arguments(*args)
        options = sanitize_help_tag_options(options)
        return name, text, options
      end
      
      def sanitize_help_tag_options(options={})
        options.stringify_keys!
        options.reject! {|k, v| %w(text edit for req lock auto popup url object position all help).include?(k)}
        options
      end
      
      def help_link_tag_id(id)
        "#{id}_link"
      end
      
      def help_text_tag_id(id)
        "#{id}_text"
      end
      
      # renders a help link to a js function, e.g. (?)
      def help_link_to_function(function, html_options={})
        html_options.stringify_keys!
        html_options['class'] = "questionmark #{html_options['class']}"
        link_to_function('&nbsp;', function, html_options)
      end
      
      def sanitize_label_tag_options(options={})
        options.stringify_keys.reject {|k, v| %w(display text edit for req lock auto popup url object position all help).include?(k) }
      end
      
      # Renders a box that is used to display help messages with warning, error, notice icons
      # Also used by help_text_tag to display help messages for entry fields.
      def render_help_text(text, options={})
        options.stringify_keys!
        mapping = {:notice => "helpInfo", :info => "helpInfo", :warning => "helpWarning", :error => "helpError"}

        id = options.delete('id')
        display = options.delete('display') || false
        onclick = options.delete('onclick') || visual_effect(:blind_up, id, :duration => 0.3)
        type = mapping[(options.delete('type') || 'info').to_sym]
<<-HTML
<div id="#{id}" class="helpInfoBox" onclick='#{onclick}' style="#{display ? '' : 'display:none;'}">
  <table cellpadding=0 cellspacing=0>
  	<tr>
  		<td class="helpInfoLeft">
  			<div class="#{type}"></div>
  		</td>
  		<td class="helpInfoContent">
  		  #{text}
  		</td>
  	</tr>
  </table>
</div>
HTML
      end
      
      # tries to make sense of the help options and returns a hash
      # {"help"=>{:text=>"hi!"}, ...} -> {:text=>"hi!"}
      # {:text=>"hi!"} ->  {:text=>"hi!"}
      # true -> {}
      def normalize_help_tag_options(options={})
        options.stringify_keys!
        options = !options['help'] ? options : options['help']
        options = options.is_a?(Hash) ? options.stringify_keys : {}
        options
      end
      
      # distills the text form the hash
      def text_from_normalize_help_tag_options(options={})
        options = normalize_help_tag_options(options)
        options['text'] ? options['text'] : nil
      end
      
    end
    
    class InstanceTag
      include ActionView::Helpers::TextHelper   # markdown
      include ActionView::Helpers::JavaScriptHelper  # options_for_javascript
      include ActionView::Helpers::ScriptaculousHelper   # visual_effect
      
      def to_help_tag(*args)
        help_tag(*prepend_name(*args))
      end
      
      def to_help_link_tag(options={})
        options = sanitize_help_tag_options(options)
        help_link_tag(help_link_tag_name(help_tag_name(options.delete('id'))), options)
      end
      
      def to_help_text_tag(*args)
        help_text_tag(*prepend_name(*args))
      end
      
      private

      def prepend_name(*args)
        [help_tag_name] + args
      end
      
      def help_link_tag_name(id)
        "#{id}_link"
      end

      def help_text_tag_name(id)
        "#{id}_text"
      end

      def help_tag_name(id=nil)
        id || "#{sanitized_object_name}_#{sanitized_method_name}"
      end

    end
    
  end
end
ActionView::Helpers::FormTagHelper.send(:alias_method_chain, :label_tag, :icons)