module VoteablesHelper
  
  # returns html for a vote control used in kases and responses
  def vote_control(object, up_html_options={}, down_html_options={})
    up_html_options = {
      :rel => "nofollow",
      :title => case object.class.base_class.name
      when /Kase/ then ["This %{type} is useful and clear".t % {:type => object.class.human_name}, "Click again to undo".t].to_sentences
      when /Response/ then ["This reply is useful".t, "Click again to undo".t].to_sentences
      end
    }.merge(up_html_options)
    down_html_options = {
      :rel => "nofollow",
      :title => case object.class.base_class.name
      when /Kase/ then ["This %{type} is unclear and not useful".t % {:type => object.class.human_name}, "Click again to undo".t].to_sentences
      when /Response/ then ["This reply is not useful".t, "Click again to undo".t].to_sentences
      end
    }.merge(down_html_options)

    html = tag(:div, {:class => 'vote', :id => dom_id(object, :vote)}, true)
      html << content_tag(:span, 
        link_to_remote('', {:url => vote_up_member_path(object), :method => :put}, up_html_options), 
          :class => 'up')
      html << content_tag(:span, object.votes_sum.to_i, :class => 'text')
      html << content_tag(:span,
        link_to_remote('', {:url => vote_down_member_path(object), :method => :put}, down_html_options),
          :class => 'down')
    html << "</div>"
    html
  end
  
end
