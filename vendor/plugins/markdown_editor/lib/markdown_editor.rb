module MarkdownEditor
  module FormHelper

    # adds observer to attach textarea widget, which has two featuers:
    #
    #   1. autogrow a textarea
    #   2. monitors the remaining characters left to enter
    #
    # options:
    #   :max_height => <size in pixels, default: 256>
    #   :max_length => <optional, maximum length in characters, e.g. 140>
    #   :length_id => <optional, dom element name, e.g. 'remainingCharacters'>
    #   :line_height => <size in pixels per line, default: 16>
    #
    def text_area_widget_observer(object_name, method, options={})
      options = {:max_height => 256}.merge(options)
      id = text_area_widget_dom_id(object_name, method, options)
      options.delete(:id)
      javascript_tag <<-JS
document.observe('dom:loaded', function() {
  new Widget.Textarea('#{id}', #{options.to_json});
});
      JS
    end

    # include to the output the span and javascript tag needed for the helper
    def markdown_editor_output(textarea, object_name, method, id)
      name = method.nil? ? "#{id}" : "#{object_name}_#{method}"
      
      out = textarea
      
      js = <<-JS
document.observe('dom:loaded',function(){
  new Markdown.Textarea('#{name}');
});
      JS
      
      out << js
      out    
    end
    
    # adds the observer javascript to the markdown editor
    # if :preview_id option is given, the preview will be rendered
    # into it
    def markdown_editor_observer(object_name, method, options={})
      id = markdown_editor_dom_id(object_name, method, options)
      if preview_id = options[:preview_id]
        javascript_tag <<-JS
document.observe('dom:loaded',function(){
  new Markdown.Textarea('#{id}', '#{preview_id}');
});
        JS
      else
        javascript_tag <<-JS
document.observe('dom:loaded',function(){
  new Markdown.Textarea('#{id}');
});
        JS
      end 
    end

    # just returns the javascript for the markdown editor
    def markdown_editor_javascript(object_name, method, options={})
      id = markdown_editor_dom_id(object_name, method, options)
      if preview_id = options[:preview_id]
        <<-JS
new Markdown.Textarea('#{id}', '#{preview_id}');
        JS
      else
        <<-JS
new Markdown.Textarea('#{id}');
        JS
      end 
    end

    # javascript wrapped in a tag
    def markdown_editor_javascript_tag(object_name, method, options={})
      javascript_tag(markdown_editor_javascript(object_name, method, options))
    end
    
    def markdown_editor_tag(name, value = nil, options = {})
      options[:id] ||= name
      options[:class] ||= "markdown_editor"
    
      textarea = content_tag :textarea, nil, { 
                   "id" => options[:id], 
                   "name" => name,
                   "class" => options[:class],
                   "value" => value}.update(options.stringify_keys)

      return markdown_editor_output(textarea, name, nil, options[:id])
    end

    def markdown_editor(object, method, options = {})     
      obj = options[:object] || instance_variable_get("@#{object}")
      options[:class] ||= "markdown_editor"
         
      textarea = ActionView::Helpers::InstanceTag.new(object, method, self, nil, options.delete(:object))
      return markdown_editor_output textarea.to_text_area_tag(options), object, method, nil 
    end
    
    private
    
    def markdown_editor_dom_id(object_name, method, options={})
      options[:id] ? "#{options[:id]}" : "#{object_name}_#{method}"
    end

    def text_area_widget_dom_id(object_name, method, options={})
      options[:id] ? "#{options[:id]}" : "#{object_name}_#{method}"
    end
    
  end 
end

module ActionView
  module Helpers
    class FormBuilder
      def markdown_editor(method, options = {})
        @template.markdown_editor(@object_name, method, options.merge(:object => @object))
      end
    end
  end
end
