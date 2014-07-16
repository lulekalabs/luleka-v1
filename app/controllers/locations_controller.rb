# handles location based views to browse people and kases by
# 
#   * tags
#   * person
#   * kase
#
class LocationsController < FrontApplicationController
  helper :people
  
  #--- filters
  before_filter :load_gmap_key, :only => [:index, :show]
  before_filter :load_origin
  before_filter :load_radius
  before_filter :load_organization_or_organizations
  before_filter :load_kase_or_kases
  before_filter :load_people

  #--- actions

  def index
  end
  
  def show
  end
  
  protected

  # loads address from :l parameter or takes the current user's location as origin
  def load_origin
    @locations = []
    if params[:id]
      @origin = GeoKit::Geocoders::MultiGeocoder.geocode(Location.unescape(params[:id]))
    else
      if logged_in?
        @origin = current_user.person.geo_location
      else
        @origin = GeoKit::Geocoders::MultiGeocoder.geocode(Utility.country_code)
      end
    end
  end
  
  # assigns @radius in kilometers from :r parameter, 50 kilometers by default
  def load_radius
    @radius = params[:r].to_i if params[:r]
    @radius ||= LOCATIONS_RADIUS
  end
  
  # a) /organization/all/location  ->  organizations
  # a1) /tags/:tag_id/organizations/all/location  ->  organizations tagged with :tag_id
  # b) /organization/:organization_id/location  ->  kases, employees
  def load_organization_or_organizations
    if params[:organization_id] && Organization::ALL_ID == params[:organization_id].downcase
      if params[:tag_id]
        # a1)
        @organizations = Organization.find_tagged_with(Tag.parse_param(params[:tag_id]), {
          :origin => @origin,
          :within => @radius,
          :conditions => {:status => 'active'},
          :limit => LOCATIONS_LIMIT
        })
      else
        # a)
        @organizations = Organization.find(:all, {
          :origin => @origin,
          :within => @radius,
          :conditions => {:status => 'active'},
          :limit => LOCATIONS_LIMIT
        })
      end
      @locations += @organizations unless @organizations.blank?
    elsif params[:organization_id] && !params[:kase_id]
      # b)
      if @organization = Organization.find_by_permalink_and_region_and_active(params[:organization_id], {
          :conditions => ["organizations.lng IS NOT NULL AND organizations.lat IS NOT NULL"]})
        @locations << @organization
        @origin = @organization.geo_location || @origin
      end
    end
    true
  end

  # a) /kase/all/location                   ->  all kases (max 100)
  # a2) /organization/:organization_id/kases/all/location
  # a4) /tags/:tag_id/organization/:organization_id/kases/all/location  -> tagged kases of organization
  # a5) /tags/:tag_id/kases/all/location    ->  all kases tagged with :tag_id
  # b) /kase/:id/location       ->  kase, qualified partners, people with similar kases
  def load_kase_or_kases
    if params[:kase_id] && Kase::ALL_ID == params[:kase_id].downcase
      if @organization && params[:tag_id]
        # a4)
        @kases = Kase.find_tagged_with(Tag.parse_param(params[:tag_id]), {
          :origin => @origin,
          :within => @radius,
          :include => :kontexts,
          :conditions => ["kontexts.organization_id = ?", @organization.id],
          :limit => LOCATIONS_LIMIT
        }.merge_finder_options(Kase.find_options_for_active))
      elsif @organization
        # a2)
        @kases = @organization.kases.find(:all, {
          :origin => @origin,
          :within => @radius,
          :limit => LOCATIONS_LIMIT
        }.merge_finder_options(Kase.find_options_for_active))
      elsif params[:tag_id]  
        # a5)
        @kases = Kase.find_tagged_with(Tag.parse_param(params[:tag_id]), {
          :origin => @origin,
          :within => @radius,
          :limit => LOCATIONS_LIMIT
        }.merge_finder_options(Kase.find_options_for_active))
      else
        # a)
        @kases = Kase.find(:all, {
          :origin => @origin,
          :within => @radius,
          :limit => LOCATIONS_LIMIT
        }.merge_finder_options(Kase.find_options_for_active))
      end
      @kases.sort_by_distance_from(@origin) if @kases
      @locations += @kases unless @kases.blank?
    elsif params[:kase_id]
      # b)
      if @kase = Kase.find_by_permalink(params[:kase_id], {
          :conditions => ["kases.lng IS NOT NULL AND kases.lat IS NOT NULL"]
        }.merge_finder_options(Kase.find_options_for_active))
          @locations << @kase
          @origin = @kase.geo_location
      end
    end
    true
  end
  
  def load_people
    if params[:person_id] && @person = Person.find_by_permalink(params[:person_id])
      # person_id
      @locations << @person
      @origin = @person.geo_location || @origin
      @locations << @kases = Kases.find(:all, {
        :origin => @origin,
        :within => @radius,
        :limit => LOCATIONS_LIMIT
      }.merge_finder_options(Kase.find_options_for_active)) if !@kases.blank? && @organizations.blank?
    elsif !@kase && !@organization
      # current user
      @locations << @person
      @origin = @person.geo_location || @origin
      @locations << @kases = @person.kases.find(:all, {
        :origin => @origin,
        :within => @radius,
        :limit => LOCATIONS_LIMIT
      }.merge_finder_options(Kase.find_options_for_active)) if !@kases.blank? && @organizations.blank?
    else
      @person = nil
    end
    
    @locations += @partners = @kase.find_matching_partners({
      :origin => @origin,
      :within => @radius,
      :limit => LOCATIONS_LIMIT
    }) if @kase
    
    # employees of @organization
    @locations += @employees = @organization.employees.find(:all,
      :origin => @origin,
      :within => @radius,
      :limit => LOCATIONS_LIMIT
    ) if @organization
    
    true
  end
  
end
