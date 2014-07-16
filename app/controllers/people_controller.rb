# provides action to show a list of members and edit person profile
class PeopleController < FrontApplicationController
  include PropertyEditor
  include FlagsControllerBase
  include TiersControllerBase
  helper :users, :partners, :property_editor, :kases, :flags,
    :tiers, :organizations, :topics, :products, :locations

  #--- constants
  SIDEBAR_ITEMS_COUNT = 5

  #--- filters
  skip_before_filter :login_required, :only => [:index, :list_item_expander, :show, :kases, :search, :pcard]
  before_filter :load_tier
  before_filter :load_topic
  before_filter :load_profile_or_redirect, :only => [:show, :edit, :contacts, :followers, :shared_contacts, 
    :visitors, :kases, :matching_kases, :responded_kases]
  before_filter :load_gmap_key, :only => :show
  before_filter :add_visit, :only => :show
  before_filter :ensure_current_url, :only => :show

  #--- layout
  layout :choose_layout

  #--- theme
  choose_theme :which_theme?

  #--- class methods
  class << self
    
    def profile_action(class_name, method_name, options={})
      partial = options.delete(:partial)
      name = options.delete(:name) || :profile
          
      # edit
      define_method "edit_#{method_name}_in_place" do 
        if request.get? && request.xhr?
          object_name = params[:object_name]
          method_name = params[:method_name]
          klass = class_name.to_s.pluralize.classify.constantize
          object = if class_name == :person
            klass.find_by_permalink(params[:id])
          else
            klass.find(params[:id])
          end
          render :partial => 'people/profile_property_in_place', :object => object, :locals => {
            :edit => true, :object_name => object_name, :method_name => method_name,
            :update => true, :partial => partial, :locals => {
              :object_name => object_name,
              :method_name => method_name,
              :edit => true
            }
          }
        else
          render :nothing => true
        end
      end
      
      # update
      define_method "update_#{method_name}_in_place" do
        if request.put? && request.xhr?
          object_name = params[:object_name]
          method_name = params[:method_name]
          klass = class_name.to_s.pluralize.classify.constantize
          object = if class_name == :person
            klass.find_by_permalink(params[:id])
          else
            klass.find(params[:id])
          end
          object.attributes = property_attributes_for_params(name)
          if object.valid?
            object.save
            render :partial => 'people/profile_property_in_place', :object => object, :locals => {
              :edit => false, :object_name => object_name, :method_name => method_name,
              :update => true, :editable => true, :partial => partial, :locals => {
                :object_name => object_name,
                :method_name => method_name,
                :edit => false
              }
            }
          else
            render :text => form_error_messages_for(object), :status => 444
          end
        end
      end
    end
    
  end

  #--- actions
  property_action :person, :summary, :partial => 'people/text_area_summary', :name => :profile
  profile_action :person, :have_expertise, :partial => 'people/text_area_tags'
  profile_action :person, :want_expertise, :partial => 'people/text_area_tags'
  profile_action :person, :spoken_language_ids, :partial => 'shared/form_select_spoken_languages'
  profile_action :person, :interest, :partial => 'people/text_area_tags'
  profile_action :person, :home_page_url, :partial => 'people/text_area_link'
  profile_action :person, :blog_url, :partial => 'people/text_area_link'
  profile_action :person, :twitter_name, :partial => 'shared/form_twitter_name'
  profile_action :address, :personal_address_attributes, :partial => 'shared/address',
    :name => [:profile, :personal_address_attributes]
  profile_action :address, :business_address_attributes, :partial => 'shared/address',
    :name => [:profile, :business_address_attributes]

  profile_action :person, :education, :partial => 'people/education'
  profile_action :person, :work, :partial => 'people/work'

  
  def index
    @people = if @topic
      do_search_people(@topic.people, nil, :with_tags => !request.xhr?,
        :sort_display => true, :url => hash_for_people_path)
    elsif @tier
      do_search_people(@tier, :people, :with_tags => !request.xhr?,
        :sort_display => true, :url => hash_for_people_path)
    else
      do_search_people(Person, :find_all_active, :with_tags => !request.xhr?,
        :sort_display => true, :url => hash_for_people_path)
    end
  end

  # expands or retracts each list item using the (+) and (x) icons
  def list_item_expander
    respond_to do |format|
      format.html {
        render :nothing => true, :status => :no_content
      }
      format.js {
        @person = Person.find_by_permalink(params[:id])
        render :partial => 'people/list_item_content', :object => @person, :locals => {
          :expanded => params[:expanded].to_s.index(/1/) ? false : true
        }
      }
    end
  end
  
  def show
    # nothing else to do here
  end
  
  def edit
    # if current user is not this profile then we are not allowed to edit
    unless current_user_me?(@profile)
      redirect_to person_path(@profile)
      return
    end
  end
  
  # renders tiny profilecard version to preview a person's profile (inside a popup or tooltip)
  def pcard
    raise ActionController::UnknownAction if !request.xhr? && RAILS_ENV != "development"
    @profile = Person.find_by_permalink(params[:id]) if params[:id]
    do_render_pcard
  end

  # forward to current person's profile
  def me
    if @person
      redirect_to person_path(@person)
    else
      redirect_to people_path
    end
    return
  end
  
  # put /person/:id/follow
  def follow
    if request.xhr?
      if current_user && @profile = Person.find_by_permalink(params[:id])
        if current_user != @profile
          @follow = current_user.person.follow(@profile)
          flash[:warning] = "You have subscribed to receive updates from \"%{name}\"".t.to_sentence % {:name => @profile.username_or_name}
        end
      end
    else
      render :nothing => true
      return
    end
  end

  # put /person/:id/stop_following
  def stop_following
    if request.xhr?
      if current_user && @profile = Person.find_by_permalink(params[:id])
        if current_user != @profile
          @follow = current_user.person.stop_following(@profile)
          flash[:warning] = "You have unsubscribed to receive updates from \"%{name}\"".t.to_sentence % {:name => @profile.username_or_name}
        end
      end
    else
      render :nothing => true
      return
    end
  end

  # delete /person/:id/destroy_contact
  def destroy_contact
    if request.xhr?
      if current_user && @person = Person.find_by_permalink(params[:id])
        if current_user != @person
          @friendship = current_user.person.is_not_friends_with(@person)
          flash[:warning] = "\"%{name}\" has been removed from your contacts".t.to_sentence % {:name => @person.casualize_name}
        end
      end
    else
      render :nothing => true
      return
    end
  end
  
  # get /people/:id/kases
  def kases
    @title = "%{kases} started by %{name}".t % {:kases => Kase.human_name(:count => 2),
      :name => @profile.username_or_name}
    @kases = do_search_kases(@profile.kases, nil, :with_tags => !request.xhr?,
      :sort_display => true, :url => hash_for_kases_path)
    render :template => 'kases/index' unless request.xhr?
    return
  end

  # get /people/:id/matching_kases
  def matching_kases
    if @profile == @person
      @title = "%{kases} matching my experience".t % {:kases => Kase.human_name(:count => 2)}
    else
      @title = "%{kases} matching experience of %{name}".t % {:kases => Kase.human_name(:count => 2), 
        :name => @profile.username_or_name}
    end    
    @kases = do_search_kases(@profile, :find_matching_kases, :with_tags => !request.xhr?,
      :sort_display => true, :url => hash_for_kases_path)
    render :template => 'kases/index' unless request.xhr?
    return
  end

  # get /people/:id/responded_kases 
  def responded_kases
    @title = "My Recommendations".t
    @kases = do_search_kases(@profile, :responded_kases, :with_tags => !request.xhr?,
      :sort_display => false, :url => hash_for_kases_path)
    render :template => 'kases/index' unless request.xhr?
    return
  end

  # get /people/:id/contacts
  def contacts
    @people = do_search_people(@profile.friends, nil, :with_tags => !request.xhr?,
      :sort_display => true, :url => hash_for_people_path)
  end

  # get /people/:id/shared_contacts
  def shared_contacts
    if request.xhr? && params[:sidebar]
      render :partial => 'shared/sidebar_profile_list', :object => @shared_contacts, :locals => {:link => true}
      return
    else
      @people = do_search_people(@profile.shared_friends_with(@person), nil, :with_tags => !request.xhr?,
        :sort_display => true, :url => hash_for_people_path)
      render :action => 'index'
    end
  end

  # get /people/:id/visitors
  def visitors
    if request.xhr? && params[:sidebar]
      render :partial => 'shared/sidebar_profile_list', :object => @visitors, :locals => {:link => true}
      return
    else
      @people = do_search_people(@profile.visitors, nil, :with_tags => !request.xhr?,
        :sort_display => true, :url => hash_for_people_path)
    end
  end

  # get /people/:id/followers
  def followers
    if request.xhr? && params[:sidebar]
      render :partial => 'shared/sidebar_profile_list', :object => @followers, :locals => {:link => true}
      return
    else
      @people = do_search_people(@profile.followers, nil, :with_tags => !request.xhr?,
        :sort_display => true, :url => hash_for_people_path)
    end
  end

  def reputable
    # find all properous
    # highest earnings?
  end
  
  def popular
    # find all popular
    # most votes?
  end

  def partners
    if request.xhr? && params[:sidebar]
      render :partial => 'shared/sidebar_profile_list', :object => @followers, :locals => {:link => true}
      return
    else
      @title = "Partners"
      @people = do_search_people(Person, :find_all_partners, :with_tags => !request.xhr?,
        :sort_display => true, :url => hash_for_people_path)
      render :action => 'index'
    end
  end

  # edit avatar
  def edit_avatar
    render :text => " " and return
  end

  def update_avatar
    if request.put?
      @profile = Person.find_by_permalink(params[:id])
      @profile.attributes = params[:profile]
      if @profile.save
        responds_to_parent do
          render :update do |page|
            page.replace dom_id(@profile, :overview), :partial => 'people/profile_overview', :object => @profile
          end
        end
        return
      end
    end
    render :nothing => true
  end
  
  def destroy_avatar
    if request.delete?
      if @profile = Person.find_by_permalink(params[:id])
        @profile.avatar.destroy if @profile.avatar.file?
        render :update do |page|
          page.replace dom_id(@profile, :overview), :partial => 'people/profile_overview', :object => @profile
        end
        return
      end
    end
    render :nothing => true
  end

  # AJAX call for updating address form in _profile
  def profile_address_in_place
    if request.xml_http_request?
      begin
        @address = Address.find( params[:id] )
        case params[:type].to_s.to_sym
        when :save
          # saving changes
          @address.attributes = params[@address.kind]
          @address.save!
          render :partial => 'shared/profile_address_in_place', :locals => { :address => @address, :update => true, :editable => true }
        when :edit
          # swithcing to edit mode
          render :partial => 'shared/profile_address_in_place', :locals => { :address => @address, :update => true, :edit => true }
        end
      rescue ActiveRecord::RecordInvalid => ex
        render :text => form_error_messages_for(:address), :status => 444
      rescue Exception => ex
        flash[:error] = "There were unexpected errors.".t
        render :text => form_flash_messages, :status => 444
      end
    end
  end

  # profile_spoken_languages_in_place
  def profile_spoken_languages_in_place
    if request.xml_http_request?
      begin
        @person = Person.find( params[:id] )
        case params[:type].to_s.to_sym
        when :save
          # saving changes
          assign_spoken_languages_to_person( @person, params[:spoken_languages] )
          @person.save!
          render :partial => 'profile_spoken_languages_in_place', :locals => { :person => @person, :update => true, :editable => true }
        when :edit
          # swithcing to edit mode
          render :partial => 'profile_spoken_languages_in_place', :locals => { :person => @person, :update => true, :edit => true }
        end
      rescue ActiveRecord::RecordInvalid => ex
        render :text => form_error_messages_for(:person), :status => 444
      rescue Exception => ex
        flash[:error] = "There were unexpected errors.".t
        render :text => form_flash_messages, :status => 444
      end
    end
  end

  protected 

  def tier_class
    @tier_class || Tier
  end
  
  def topic_class
    @topic_class || Topic
  end

  # adds a visit @profile (Person instance) by current_person or session_id, if:
  # 
  #   * this is not a robot, and
  #   * this is not my own profile, or
  #   * the user is not signed in
  #
  def add_visit
    @profile.view(@person || session.session_id) if !request_from_robot? && (!@person || (@person && current_user_not_me?(@profile)))
    true
  end

  # used when routes /organizations/xxx/people... in before_filter is loaded
  def load_tier
    if id = tier_param_id
      @tier = Tier.find_by_permalink_and_region_and_active(id)
      @tier_class = @tier.class if @tier
    end
  end

  # used when routes /tiers/luleka/products/xxx/people... in before_filter is loaded
  def load_topic
    if @tier && id = topic_param_id
      @topic = @tier.topics.find_by_permalink_and_region_and_active(id)
      @topic_class = @topic.class if @topic
    end
  end
  
  # loads a person instance and stores it in @profile
  def load_profile_or_redirect
    if params[:id] && @profile = Person.find_by_permalink(params[:id]) # :include => [:recent_visits_from, :friends],
