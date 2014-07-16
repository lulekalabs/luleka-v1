module HomePagesHelper

  # prints a list of search order options
  def search_order_list(list, active=nil)
    html = "<ul>"
    index = 0
    list.each do |key, value|
      html << content_tag(:li,
        link_to_function(value, ''),
        :class => active ? (key == active ? 'active' : nil) : (0 == index ? 'active' : nil)
      )
      html << content_tag(:li, "&nbsp;|&nbsp;") unless index == list.size - 1
      index += 1
    end
    html << "</ul>"
  end

  # similar to dom_id but allows strings/symbols to name a dom element 
  # in key visual forms
  #
  # e.g.
  #
  #   kv_dom_class(:kase, :form)  ->  'form_kase'
  #   kv_dom_class(Kase, :form)
  #
  def kv_dom_class(name, prefix=nil)
    if name.is_a?(Class)
      dom_class(name, prefix)
    else
      "#{prefix ? prefix.to_s + '_' : ''}#{name}"
    end
  end

end
