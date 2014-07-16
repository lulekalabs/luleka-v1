# Controller has the function of handling tag edits from _tag_list partial
# and showing tag results for kases, communities, topics, people
#
#
# e.g.
#
# Tag results for
#
# kases
#   /cases/tags/keyboard                                    | find all cases tagged with "keyboard"
#   /communities/apple/cases/tags/keyboard                  | find in Apple forum cases tagged with "keyboard"
#   /communities/apple/topics/imac/cases/tags/keyboard      | find in Apple's iMac forum cased tagged with "keyboard"
#
# communities
#   /communities/tags/apple                                 | find communities tagged with "apple"
#
# topics
#   /communities/apple/topics/tags/imac                     | find in Apple for topics tagged with "imac"
#
# search people
#   /people/tags/juergen+fesslmeier                         | find people tagged with "juergen" or "fesslmeier"
#
#
class TagsController < FrontApplicationController
  include TiersControllerBase
  include KasesControllerBase

  helper :kases, :property_editor, :flags,
    :tiers, :organizations, :topics, :products, :locations,
    :voteables

  #--- filters
  skip_before_filter :login_required
  before_filter :load_taggable, :only => [:create, :update, :destroy]
  before_filter :load_tier, :only => :show
  before_filter :load_topic, :only => :show
  
  #--- theme
  choose_theme :which_theme?

  #--- actions

  def show
    do_search_query(Tag.parse_param(params[:id]))
  end

  def create
    if request.xhr?
      if @taggable && params[:tag] && params[:tag][:name]
        @taggable.add_tag_with(params[:tag][:name],
          :attribute => params[:tag][:context]) unless params[:tag][:name].blank?
      
        render :update do |page|
          # edit tags update
          page.replace dom_id(@taggable, :edit_tags), :partial => 'shared/tag_list', :object => @taggable,
            :locals => {:editable => true, :edit => true, :context => @context, :update => true}
            
          # shows tags update
          page.replace dom_id(@taggable, :show_tags), :partial => 'shared/tag_list', :object => @taggable,
            :locals => {:editable => true, :edit => false, :context => @context, :update => true}
        end
        return
      end
    end
    render :nothing => true
    return
  end

  def destroy
    if request.xhr?
      if @taggable && (@taggings = @taggable.taggings_tagged_with(unescape_with_wildcard(params[:id]), @context)) && !@taggings.blank?
        @tag = @taggings[0].tag
        @taggings.map(&:destroy)
      
        render :update do |page|
          page.replace dom_id(@tag, :edit_tag), ''
          page.replace dom_id(@tag, :show_tag), ''
        end
        return
      end
    end
    render :nothing => true
    return
  end

  # callback from fast_autocomplete
  def autocomplete
    render :json => context_class.tag_counts_on(params[:context] || "tags", 
      :conditions => ["#{Tag.table_name}.name LIKE ?", "%#{params[:name]}%"]).map {|t| [t.name, t.id]}.to_json
  end

  protected
  
  def load_taggable
    if params[:kase_id]
      @taggable = Kase.find_by_permalink(params[:kase_id])
    end
    
    # alias tag type
    @context = if params[:context]
      params[:context]
    elsif params[:tag] && params[:tag][:context]
      params[:tag][:context]
    end
  end
  
  # determine which theme we should set?
  def which_theme?
    if @taggable && @taggable.is_a?(Response)
      :response
    else
      :case
    end
  end
  
  # inserts SQL wildcard (it is not * but _) for space, dashes and underscores
  def unescape_with_wildcard(name)
    if name
      name.gsub!(/-/, '_')
      name.gsub!(/\+/, '_')
      name.gsub!(/%/, '_')
      name.gsub!(/_/, '_')
    end
    name
  end
  
  def tier_class
    @tier_class || Tier
  end

  def topic_class
    @topic_class || Topic
  end

  # override from kases controller base
  def kase_class
    @kase_class || Kase
  end

  def load_tier
    if id = tier_param_id
      @tier = Tier.find_by_permalink_and_region_and_active(id)
      @tier_class = @tier.class if @tier
    end
  end

  def load_topic
    if @tier && id = topic_param_id
      @topic = @tier.topics.find_by_permalink_and_region_and_active(id)
      @topic_class = @topic.class if @topic
    end
  end
  
  # Depending on the requests, determines what to look for
  # the first occurence of tags and guesses which context type to return:
  # :kase, :tier, :topic, :person
  def context_type
    @context_type || @context_type = find_context_type_from_uri
  end

  # returns class for context_type, e.g. :tier => Tier
  def context_class
    "#{context_type}".capitalize.constantize
  end

  # render search query based on the search context
  #
  # e.g.
  #
  #   do_search_query(["ruby", "rails"])
  #
  def do_search_query(tags)
    unless tags.blank? && context_type.blank?
      if :kase == context_type
        #--- kase tags
        @kases = if @topic
          @topic.kases.find(:all, kase_class.find_options_for_query(tags))
        elsif @tier
          @tier.kases.find(:all, kase_class.find_options_for_query(tags))
        else
          kase_class.find_by_query(:all, tags)
        end
        unless @kases.blank?
          render :template => 'kases/index'
          return
        end
      elsif :tier == context_type
        #--- tier tags
        @tiers = Tier.find_all_by_query(tags)

        do_search_most_recent_tiers
        do_search_most_popular_tiers

        unless @tiers.blank?
          render :template => 'tiers/index'
          return
        end
      elsif :topic == context_type
        #--- topic tags
        @topics = @tier.topics.find(:all, topic_class.find_options_for_query(tags))
        do_search_popular_topics
        
        unless @topics.blank?
          render :template => 'topics/index'
          return
        end
      elsif :person == context_type
        #--- person tags
        @people = Person.find_all_by_query(tags)
        unless @people.blank?
          render :template => 'people/index'
          return
        end
      end
    end
    render :template => 'searches/no_result'
  end

  private

  # derives search context (cases, people, etc.) from the URI
  #
  # e.g.
  #
  #   /communities/luleka/cases/tags/foo+bar  ->  :kase
  #   /communities/search/foo+bar  ->  :tier
  #
  def find_context_type_from_uri
    found = false
    request.request_uri.split('/').reverse.each do |comp|
      if found
        return @context_type = case comp
        when /kases|kases/i, Regexp.new("#{Kase.human_resources_name}|#{Kase.human_resource_name}", Regexp::IGNORECASE) then :kase
        when /tiers|tier/i, Regexp.new("#{Tier.human_resources_name}|#{Kase.human_resource_name}", Regexp::IGNORECASE) then :tier
        when /organizations|organization/i, Regexp.new("#{Organization.human_resources_name}|#{Organization.human_resource_name}", Regexp::IGNORECASE) then :organization
        when /topics|topic/i, Regexp.new("#{Topic.human_resources_name}|#{Topic.human_resource_name}", Regexp::IGNORECASE) then :topic
        when /products|product/i, Regexp.new("#{Product.human_resources_name}|#{Product.human_resource_name}", Regexp::IGNORECASE) then :product
        when /services|service/i, Regexp.new("#{Service.human_resources_name}|#{Service.human_resource_name}", Regexp::IGNORECASE) then :service
        when /people|person/i, Regexp.new("#{Person.human_resources_name}|#{Person.human_resource_name}", Regexp::IGNORECASE) then :person
        end
      end
      found = true if comp =~ /tag|tags|search|searches/i
    end
    nil
  end
  
end