#        :order => "friendships.created_at DESC, visits.created_at DESC")
    
      #--- only me or friends/contacts
      if current_user_me?(@profile) || current_user_friends_with?(@profile)
        # contacts
        @contacts = @profile.friends.paginate(
          :page => 1, :per_page => SIDEBAR_ITEMS_COUNT
        )
        @contacts = nil if @contacts && @contacts.empty?
        @contacts_count = @profile.friends.count

        # followers
        @followers_count = @profile.followers_count
        @followers = @profile.followers
        @followers = nil if @followers && @followers.empty?
      end

      #--- everyone, except me
      if current_user_not_me?(@profile)
        # shared contacts
        @shared_contacts = @profile.shared_friends_with(@person).paginate(
          :page => 1, :per_page => SIDEBAR_ITEMS_COUNT
        ) 
        @shared_contacts = nil if @shared_contacts && @shared_contacts.empty?
        @shared_contacts_count = @profile.shared_friends_with(@person).size if @profile
      end
    
      #--- only me
      if current_user_me?(@profile)
        # recent visitors
        @visitors = @profile.viewers.paginate(
          :order => "people.id", :page => 1, :per_page => SIDEBAR_ITEMS_COUNT
        ) if current_user_me?(@profile)
        @visitors = nil if @visitors && @visitors.empty?
