module PagesHelper

  # returns either id class options for div tag for page
  def page_div_tag_options(page=nil, options={})
    result = {:id => "page"}
    if page
      unless page.dom_id.blank?
        result = result.merge(:id => page.dom_id)
      end
      unless page.dom_class.blank?
        result = result.merge(:class => page.dom_class) 
      end
    end
    result = result.merge(options)
    result
  end

  def parse_page_html
    html = @page.html
    
    context = Radius::Context.new do |c|

      # <r:email href="jobs@luleka.com">Jobs</r:email>
      c.define_tag 'email' do |tag|
        href = (tag.attr['href'] || 'admin@luleka.com')
        if (name = tag.expand) && !name.blank?
          mail_to(href, name, :encode => 'javascript')
        else
          mail_to(href, href, :encode => 'javascript')
        end
      end
      
      # <r:profile name="juergen" />
      c.define_tag 'profile' do |tag|
        name = (tag.attr['name'])
        team_profile_tag(name)
      end
      
    end
    
    # create a parser to parse tags that begin with 'r:'
    parser = Radius::Parser.new(context, :tag_prefix => 'r')

    # parse tags and output the result
    html = parser.parse(html)
  end

  # renders a person's profile by permalink
  def team_profile_tag(permalink)
    if person = Person.finder(permalink)
      <<-HTML
<div class="profile">
  <div class="fl">
    #{avatar_link_to(person, {:name => :profile, :size => "55x55"})}
  </div>
  <div class="fl info">
    <strong>#{link_to person.name, person_path(person)}</strong>
    <br />
    #{person.professional_title}
  </div>
  <div class="clearClass"></div>
</div>  
      HTML
    end
  rescue ActiveRecord::RecordNotFound
    ''
  end

end
