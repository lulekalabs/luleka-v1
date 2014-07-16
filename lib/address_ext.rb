# extends acts_as_addressable address class
require 'academic_title'
class Address < ActiveRecord::Base
  
  #--- class variables
  @@middle_name_column = :middle_name

  #--- associations
  belongs_to :academic_title
  
  #--- validations
  validates_presence_of :postal_code, :if => Proc.new {|u| [:business, :billing].include?(u.kind)}
  validates_presence_of :city, :street, :if => Proc.new {|u| [:business, :billing].include?(u.kind)}

  # phone
  validates_presence_of :phone, :if => Proc.new {|u| [:business].include?(u.kind)}
  
  # province
  validates_presence_of :province, 
    :if => Proc.new {|u| [:personal, :business, :billing].include?(u.kind) && !u.province_code}
  validates_presence_of :province_code,
    :if => Proc.new {|u| [:personal, :business, :billing].include?(u.kind) && !u.province}

  # country
  validates_presence_of :country_code, :if => Proc.new {|a| a.country.nil? &&
    [:personal, :business, :billing].include?(a.kind)}
  validates_presence_of :country, :if => Proc.new {|a| a.country_code.nil? &&
      [:personal, :business, :billing].include?(a.kind)}

  #--- acl
  allows_display_of :street,        :if => Proc.new {|o| o.accepts_right? :street, User.current_user}
  allows_display_of :city,          :if => Proc.new {|o| o.accepts_right? :city, User.current_user}
  allows_display_of :zip,           :if => Proc.new {|o| o.accepts_right? :zip, User.current_user}
  allows_display_of :province,      :if => Proc.new {|o| o.accepts_right? :province, User.current_user}
  allows_display_of :province_code, :if => Proc.new {|o| o.accepts_right? :province_code, User.current_user}
  allows_display_of :country,       :if => Proc.new {|o| o.accepts_right? :country, User.current_user}
  allows_display_of :country_code,  :if => Proc.new {|o| o.accepts_right? :country_code, User.current_user}
  allows_display_of :phone,         :if => Proc.new {|o| o.accepts_right? :phone, User.current_user}
  allows_display_of :mobile,        :if => Proc.new {|o| o.accepts_right? :mobile, User.current_user}
  allows_display_of :fax,           :if => Proc.new {|o| o.accepts_right? :fax, User.current_user}

  #--- observers
  after_save :update_addressable_geo_location
  
  def update_addressable_geo_location
    if self.addressable && self.addressable.respond_to?(:geo_location_changed?) && self.addressable.geo_location_changed?
      self.addressable.save(false) unless self.addressable.new_record?
    end
  end

  #--- class methods
  class << self

    # created new personal address
    def new_personal(attributes = {})
      defaults = { :kind => 'personal' } 
      attributes = attributes.merge(defaults).symbolize_keys    # defaults override attributes
      Address.new( attributes )
    end

    # creates new business address
    def new_business(attributes = {})
      defaults = { :kind => 'business' }
      attributes = attributes.merge(defaults).symbolize_keys    # defaults override attributes
      Address.new( attributes )
    end

    # creates new billing address
    def new_billing(attributes = {})
      defaults = { :kind => 'billing' } 
      attributes = attributes.merge(defaults).symbolize_keys    # defaults override attributes
      Address.new( attributes )
    end

    # returns the city province postal format of the current locale country or from
    # the given country code.
    # 
    # e.g.
    #
    #   city_postal_and_province_format -> "%c, %s %z"  # city, state and zip
    #   city_postal_and_province_format("DE") -> "%z %c"
    #
    def city_postal_and_province_format(country_code=nil)
      country_code ||= I18n.locale_country
      country_code ? I18n.t("address.#{country_code.to_s.upcase}.city.format") : "%c, %s %z"
    end

  end

  #--- instance methods
  
  # override Address
  # returns either the full country name or the country code (e.g. DE)
  def country_or_country_code
    if self.country.blank?
      self.country_code ? I18n.t(self.country_code, :scope => "countries") : ''
    else
      self.country
    end
  end
  
  def validate
    if self.kind == :billing && self.addressable && self.addressable.is_a?(Person)
      self.errors.add(:first_name, I18n.t('activerecord.errors.messages.empty')) if self.first_name.blank?
      self.errors.add(:last_name, I18n.t('activerecord.errors.messages.empty')) if self.last_name.blank?
    end
  end

  # returns either the academic title or the gender salutation
  #
  # e.g.
  #
  # Mr
  # Prof Dr.
  #
  def salutation(options={})
    return self.academic_title.name if self.academic_title
    return "Mr".t if self.gender == 'm' 
    return "Ms".t if self.gender == 'f' 
  end
  alias_method :salutation_t, :salutation

  # Returns the salutation and name
  #
  # e.g.
  #
  # "Prof. Dr. Thomas Mann" or "Mr Adam Smith"
  #
  def salutation_and_name
    result = []
    result << self.salutation
    result << self.name
    result.compact.join(" ")
  end

  # Depending on the country code, prints the city 
  # in the locale determined format
  #
  # e.g.
  # 
  #   San Francisco, CA, 94112
  #   80469 München
  #
  def city_postal_and_province(options={})
    options = {:country_code => self.country_code || 'US'}.merge(options).symbolize_keys

    if self.city && (self.province_code || self.province) && self.postal_code
      format = self.class.city_postal_and_province_format(options[:country_code]) || "%c, %s %z"
      format = format.sub('%c', self.city || '')
      format = format.sub('%s', self.province_code || self.province || '')
      format = format.sub('%z', self.postal_code || '')
    end
    format
  end

  # Writes the address as comma delimited string
  def to_s
    result = []
    result << self.name if [:billing, :origin].include?(self.kind)
    result << self.address_line_1
    result << self.address_line_2
    result << self.city
    result << self.province_or_province_code
    result << self.postal_code
    result << self.country_or_country_code
    result.compact.map {|m| m.to_s.strip }.reject {|i| i.empty? }.join(", ")
  end
  
end