#        @visitors_count = @profile.visits_count if @profile
      end
      
      # return to before_filter pipeline
      true
    else
      redirect_to contacts_path
      return false
    end
  end

  # returns an alternative lowercase translateable name for an action 
  # to be overidden in subclasses
  def action_synonym(name=self.action_name)
    case "#{name}"
    when /index/, /show/ then "overview".t
    when /members/ then @tier && @tier.is_a?(Organization) ? "employees".t : "members".t
    else "#{name}".gsub(/_/, '').t
    end
  end
  helper_method :action_synonym

  # checks to see if permalink is still current, if not redirect to current slug
  def ensure_current_url
    return true # TODO: enable with friendly_id 3
    if (@person && @person.has_better_id?)
      redirect_to person_url(@person), :status => :moved_permanently
    end
  end

  # renders pcard for @profile
  def do_render_pcard(options={})
    if @profile 
      respond_to do |format|
        format.js { render :template => "people/pcard", :layout => false, :locals => options }
        format.html { RAILS_ENV == "production" ? render(:nothing => true, :status => :no_content) : nil }
      end
    else
      render :nothing => true, :status => :no_content
    end
  end
  
  private
  
  # Helper to choose a layout based on conditions
  def choose_layout
    # this for making the avatar upload work with iframe
    ["profile_overview_avatar_in_place"].include?(action_name) ? false : super
  end

  # choose theme based on action
  def which_theme?
    [:kases].include?(self.action_name.to_sym) ? :issue : :profile
  end

  # reads the parameters based on the :name option passed in to property_action
  # for in place properties
  def property_attributes_for_params(name=nil)
    name = [name].flatten
    case name.size
      when 1 then params[name[0]]
      when 2 then params[name[0]][name[1]]
      when 3 then params[name[0]][name[1]][name[2]]
    else
      raise "Can't read attributes"
    end
  end
  
end
