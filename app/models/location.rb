# Location subclasses address to additionally store the latitude and longitude.
class Location < Address

  #--- associations
  has_many :kontexts
  has_many :kases,
    :through => :kontexts,
    :source => :kase,
    :foreign_key => :kase_id,
    :class_name => 'Kase'
  
  #--- mixins
  acts_as_mappable :default_units => :kms

  #--- callbacks
  before_validation_on_create :geocode_address

  #--- class methods
  class << self
    
    def kind
      :location
    end
    
    # parses the parameter for address or a geo location encoded like
    #
    #   "geo:lat = <lat> geo:lon = <lng>"
    #   "geo:lat = <lat> geo:lng = <lng>"
    #
    # or 
    #
    #   "100 Rousseau St, San Francisco, CA 94112, US"
    #
    def build_from(object)
      if object.is_a?(String)
        # empty?
        return nil if object.blank?
        # geo coordinates?
        if /geo:lat[\s]{0,}=[\s]{0,}([+-]{0,1}\d*([.]\d*)?|[.]\d+)\s/i.match("#{object} ")
          lat = $1.to_f
          if /geo:lng[\s]{0,}=[\s]{0,}([+-]{0,1}\d*([.]\d*)?|[.]\d+)\s/i.match("#{object} ") ||
            /geo:lon[\s]{0,}=[\s]{0,}([+-]{0,1}\d*([.]\d*)?|[.]\d+)\s/i.match("#{object} ")
            lng = $1.to_f
            return Location.new(:lat => lat, :lng => lng)
          end
        end
        # address, like 'San Francisco, USA'?
        if res = Location.geocode(object) and res.success
          Location.new(
            :lat => res.lat,
            :lng => res.lng,
            :street => res.street_address,
            :country_code => res.country_code,
            :postal_code => res.zip,
            :province_code => res.state,
            :city => res.city
          )
        end
      elsif object.is_a?(Location)
        object
      elsif object.is_a?(Address)
        res = Location.new(object.content_attributes)
        res.geocode_address
        res
      end
    rescue GeoKit::Geocoders::GeocodeError
      return
    end
  
    # decodes an url location
    def unescape(url_location)
      CGI::unescape(url_location) if url_location
    end

    # decodes an url location
    def escape(string)
      CGI::escape(string) if string
    end
    
  end

  #--- instance methods

  def kind
    self.class.kind
  end

  def locateable
    self.addressable
  end
  
  # overrides address to_s and removes name
  def to_s
    result = []
    result << self.address_line_1
    result << self.address_line_2
    result << self.city
    result << self.province_or_province_code
    result << self.postal_code
    result << self.country_or_country_code
    result = result.compact.map {|m| m.to_s.strip }.reject {|i| i.empty?}
    if result.empty?
      self.to_lat_lng_s
    else
      result.join(", ")
    end
  end
  
  # returns the latitude and longitude string representation
  # e.g. geo:lat = -33.3323 geo:lng = 23.232
  def to_lat_lng_s
    result = []
    result << "geo:lat=#{self.lat}" if self.lat
    result << "geo:lng=#{self.lng}" if self.lng
    result = result.compact.map {|m| m.to_s.strip}.reject {|i| i.empty?}
    result.join(" ")
  end
  
  # returns either the full country name or the country code (e.g. DE)
  def country_or_country_code
    self.country.to_s.empty? ? self.country_code : self.country
  end

  # extends attributes from address
  def geokit_attributes
    result = super
    result.merge!({
      :lat => self.lat,
      :lng => self.lng
    })
  end
  
  def geocode_address
    unless self.lng && self.lat
      geo = GeoKit::Geocoders::MultiGeocoder.geocode(self.to_s)
      errors.add_to_base(:address, I18n.t('activerecord.errors.messages.invalid')) if !geo.success
      self.lat, self.lng = geo.lat, geo.lng if geo.success
    end
  end
  
end
