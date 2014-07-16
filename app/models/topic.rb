# Topic is superclass of a Product, Service, Meeting, Vehicle, etc., which represent
# a context for kases
require 'digest/sha2'
class Topic < ActiveRecord::Base
  include QueryBase
  include ActionView::Helpers::TextHelper
  
  #--- constants
  MAXIMUM_IMAGE_SIZE = 256
  BANNED_SITE_NAMES  = %w(faq about terms terms-of-service privacy-policy guidelines)
  
  #--- accessors
  attr_accessor :kind
  # prevents a user from submitting a crafted form that bypasses activation
  attr_protected :status, :kind, :type

  #--- associations
  belongs_to :tier
  belongs_to :created_by, :class_name => 'Person', :foreign_key => :created_by_id
  has_many :kontexts
  has_many :kases,
    :through => :kontexts,
    :source => :kase,
    :foreign_key => :kase_id,
    :class_name => 'Kase',
    :group => "kases.id",
    :conditions => Kase.find_options_for_visible[:conditions]
  has_many :most_recent_kases,
    :limit => 5,
    :through => :kontexts,
    :source => :kase,
    :foreign_key => :kase_id,
    :class_name => 'Kase',
    :group => "kases.id",
    :conditions => Kase.find_options_for_visible[:conditions],
    :order => "kases.created_at DESC, kases.title ASC"
  has_many :popular_kases,
    :through => :kontexts,
    :source => :kase,
    :foreign_key => :kase_id,
    :class_name => 'Kase',
    :group => "kases.id",
    :conditions => Kase.find_options_for_popular(Kase.find_options_for_visible)[:conditions],
    :order => Kase.find_options_for_popular[:order]
  has_many :people,
    :class_name => 'Person',
    :finder_sql => 'SELECT DISTINCT people.* FROM people ' + 
      'INNER JOIN kases ON people.id = kases.person_id ' +
      'INNER JOIN kontexts ON kases.id = kontexts.kase_id ' +
      'WHERE kontexts.topic_id = #{id} AND people.status NOT IN (\'created\') ' +
      ' AND kases.status NOT IN (\'created\', \'suspended\', \'deleted\') ' +
      'GROUP BY people.id',
    :counter_sql => 'SELECT COUNT(DISTINCT people.id) FROM people ' + 
      'INNER JOIN kases ON people.id = kases.person_id ' +
      'INNER JOIN kontexts ON kases.id = kontexts.kase_id ' +
      'WHERE kontexts.topic_id = #{id} AND people.status NOT IN (\'created\') ' +
      ' AND kases.status NOT IN (\'created\', \'suspended\', \'deleted\') ' +
      'GROUP BY people.id'
  
  #--- mixins
  self.keep_translations_in_model = true
  translates :name, :description, :base_as_default => true
  acts_as_taggable
  has_friendly_id :name, 
    :use_slug => true, 
    :cache_column => :permalink, 
    :scope => :tier,
    :approximate_ascii => true
  has_attached_file :image, 
    :storage => %w(development test).include?(RAILS_ENV) ? :filesystem : :s3,
    :s3_credentials => "#{RAILS_ROOT}/config/amazon_s3.yml",
    :s3_permissions => 'public-read',
    :s3_headers => {'Expires' => 1.year.from_now.httpdate},
    :bucket => "#{SERVICE_DOMAIN}-#{RAILS_ENV}",
    :styles => {:thumb => "35x35#", :profile => "113x113#"},
    :url => "/images/application/topics/:attachment/:id/:style_:basename.:extension",
    :path => "#{%w(development test).include?(RAILS_ENV) ? "#{RAILS_ROOT}/public/" : '' }images/application/topics/:attachment/:id/:style_:basename.:extension"
              
  #--- validations
  validates_presence_of :name
  validates_size_of :name, :within => 3..45
  validates_uniqueness_of :name, :case_sensitive => false, :scope => [:tier_id, :language_code, :country_code]
  validates_format_of :site_url, 
    :with => /^((https?):\/\/)?[a-z0-9]+([\-\.]{1}[a-z0-9]+)*\.[a-z]{2,5}(([0-9]{1,5})?\/.*)?$/ix,
    :allow_nil => true
  validates_size_of :description, :maximum => 1000, :allow_nil => true, :allow_blank => true
  validates_attachment_size :image, :in => 1..MAXIMUM_IMAGE_SIZE.kilobyte,
    :message => I18n.t('activerecord.errors.messages.image_size') % {:size => "#{MAXIMUM_IMAGE_SIZE}KB"}
  validates_attachment_content_type :image, :content_type => Utility.image_content_types,
    :message => I18n.t('activerecord.errors.messages.image_types') % {
      :extensions => Utility::VALID_IMAGE_FILE_EXTENSIONS.map(&:upcase).to_sentence.chop_period
    }

  #--- has finder
  named_scope :active, :conditions => ["topics.status = ? AND topics.internal = ?", 'active', false]
  named_scope :region, lambda {|country_code| {
    :order => "topics.country_code = '#{country_code}'"
  }}
  named_scope :current_region, :order => "topics.country_code = '#{Utility.country_code}'"
  named_scope :most_popular, :order => "topics.kases_count DESC, topics.people_count DESC"
  named_scope :language, lambda {|language_code| {
    :conditions => ["topics.language_code = ? OR topics.language_code IS NULL", language_code]
  }}
  named_scope :current_locale_first, :order => "topics.country_code = '#{Utility.country_code}', " +
    "topics.language_code = '#{Utility.language_code}'"
  named_scope :current_language_first, :order => "topics.language_code = '#{Utility.language_code}'"
  named_scope :current_country_first, :order => "topics.country_code = '#{Utility.country_code}'"

  #--- state machine
  acts_as_state_machine :initial => :passive, :column => :status
  state :passive
  state :pending, :enter => :make_activation_code
  state :active,  :enter => :do_activate, :after => :after_activate
  state :suspended, :after => :after_suspended
  state :deleted, :enter => :do_delete, :after => :after_delete

  event :register do
    transitions :from => :passive, :to => :pending
  end
  
  event :activate do
    transitions :from => :pending, :to => :active 
  end
  
  event :suspend do
    transitions :from => [:passive, :pending, :active], :to => :suspended
  end
  
  event :delete do
    transitions :from => [:passive, :pending, :active, :suspended], :to => :deleted
  end

  event :unsuspend do
    transitions :from => :suspended, :to => :active,  :guard => Proc.new {|u| !u.activated_at.blank?}
    transitions :from => :suspended, :to => :pending, :guard => Proc.new {|u| u.activated_at.blank?}
    transitions :from => :suspended, :to => :passive
  end

  #--- callbacks
  after_create :update_topic_tiers_count
  before_validation_on_create :generate_uuid

  #--- class methods
  class << self
    
    def kind
      :topic
    end
    
    # returns an array of subclasses as kind
    def subkinds
      subclasses.map(&:kind)
    end

    def self_and_subkinds
      subkinds.insert(0, kind)
    end
    
    # returns all subclasses including self
    def self_and_subclasses
      subclasses.insert(0, self)
    end
    
    # returns all param_ids as array
    #
    # e.g.
    #
    #   [:company_id, :agency_id]
    #
    def subclass_param_ids
      subclasses.map {|k| "#{k.name.downcase}_id"}.map(&:to_sym)
    end
    
    # returns self and subclass param_ids
    def self_and_subclass_param_ids
      subclass_param_ids.insert(0, self_param_id)
    end
    
    # returns the param id
    def self_param_id
      "#{name.downcase}_id".to_sym
    end
    
    # infers the controller name from class name
    def controller_name
      self.name.underscore.pluralize
    end
    
    # type casts to the class specified in :type parameter
    #
    # E.g.
    #
    #   d = Topic.new(:type => :product)
    #   d.kind == :product  # -> true
    #
    def new_with_cast(*a, &b)  
      if (h = a.first).is_a? Hash and (type = h[:type] || h['type']) and 
        (k = type.class == Class ? type : (type.class == Symbol ? klass(type): type.constantize)) != self
        raise "type not descendent of Topic" unless k < self  # klass should be a descendant of us  
        return k.new(*a, &b)  
      end  
      new_without_cast(*a, &b)  
    end  
    alias_method_chain :new, :cast

    # returns class by kind, e.g. :company returns Company
    def klass(a_kind=nil)
      [Product, Service].each do |subclass|
        return subclass if subclass.kind == a_kind
      end
      Topic
    end

    # finds instance that matches attributes or creates an instance
    def find_or_build(attributes={})
      unless object = find(:first, :conditions => attributes)
        object = new(attributes)
      end
      object
    end

    # find options to include self and sub types
    def find_options_for_type(options={})
      {:conditions => ["topics.type IN (?)", self_and_subclasses.map(&:name)]}.merge_finder_options(options)
    end

    # returns the first instance by permalink, country code and active
    def find_by_permalink_and_region_and_active(permalink, country_code=Utility.country_code, active=true, options={})
      options = find_options_for_permalink_and_region_and_active(permalink, country_code, active, options)
      records = find(:all, options.merge(:limit => 2))
      if records.empty?
        raise ActiveRecord::RecordNotFound, "Couldn't find #{name} with ID=#{permalink}"
      else
        record = records[0]
        if record && record.slug && record.slug.name =~ Regexp.new(permalink, Regexp::IGNORECASE)
          record.friendly_id_status.slug = record.slug
        end
      end
      record
    end
    
    # find options for find by permalink
    def find_options_for_permalink_and_region_and_active(permalink, country_code=Utility.country_code, active=true, options={})
      conditions = [active ? 
        "slugs.name = ? AND (topics.country_code = ? OR topics.country_code IS NULL) AND topics.status = ?" :
          "slugs.name = ? AND (topics.country_code = ? OR topics.country_code IS NULL) AND topics.status != ?",
            permalink, country_code, 'active']
      # make sure that country code comes first, if given
      order = "#{sanitize_and_merge_conditions(["topics.country_code IS NULL DESC, topics.country_code IN (?) DESC", 
        [country_code]])}"
      {:conditions => conditions, :include => :slugs, :order => order}.merge_finder_options(options)
    end
    
    # find options for region
    def find_options_for_region_and_active(country_code=Utility.country_code, active=true, options={})
      conditions = if active == true
        ["(topics.country_code = ? OR topics.country_code IS NULL) AND topics.status = ?", country_code, 'active']
      elsif active == false
        ["(topics.country_code = ? OR topics.country_code IS NULL) AND topics.status != ?", country_code, 'active']
      else
        ["(topics.country_code = ? OR topics.country_code IS NULL)", country_code]
      end
      {:conditions => conditions}.merge_finder_options(options)
    end
    
    # overrides default finder and makes sure only active organizations
    def find_by_permalink(permalink, options={})
      unless result = find(:first, find_options_for_find_by_permalink(permalink, options))
        raise ActiveRecord::RecordNotFound, "Couldn't find #{name} with ID=#{permalink}"
      end
      result.friendly_id_status.name = permalink if result
      result
    end
    
    # find options for permalink
    def find_options_for_find_by_permalink(permalink, options={})
      {:conditions => ["topics.permalink = ? AND topics.status IN (?)", permalink, ['active']]}.merge_finder_options(options)
    end
    
    # finds all featured
    def find_featured(country_code=nil, options={})
      find(:all, find_options_for_featured(country_code, options))
    end

    # find options for finding features kases
    def find_options_for_featured(country_code=nil, options={})
      find_options_for_region_and_active(country_code, true, {:conditions => ["topics.featured = ?", true]})
    end

    def kases_count_column?
      columns.to_a.map {|a| a.name.to_sym}.include?(:kases_count)
    end
    
    def people_count_column?
      columns.to_a.map {|a| a.name.to_sym}.include?(:people_count)
    end
    
    # overrides query columns from query base
    def find_by_query_columns
      ['name', 'description']
    end
    
    # overrides additional query find options from query base
    def find_class_options_for_query_with_and(query, options={})
      find_options_for_region_and_active(Utility.country_code, true, options)
    end
    
    # find all visible
    def find_all_visible(options={})
      find(:all, find_options_for_visible(options))
    end
    
    # find options for visible
    def find_options_for_visible(options={})
      {:conditions => ["topics.status NOT IN (?)", ['passive', 'pending', 'suspended', 'deleted']]}.merge_finder_options(options)
    end
    
  end

  #--- instance methods

  # reminder for db attribute
  # returns the default locale country code if the record is new
  # and no language is code is assigned
  def language_code
    return self[:language_code].downcase if self[:language_code]
  end

  # forces upcase and turns empty strings to nil values
  def language_code=(a_language_code)
    self[:language_code] = a_language_code ? a_language_code.strip.downcase : a_language_code
  end
  
  # returns a locale code, e.g. de-DE for German - Germany
  def locale
    "#{self.language_code}-#{self.country_code}"
  end
  
  # returns true if we can provide a locale made from country and language
  def locale?
    !!self.language_code && !!self.country_code
  end
  
  # reminder for db attribute
  def country_code
    self[:country_code].upcase if self[:country_code]
  end

  # forces upcase and turns empty strings to nil values
  def country_code=(a_country_code)
    self[:country_code] = a_country_code ? a_country_code.strip.upcase : a_country_code
  end

  # returns a string representation for class/instance type
  # kind setter is generated and used on new action
  def kind
    @kind || :topic
  end

  # returns kases count either from counter field or through query
  def kases_count
    if self.class.kases_count_column?
      self[:kases_count]
    else
      self.kases.count
    end
  end

  # updates kases count counter
  def update_kases_count
    if self.class.kases_count_column?
      self.update_attribute(:kases_count, 
        self[:kases_count] = self.kases.count("kases.id", Kase.find_options_for_visible({:distinct => true})))
      self[:kases_count]
    end
  end
  
  # returns people count
  def people_count
    if self.class.people_count_column?
      self[:people_count]
    else
      self.people.count  # counter_sql in has_many takes care
    end
  end

  # updates people count counter
  def update_people_count
    if self.class.people_count_column?
      self.update_attribute(:people_count, 
        self[:people_count] = self.people.count)
      self[:people_count]
    end
  end

  # intercept globalized name to return any localized column content as default
  #
  # e.g. 
  #
  # on locale "en-US" with self[:name_es] == "Argentina" and self[:name] = nil, we return
  #  "Argentina"
  #
  def name_with_any_as_default
    name_without_any_as_default || self.class.localized_facets_without_base(:name).map {|m| send(m)}.compact.first
  end
  alias_method_chain :name, :any_as_default
  
  # discription, otherwise as dito
  def description_with_any_as_default
    description_without_any_as_default || self.class.localized_facets_without_base(:description).map {|m| send(m)}.compact.first
  end
  alias_method_chain :description, :any_as_default
  
  # used for attachment column
  def generate_uuid 
    self[:uuid] ||= Utility.generate_random_uuid
  end

  # use first 10 uuid digits to encode attachment id
  def attachment_uuid
    self.uuid.gsub(/-/, '')[0..9] if self.uuid
  end
  
  # determines the language code for associated tags
  # intercepts from acts_as_taggable_type
  def tag_language_code_with_content
    self.language_code || self.tag_language_code_without_content 
  end
  alias_method_chain :tag_language_code, :content
  
  protected
  
  def make_activation_code
    self.deleted_at = nil
    self.activation_code = Digest::SHA1.hexdigest( Time.now.to_s.split(//).sort_by {rand}.join )
  end
  
  def do_delete
    self.deleted_at = Time.now.utc
  end

  def after_delete
    self.update_topic_tiers_count
  end

  def do_activate
    @activated = true
    self.activated_at = Time.now.utc
    self.deleted_at = self.activation_code = nil
  end
  
  def after_activate
    self.update_topic_tiers_count
  end

  def after_suspended
    self.update_topic_tiers_count
  end

  # update kase_count in tier association. we only count "visible" kases
  def update_topic_tiers_count
    if self.tier && self.tier.class.columns.to_a.map {|a| a.name.to_sym}.include?(:topics_count)
      self.tier.class.transaction do 
        self.tier.lock!
        self.tier.update_attribute(:topics_count, 
          self.tier.topics.count("topics.id", self.class.find_options_for_region_and_active(self.country_code, true, {:distinct => true})))
      end
    end
  end

  # Custom validation
  def validate
    #--- banned sites
    site_name = normalize_friendly_id(FriendlyId::SlugString.new(self.name))
    errors.add(:name, I18n.t('activerecord.errors.messages.exclusion')) if 
      BANNED_SITE_NAMES.include?(site_name) || (site_name =~ /^www|^-|^_/)
  end

  # make sure we normalize slug correctly
  def normalize_friendly_id(slug_string)
    return super if self.language_code ? self.language_code == "en" : I18n.locale_language == :en
    options = friendly_id_config.babosa_options
    language = Utility.english_language_name(self.language_code || I18n.locale_language) || :english
    slug_string.normalize! options.merge(:transliterations => "#{language}".underscore.to_sym)
  end

end
