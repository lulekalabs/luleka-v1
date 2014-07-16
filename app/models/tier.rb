# Tier is the super class of Organization (Company, Agency), Group, etc.
# Tiers can have memberships with people. Each tier can have one or more
# topic (e.g. products, services, meetings, etc.)
require 'digest/sha2'
class Tier < ActiveRecord::Base
  include QueryBase
  
  #--- constants
  MAXIMUM_IMAGE_SIZE_IN_KB = 256
  ALL_ID             = "all"
  BANNED_SITE_NAMES  = %w(all new create edit delete destroy show preview page pages complete
    search searches tag tags api apis
    profile profiles person people category categories
    tier tiers communities community organizations organization tier tiers group groups company companies
    topic topics product products service services event events meeting meetings
    www blog lecture lectures vehicle vehicles location locations
    kases kase case cases question questions problem problems praise praises idea ideas
    account accounts admin admins home homes me my mine
    contact contacts invitation invitations claim claims help share faq privacy-policy
    terms-of-service tos about job jobs blog blogs copyright voucher vouchers
    why what how fuck sex dick)
    
  #--- accessors
  attr_accessor :kind
  attr_accessor :owner
  attr_accessor :pre_approved_emails
  
  # prevents a user from submitting a crafted form that bypasses activation
  attr_protected :status, :type
  
  #--- associations
  belongs_to :created_by, :class_name => 'Person', :foreign_key => :created_by_id
  belongs_to :category, :class_name => 'TierCategory', :foreign_key => :tier_category_id
  has_one :piggy_bank, :as => :owner,
    :class_name => 'PiggyBankAccount',
    :dependent => :destroy
  has_many :memberships, :dependent => :destroy
  has_many :members,
    :through => :memberships,
    :class_name => 'Person',
    :source => :member,
    :conditions => "memberships.status IN ('active', 'moderator', 'admin')"
  has_many :admins,
    :through => :memberships,
    :class_name => 'Person',
    :source => :member,
    :conditions => "memberships.status = 'admin'"
  has_many :moderators,
    :through => :memberships,
    :class_name => 'Person',
    :source => :member,
    :conditions => "memberships.status = 'moderator'"
  has_many :partners,
    :through => :memberships,
    :class_name => 'Person',
    :source => :member,
    :conditions => "people.status IN ('partner')"
  has_many :topics, :dependent => :destroy,
    :order => "topics.name ASC"
  has_many :select_topics,
    :class_name => "Topic",
    :conditions => ["topics.status IN (?) AND topics.internal = ?", ['active'], false],
    :limit => 16,
    :order => "topics.country_code = '#{Utility.country_code}', " +
      "topics.language_code = '#{Utility.language_code}', " +
      "topics.kases_count DESC, topics.people_count DESC" 
  has_many :recent_topics,
    :class_name => 'Topic',
    :limit => 5,
    :order => "topics.activated_at DESC",
    :conditions => ["topics.status IN (?) AND topics.internal = ?", ['active'], false]
  has_many :popular_topics,
    :class_name => 'Topic',
    :order => "COUNT(kases.id) DESC",
    :limit => 5,
    :finder_sql => 'SELECT DISTINCT topics.* FROM topics ' + 
      'INNER JOIN kontexts ON kontexts.topic_id = topics.id ' +
      'INNER JOIN kases ON kases.id = kontexts.kase_id ' +
      'WHERE kontexts.tier_id = #{id} AND ' +
        'topics.status IN (\'active\') AND topics.internal = 0'
  has_many :kontexts # :dependent => :destroy is called through destroy_all_kases_and_kontexts
  has_many :all_kases,
    :through => :kontexts,
    :source => :kase,
    :foreign_key => :kase_id,
    :class_name => 'Kase',
    :group => "kases.id"
  has_many :kases,
    :through => :kontexts,
    :source => :kase,
    :foreign_key => :kase_id,
    :class_name => 'Kase',
    :group => "kases.id",
    :conditions => Kase.find_options_for_visible[:conditions]
  has_many :popular_kases,
    :through => :kontexts,
    :source => :kase,
    :foreign_key => :kase_id,
    :class_name => 'Kase',
    :group => "kases.id",
    :conditions => Kase.find_options_for_popular(Kase.find_options_for_visible)[:conditions],
    :order => Kase.find_options_for_popular[:order]
  has_many :recent_kases,
    :through => :kontexts,
    :source => :kase,
    :foreign_key => :kase_id,
    :class_name => 'Kase',
    :group => "kases.id",
    :conditions => Kase.find_options_for_visible[:conditions],
    :order => "kases.created_at DESC, kases.title ASC"
  has_many :most_recent_kases,
    :limit => 5,
    :through => :kontexts,
    :source => :kase,
    :foreign_key => :kase_id,
    :class_name => 'Kase',
    :group => "kases.id",
    :conditions => Kase.find_options_for_visible[:conditions],
    :order => "kases.created_at DESC, kases.title ASC"
  has_many :people,
    :class_name => 'Person',
    :finder_sql => 'SELECT DISTINCT people.* FROM people ' + 
      'INNER JOIN kases ON people.id = kases.person_id ' +
      'INNER JOIN kontexts ON kases.id = kontexts.kase_id ' +
      'WHERE kontexts.tier_id = #{id} AND people.status NOT IN (\'created\') ' + 
      ' AND kases.status NOT IN (\'created\', \'suspended\', \'deleted\') ' +
      'GROUP BY people.id',
    :counter_sql => 'SELECT COUNT(DISTINCT people.id) FROM people ' + 
      'INNER JOIN kases ON people.id = kases.person_id ' +
      'INNER JOIN kontexts ON kases.id = kontexts.kase_id ' +
      'WHERE kontexts.tier_id = #{id} AND people.status NOT IN (\'created\') ' + 
      ' AND kases.status NOT IN (\'created\', \'suspended\', \'deleted\') ' +
      'GROUP BY people.id'  
  has_many :bonus_rewards
  has_many :reputation_rewards
  has_many :reputation_thresholds
      
  #--- mixins
  self.keep_translations_in_model = true
  translates :name, :description, :summary, :base_as_default => true
  has_attached_file :image, 
    :storage => %w(development test).include?(RAILS_ENV) ? :filesystem : :s3,
    :s3_credentials => "#{RAILS_ROOT}/config/amazon_s3.yml",
    :s3_permissions => 'public-read',
    :s3_headers => {'Expires' => 1.year.from_now.httpdate},
    :bucket => "#{SERVICE_DOMAIN}-#{RAILS_ENV}",
    :styles => {:thumb => "35x35#", :profile => "113x113#", :invoice => "200x100>"},
    :url => "/images/application/tiers/:attachment/:id/:style_:basename.:extension",
    :path => "#{%w(development test).include?(RAILS_ENV) ? "#{RAILS_ROOT}/public/" : '' }images/application/tiers/:attachment/:id/:style_:basename.:extension"
  has_attached_file :logo, 
    :storage => %w(development test).include?(RAILS_ENV) ? :filesystem : :s3,
    :s3_credentials => "#{RAILS_ROOT}/config/amazon_s3.yml",
    :s3_permissions => 'public-read',
    :s3_headers => {'Expires' => 1.year.from_now.httpdate},
    :bucket => "#{SERVICE_DOMAIN}-#{RAILS_ENV}",
    :styles => {:normal => "300x66"},
    :url => "/images/application/tiers/:attachment/:id/:style_:basename.:extension",
    :path => "#{%w(development test).include?(RAILS_ENV) ? "#{RAILS_ROOT}/public/" : '' }images/application/tiers/:attachment/:id/:style_:basename.:extension"
  
  acts_as_tree :order => 'name'
  acts_as_addressable :has_one => true
  acts_as_taggable
  acts_as_mappable :default_units => :kms
  has_friendly_id :site_name, 
    :use_slug => true,
    :cache_column => :permalink,
    :scope => :country_code, 
    :approximate_ascii => true
  acts_as_seller
  
  #--- valdations
  validates_presence_of :name
  validates_size_of :name, :within => 3..45
  validates_presence_of :site_name
  validates_presence_of :category
  validates_format_of :site_name, :with => /^[a-zA-Z0-9-]+$/
  validates_uniqueness_of :site_name, :allow_nil => false, :scope => :country_code, :case_sensitive => false
  validates_size_of :site_name, :within => 3..35
  validates_format_of :site_url, 
    :with => /^((https?):\/\/)?[a-z0-9]+([\-\.]{1}[a-z0-9]+)*\.[a-z]{2,5}(([0-9]{1,5})?\/.*)?$/ix, 
    :allow_nil => true                      
  validates_size_of :description, :maximum => 1000, :allow_nil => true, :allow_blank => true
  validates_size_of :summary, :maximum => 250, :allow_nil => true, :allow_blank => true
  validates_attachment_size :image, :in => 1..MAXIMUM_IMAGE_SIZE_IN_KB.kilobyte,
    :message => I18n.t('activerecord.errors.messages.image_size') % {:size => "#{MAXIMUM_IMAGE_SIZE_IN_KB}KB"}
  validates_attachment_content_type :image, :content_type => Utility.image_content_types,
    :message => I18n.t('activerecord.errors.messages.image_types') % {
      :extensions => Utility::VALID_IMAGE_FILE_EXTENSIONS.map(&:upcase).to_sentence.chop_period
    }
  validates_acceptance_of :terms_of_service
  validates_email_format_of :owner_email, :on => :create
    
  #--- has finder
  named_scope :active, :conditions => ["tiers.status in (?)", ['active']]
  named_scope :current_region, :conditions => ["((tiers.country_code = ? AND tiers.parent_id IS NULL) " + 
    "OR tiers.country_code IS NULL)", Utility.country_code]
  named_scope :region, lambda {|country_code| {
    :conditions => ["(tiers.country_code = ? AND tiers.parent_id IS NULL) OR tiers.country_code IS NULL", country_code] }
  }
  
  named_scope :current_locale_first, :order => "tiers.country_code = '#{Utility.country_code}', " +
    "tiers.language_code = '#{Utility.language_code}'"
  named_scope :current_language_first, :order => "tiers.language_code = '#{Utility.language_code}'"
  named_scope :current_country_first, :order => "tiers.country_code = '#{Utility.country_code}'"
  named_scope :most_popular, :order => "tiers.kases_count DESC, tiers.topics_count DESC, " +
    "tiers.people_count DESC, tiers.members_count DESC"
  
  def self.most_active(options={})
    Organization.active({:limit => 5, :include => :kases, :order => "COUNT(kases) DESC"}.merge(options))
  end
  
  #--- state machine
  acts_as_state_machine :initial => :passive, :column => :status
  state :passive
  state :pending, :enter => :make_activation_code
  state :active,  :enter => :do_activate
  state :suspended
  state :deleted, :enter => :do_delete

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
  before_create :create_piggy_bank
  before_save :save_subsidiaries, :geocode_addresses
  before_destroy :destroy_all_kases_and_kontexts
  before_validation_on_create :generate_uuid
  
  def after_initialize
    self.modified! if self.new_record?
  end

  def geocode_addresses
    self.before_save_address(self.address)
  end
  
  # geocode address in case it is a personal or business address
  # assigns person's location to either personal or business address
  def before_save_address(address)
    return unless address
    if !self.geo_coded? || address.changed?
      res = GeoKit::Geocoders::MultiGeocoder.geocode(address.to_s)
      if res.success
        self.lat = address.lat = res.lat
        self.lng = address.lng = res.lng
      end
    end
  rescue GeoKit::Geocoders::GeocodeError => ex
    logger.error "Exception #{ex.message} caught when geocoding #{address.to_s}"
    return
  end

  #--- class methods
  class << self
    
    def finder_name
      :find_by_permalink
    end
    
    def finder_options
      {}
    end

    def kind
      :tier
    end
    
    # returns an array of subclasses as kind
    def subkinds
      subclasses.map(&:kind)
    end
    
    def self_and_subkinds
      subkinds.insert(0, kind)
    end

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
    
    # returns the class for this tier's topic
    # override in subclass, e.g. Organization -> Product
    def topic_class
      Topic
    end
    
    # returns the type/kind for the related topic
    def topic_kind
      topic_class.kind
    end
    alias_method :topic_type, :topic_kind
    
    # used when we need to know what a single topic is called
    # override in subclass
    # 
    #   Company.topic_s  ->  'product'
    #   Group.topic_s  ->  'topic'
    #
    def topic_s
      "#{topic_kind}"
    end

    # translated version of topic_s
    def topic_t
      topic_s.t
    end

    # pluralized version of topic_s
    def topics_s
      topic_s.pluralize
    end
    
    # translated and pluralized version to topic_s
    def topics_t
      topics_s.t
    end
    
    # returns associated membership class
    def membership_class
      Membership
    end
    
    # returns symbol for type of member, e.g. :employee in Organization
    def membership_kind
      membership_class.kind
    end
    
    # string rep. of member kind
    def member_s
      membership_class.member_s
    end

    # translated member name
    def member_t
      membership_class.member_t
    end
    
    # string rep. of member kind
    def members_s
      membership_class.members_s
    end

    # translated member name
    def members_t
      membership_class.members_t
    end
    
    # infers the controller name from class name
    def controller_name
      self.name.underscore.pluralize
    end
    
    # type casts to the class specified in :type parameter
    #
    # E.g.
    #
    #   d = Tier.new(:type => :organization)
    #   d.kind == :organization  # -> true
    #
    def new_with_cast(*a, &b)  
      if (h = a.first).is_a? Hash and (type = h[:type] || h['type']) and 
        (k = type.class == Class ? type : (type.class == Symbol ? klass(type): type.constantize)) != self
        raise "type not descendent of Tier" unless k < self  # klass should be a descendant of us  
        return k.new(*a, &b)  
      end  
      new_without_cast(*a, &b)  
    end  
    alias_method_chain :new, :cast

    # returns class by kind, e.g. :company returns Company
    def klass(a_kind=nil)
      [Organization, Group].each do |subclass|
        return subclass if subclass.kind == a_kind
      end
      Tier
    end

    # returns probono headquarters company instance
    def probono
      @probono_company || @probono_company = find_worldwide_or_regional_by_permalink_and_active(
        'luleka', true, :include => :piggy_bank)
    end

    # find options to include self and sub types
    def find_options_for_type(options={})
      {:conditions => ["tiers.type IN (?)", self_and_subclasses.map(&:name)]}.merge_finder_options(options)
    end
    
    # find all visible tiers
    def find_all_visible(options={})
      find(:all, find_options_for_visible(options))
    end
    
    # find options for visible tiers
    def find_options_for_visible(options={})
      {:conditions => ["tiers.status NOT IN (?)", ['passive', 'pending', 'suspended', 'deleted']]}.merge_finder_options(options)
    end

    # returns find options for most popular
    def find_options_for_popular(options={})
      conditions = ["tiers.status = ? AND ((tiers.country_code = ? AND tiers.parent_id IS NULL) OR tiers.country_code IS NULL)", 'active', Utility.country_code]
      conditions = sanitize_and_merge_conditions(conditions, options.delete(:conditions)) if options[:conditions]
      {
        :select => "tiers.*, COUNT(kases.id) AS kases_count",
        :group => "tiers.id HAVING kases_count >= 0",
        :order => "kases_count DESC, tiers.activated_at ASC",
        :conditions => conditions,
        :joins => "LEFT OUTER JOIN kontexts ON (tiers.id = kontexts.tier_id) " +
          "LEFT OUTER JOIN kases ON (kases.id = kontexts.kase_id)" + 
          "LEFT OUTER JOIN topics ON (topics.id = kontexts.topic_id)"
      }.merge_finder_options(options)
    end
    
    # find options to get all tiers ordered by topics count
    def find_options_for_popular_ordered_by_topics(options={})
      conditions = sanitize_sql(["tiers.status = ? AND ((tiers.country_code = ? AND tiers.parent_id IS NULL) OR tiers.country_code IS NULL)", 'active', Utility.country_code])
      {
        :conditions => conditions,
        :select => "tiers.*, COUNT(tier_topics.id) AS topics_count, COUNT(kase_topics.id) AS kases_count",
        :group => "tiers.id",
        :order => "topics_count DESC, kases_count DESC",
        :joins => "LEFT OUTER JOIN kontexts ON (tiers.id = kontexts.tier_id) " +
          "LEFT OUTER JOIN kases AS kases ON (kases.id = kontexts.kase_id)" + 
          "LEFT OUTER JOIN topics AS kase_topics ON (kase_topics.id = kontexts.topic_id) " +
          "LEFT OUTER JOIN topics AS tier_topics ON (tier_topics.tier_id = tiers.id) "
      }.merge_finder_options(options)
    end
    
    # used for status navigation
    def find_all_popular_orderd_by_topics(options={})
      find(:all, find_options_for_popular_ordered_by_topics(options))
    end

    # finds 5 top most popular
    def popular(options={})
      find(:all, find_options_for_popular({:limit => 5}.merge_finder_options(options)))
    end

    # finds all popular
    def find_all_popular(options={})
      find(:all, find_options_for_popular(options))
    end
    
    # returns the 5 (default) most recently added organizations
    def find_options_for_recent(options={})
      conditions = ["tiers.status = ? AND (tiers.country_code = ? OR tiers.country_code IS NULL)", 'active', Utility.country_code]
      conditions = sanitize_and_merge_conditions(conditions, options.delete(:conditions)) if options[:conditions]
      {
        :order => "tiers.activated_at DESC",
        :conditions => conditions
      }.merge_finder_options(options)
    end

    # returns the 5 (default) most recently added organizations
    def recent(options={})
      find(:all, find_options_for_recent({:limit => 5}.merge_finder_options(options)))
    end

    # find all most recently added tiers
    def find_all_recent(options={})
      find(:all, find_options_for_recent(options))
    end
    
    # attempts to fetch the worldwide instance of tier by permalink for active = true, false or nil don't care
    # if not the country specific one
    #
    # e.g.
    #
    #  luleka WW (nil), luleka DE (nil), luleka US (us) ->  WW, US with couuntry code 'US' and returns WW
    #  luleka DE (nil), luleka US (us) ->  US with couuntry code 'US' and returns WW
    #
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
    
    # builds options hash for finder
    def find_options_for_permalink_and_region_and_active(permalink, country_code=nil, active=true, options={})
      conditions = if active.nil?
        ["slugs.name = ?", permalink]
      elsif active == true
        ["slugs.name = ? AND tiers.status = ?", permalink, 'active']
      else
        ["slugs.name = ? AND tiers.status != ?", permalink, 'active']
      end
      # make sure that country code comes first, if given
      order = "#{sanitize_and_merge_conditions(["tiers.country_code IS NULL DESC, tiers.country_code IN (?) DESC", 
        [country_code]])}"
      {:conditions => conditions, :include => :slugs, :order => order}.merge_finder_options(options)
    end
    
    # overrides default finder and makes sure only active organizations
    def find_by_permalink(permalink, options={})
      unless result = find(:first, find_options_for_find_by_permalink(permalink, options))
        raise ActiveRecord::RecordNotFound, "Couldn't find #{name} with ID=#{permalink}"
      end
      result.friendly_id_status.name = permalink if result
      result
    end

    # find options for permlink
    def find_options_for_find_by_permalink(permalink, options={})
      {
        :conditions => ["tiers.permalink = ? AND tiers.status NOT IN (?)", permalink, ['new', 'created']]
      }.merge_finder_options(options)
    end
    
    # returns the first instance of the organization by permalink if active
    def find_all_like_by_permalink_and_region_and_active(permalink, country_code=Utility.country_code, active=true, options={})
      query = if active
        "tiers.permalink LIKE ? AND ((tiers.country_code = ? AND tiers.parent_id IS NULL) " + 
          "OR tiers.country_code IS NULL) AND tiers.status = ?"
      else
        "tiers.permalink LIKE ? AND ((tiers.country_code = ? AND tiers.parent_id IS NULL) " + 
          "OR tiers.country_code IS NULL) AND tiers.status != ?"
      end
      find(:all, {:conditions => [query, permalink, country_code, 'active']}.merge(options))
    end

    # finds all tiers 
    def find_all_by_region_and_active(country_code=Utility.country_code, active=true, options={})
      find(:all, find_options_for_region_and_active(country_code, active, options))
    end
    
    # find all by region and active
    def find_options_for_region_and_active(country_code=Utility.country_code, active=true, options={})
      conditions = if active.nil?
        ["tiers.country_code IS NULL OR (tiers.country_code = ? AND tiers.parent_id IS NULL)", country_code]
      elsif active == true
        ["(tiers.country_code IS NULL OR (tiers.country_code = ? AND tiers.parent_id IS NULL)) AND tiers.status = ?",
           country_code, 'active']
      else
        ["(tiers.country_code IS NULL OR (tiers.country_code = ? AND tiers.parent_id IS NULL)) AND tiers.status != ?",
           country_code, 'active']
      end
      # make sure that country code comes first, if given
      order = "#{sanitize_and_merge_conditions(["tiers.country_code IN (?) DESC", [country_code]])}"
      {:conditions => conditions, :order => order}.merge_finder_options(options)
    end

    def find_options_for_region_order(country_code=Utility.country_code)
      {:order => "tiers.country_code = #{country_code}"}
    end

    # finds organization root by permalink and active
    # returns the parent of the organziation's permalink, if not returns nil, 
    # if there are more than one root organziations, it returns the one with
    # the current country code.
    def find_worldwide_or_regional_by_permalink_and_active(permalink, active=true, options={})
      query = if active
        "tiers.permalink LIKE ? AND tiers.status = ?"
      else
        "tiers.permalink LIKE ? AND tiers.status != ?"
      end
      select = find(:all, {:conditions => [query, permalink, 'active']}.merge(options))
      if select.size > 0
        if roots = select.select {|o| !o.parent}
          if roots.size == 1
            roots.first
          elsif roots.size == 0
            nil
          else
            roots.find {|r| r.country_code == Utility.country_code}
          end
        end
      end
    end

    # finds the worldwide tier by permalink or if not present returns nil
    def find_worldwide_by_permalink_and_active(permalink, active=true, options={})
      conditions = if active.nil?
        ["tiers.permalink = ? AND tiers.country_code IS NULL", permalink]
      elsif active == true
        ["tiers.permalink = ? AND tiers.country_code IS NULL AND tiers.status = ?", permalink, 'active']
      else
        ["tiers.permalink = ? AND tiers.country_code IS NULL AND tiers.status != ?", permalink, 'active']
      end
      find(:first, {:conditions => conditions}.merge(options))
    end

    # finds all featured
    def find_all_featured(options={})
      find(:all, find_options_for_featured_by_country_code(nil, options))
    end

    # finds all featured
    def find_all_featured_by_country_code(country_code, options={})
      find(:all, find_options_for_featured_by_country_code(country_code, options))
    end

    # find options for finding features kases
    def find_options_for_featured_by_country_code(country_code, options={})
      find_options_for_region_and_active(country_code, true,
        {:conditions => ["tiers.featured = ?", true], :order => "tiers.created_at DESC"}.merge_finder_options(options))
    end

    # overrides additional query find options from query base
    def find_class_options_for_query_with_and(query, options={})
      find_options_for_region_and_active(Utility.country_code, true, options)
    end

    # overrides query columns from query base
    def find_by_query_columns
      ['name', 'description', 'tagline']
    end

    def kases_count_column?
      columns.to_a.map {|a| a.name.to_sym}.include?(:kases_count)
    end

    def members_count_column?
      columns.to_a.map {|a| a.name.to_sym}.include?(:members_count)
    end

    def topics_count_column?
      columns.to_a.map {|a| a.name.to_sym}.include?(:topics_count)
    end

    def people_count_column?
      columns.to_a.map {|a| a.name.to_sym}.include?(:people_count)
    end

    def find_all_categories
      TierCategory.find(:all, :conditions => ["tier_categories.super_type = ?", name],
        :order => "tier_categories.#{TierCategory.translated_attribute_name(:name)} ASC")
    end

    # find all tiers, which tier, related topics, related kases contain or are tagged with tags
    def find_deeply_tagged_with(tags, options={})
      tags = [tags].flatten.reject(&:blank?)
      tags.empty? ? [] : find(:all, find_options_for_find_deeply_tagged_with(tags, options))
    end

    def find_options_for_find_deeply_tagged_with(tags, options={})
      tags = [tags].flatten.reject(&:blank?)
      select = "DISTINCT tiers.*"
      conditions = ""
      
      # tier stuff
      conditions += tags.inject([]) {|result, tag|
        result << sanitize_sql_for_assignment(["(tiers.name LIKE ? OR tiers.name_de LIKE ? OR tiers.name_es LIKE ?)", 
          "%#{tag}%", "%#{tag}%", "%#{tag}%"])
      }.join(" OR ")
      
      joins = "LEFT OUTER JOIN taggings tiers_taggings ON tiers_taggings.taggable_id = tiers.id AND tiers_taggings.taggable_type = 'Tier' " + 
        "LEFT OUTER JOIN tags tiers_tags ON tiers_tags.id = tiers_taggings.tag_id "
      conditions += sanitize_sql_for_assignment([" OR tiers_tags.name IN (?)", tags])

      # topic stuff
      joins += "LEFT OUTER JOIN topics ON tiers.id = topics.tier_id "
      conditions += " OR " + tags.inject([]) {|result, tag|
        result << sanitize_sql_for_assignment(["topics.name LIKE ?", "%#{tag}%"])
      }.join(" OR ")
      
      joins += "LEFT OUTER JOIN taggings topics_taggings ON topics_taggings.taggable_id = topics.id AND topics_taggings.taggable_type = 'Topic' " +
        "LEFT OUTER JOIN tags topics_tags ON topics_tags.id = topics_taggings.tag_id "
      conditions += sanitize_sql_for_assignment([" OR topics_tags.name IN (?)", tags])

      # kase stuff
      joins += "LEFT OUTER JOIN kontexts kases_kontexts ON tiers.id = kases_kontexts.tier_id " +
        "LEFT OUTER JOIN kases ON kases.id = kases_kontexts.kase_id "
      joins += "LEFT OUTER JOIN taggings kases_taggings ON kases_taggings.taggable_id = kases.id AND kases_taggings.taggable_type = 'Kase' " + 
        "LEFT OUTER JOIN tags kases_tags ON kases_tags.id = kases_taggings.tag_id "
      conditions += sanitize_sql_for_assignment([" OR kases_tags.name IN (?)", tags])
      conditions += " OR " + tags.inject([]) {|result, tag|
        result << sanitize_sql_for_assignment(["kases.title LIKE ?", "%#{tag}%"])
      }.join(" OR ")
      
      {
        :select => select,
        :joins => joins,
        :conditions => conditions
      }.merge_finder_options(options)
    end

  end
  
  #--- instance methods
  
  # current state string
  def current_state_s
    "#{self.current_state}"
  end

  # translates current state
  def current_state_t
    current_state_s.t
  end
  
  # returns a string representation for class/instance type
  # kind setter is generated and used on new action
  def kind
    @kind || :tier
  end

  # see class method
  def topic_class
    self.class.topic_class
  end

  # see class method
  def topic_kind
    self.class.topic_kind
  end
  alias_method :topic_type, :topic_kind

  # name of topic, see class method
  def topic_s
    self.class.topic_s
  end
  
  # translated version to topic_s
  def topic_t
    self.class.topic_t
  end

  # pluralized version of topic_s
  def topics_s
    self.class.topics_s
  end
  
  # translated and pluralized version of topic_s
  def topics_t
    self.class.topics_t
  end
  
  # member name for membership relationship
  def member_s
    self.class.member_s
  end

  # member name for membership relationship
  def member_t
    self.class.member_t
  end

  # member name for membership relationship
  def members_s
    self.class.members_s
  end

  # member name for membership relationship
  def members_t
    self.class.members_t
  end

  # makes sure that site name is assigned in lower case
  def site_name=(a_site_name)
    self[:site_name] = a_site_name.downcase if a_site_name
  end

  # just in case upcase the country code
  def country_code
    self[:country_code].upcase if self[:country_code]
  end
  
  # forces upcase and turns empty strings to nil values
  def country_code=(a_country_code)
    self[:country_code] = a_country_code.strip.upcase unless a_country_code.to_s.empty?
  end

  # Performs a deep attribute read in the sense that it descends into child instances and tries to find
  # a name value that matches the current locale country code in the
  # associated address instance
  def deep_read_attribute(attr_name, options={})
    defaults = { :country_code => current_country_code }
    options = defaults.merge(options).symbolize_keys
    
    return self[attr_name.to_sym] if self.country_code == options[:country_code]
    self.children.each do |child|
      if value = child.deep_read_attribute(attr_name, options)
        return value
      end
    end
    return self[attr_name.to_sym] unless self.parent
    nil
  end

  # Performs a deep write analogous to the deep_read_attribute.
  def deep_write_attribute(attr_name, attr_value, options={})
    defaults = {:country_code => current_country_code}
    options = defaults.merge(options).symbolize_keys
    
    if self.country_code == options[:country_code]
      self.modified!
      return self[attr_name.to_sym] = attr_value
    end
    children.each do |child|
      if value = child.deep_write_attribute(attr_name, attr_value, options)
        return value
      end
    end
    unless self.parent  # at the root
      if self.country_code.nil?
        self.modified!
        self[attr_name.to_sym] = attr_value
        self.country_code = options[:country_code]
      else
        if self.new_record?
          return self.children.build(:country_code => options[:country_code], attr_name.to_sym => attr_value)
        else
          return self.children.create(:country_code => options[:country_code], attr_name.to_sym => attr_value)
        end
      end
    end
    nil
  end
  
  # validates tax code if present
  def validate_tax_code
    if !self.tax_code.blank? && self.country_code &&
        !LocalizedTaxSelect::localized_taxes_array(self.country_code).empty?
      errors.add(:tax_code, "invalid, check examples %{example}".t  % {
        :example => self.tax_code_example
      }) unless self.tax_code =~ self.tax_code_regexp
    end
  end
  
  # returns a regular expression for matching the country's tax code
  def tax_code_regexp
    @tax_code_regexp_cache ||= Utility.tax_regexp(self.country_code)
  end
  
  # returns a string of tax id examples with abbreviated tax names
  #
  # e.g.
  #
  #   000-00-0000 for SSN or 99-0000000 for TIN
  #
  def tax_code_example
    Utility.tax_example_in_words(self.country_code)
  end
  
  # Custom validation
  def validate
    #--- banned sites
    errors.add(:site_name, I18n.t('activerecord.errors.messages.exclusion')) if !errors.invalid?(:site_name) && 
      BANNED_SITE_NAMES.include?(self.site_name.downcase) || (site_name =~ /^www|^-|^_/)
    
    #--- no tier type (kind)  
    self.errors.add(:kind, I18n.t('activerecord.errors.messages.empty')) if !self.kind || self.kind == :tier
    
    #--- pre approved emails
    self.pre_approved_emails_a.each do |address|
      unless address =~ ValidatesEmailFormatOf::Regex
        self.errors.add(:pre_approved_emails, I18n.t("activerecord.errors.messages.email_format"))
        break
      end
    end
  end

  # returns an array of email addresses from pre_approved_emails fake attribute
  #
  # e.g. 
  #
  #   "a@b.com, c@d.com"  ->  ["a@b.com", "c@d.com"]
  #
  def pre_approved_emails_a
    self.pre_approved_emails ? self.pre_approved_emails.split(',').map(&:strip).compact.uniq : []
  end

  def validates_tax_code
    errors.add(:tax_code, I18n.t('activerecord.errors.messages.tax_format') % {
      :example => self.tax_code_example
    }) unless self.tax_code =~ self.tax_code_regexp
  end

  # URL validator
  def validates_url(attrib_name, url_value)
    begin
      uri = URI.parse(url_value)
      raise unless [URI::HTTP, URI::HTTPS, URI::Generic].include?( uri.class )
    rescue URI::InvalidURIError
      errors.add(attrib_name.to_sym, I18n.t('activerecord.errors.messages.invalid'))
    rescue Exception => e
      errors.add(attrib_name.to_sym, I18n.t('activerecord.errors.messages.invalid'))
    end
  end

  def modified?
    @modified
  end

  def modified!
    @modified = true
  end

  # Clones the address to be the billing address. This is used for
  # the Orders and Invoices be printed correctly.
  def find_or_clone_billing_address(options={})
    defaults = { :country => 'US' }
    options = defaults.merge(options).symbolize_keys
    Address.new(self.address(options).content_attributes.merge!(
      :company_name => name(options),
      :kind => :billing
    )) if self.address
  end
  
  # returns the uri part of the url representing the company domain
  # e.g. 'apple.com' from 'http://www.apple.com'
  def site_domain
    if self.site_url
      split_host = URI.parse(self.site_url).host.split('.')
      "#{split_host[split_host.size - 2]}.#{split_host[split_host.size - 1]}" if split_host.size > 1
    end
  rescue URI::InvalidURIError
    nil
  end

  # returns all subsidiaries including the headquarters in all regions
  # e.g. Apple, Apple Inc., Apple GmbH, etc.
  def worldwide
    result = [self.root]
    result += self.root.children
    result.uniq
  end

  # determines the default currency based on the country code
  def default_currency
    self.country_to_currency_code(self.country_code)
  end
  
  # derives locale from language code and country, not necessary full locale or nil, e.g. :en, or :"en-US"
  def locale
    result = []
    result << self.language_code
    result << self.country_code if self.language_code
    result.compact.reject(&:blank?).empty? ? nil : result.compact.reject(&:blank?).join("-").to_sym
  end
  
  # returns the best matching locale based on the language and country code
  def default_locale
    Utility.full_locale(self.locale) || :"en-US"
  end
  
  # Creates a piggy bank with default_currency
  def create_piggy_bank_with_default_currency(options={})
    create_piggy_bank_without_default_currency({
      :currency => self.default_currency
    }.merge(options))
  end
  alias_method_chain :create_piggy_bank, :default_currency

  # returns true if geo location has changed, therefore, the object is stale
  # and must be updated on Address after_save 
  def geo_location_changed?
    self.changed.include?("lat") || self.changed.include?("lng")
  end

  # returns a GeoKit::GeoLoc location instance based on address
  def geo_location
    if loc = Location.build_from(self.address || self.country_code)
      res = GeoKit::GeoLoc.new(loc.geokit_attributes)
      res.success = !!(res.lat && res.lng)
      res
    end
  end
  
  # returns true if the objec has been geo coded with lat/lng attributes
  def geo_coded?
    !!(self.lat && self.lng)
  end

  # name setter
  def name=(text)
    self[:name] = text
  end

  # returns kases count either from counter field or through query
  def kases_count
    if self.class.kases_count_column?
      self[:kases_count] || 0
    else
      self.kases.count("kases.id", Kase.find_options_for_visible({:distinct => true})) || 0
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

  # returns members count either from counter field or through query
  def members_count
    if self.class.members_count_column?
      self[:members_count]
    else
      self.members.count("people.id", Membership.find_options_for_active_state({:distinct => true}))
    end
  end

  # updates members count counter
  def update_members_count
    if self.class.members_count_column?
      self.update_attribute(:members_count, 
        self[:members_count] = self.members.count("people.id", {:distinct => true}))
      self[:members_count]
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

  # returns topics count either from counter field or through query
  def topics_count
    if self.class.topics_count_column?
      self[:topics_count]
    else
      self.topics.active.count
    end
  end

  # updates topics count counter
  def update_topics_count
    if self.class.topics_count_column?
      self.update_attribute(:topics_count, self[:topics_count] = self.topics.active.count)
      self[:topics_count]
    end
  end

  # category setter
  def category_id=(id)
    self.tier_category_id = id
  end

  # category getter
  def category_id
    self.tier_category_id
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
  
  # summary, otherwise as dito
  def summary_with_any_as_default
    summary_without_any_as_default || self.class.localized_facets_without_base(:summary).map {|m| send(m)}.compact.first
  end
  alias_method_chain :summary, :any_as_default

  # used for attachment column
  def generate_uuid 
    self[:uuid] ||= Utility.generate_random_uuid
  end

  # use first 10 uuid digits to encode attachment id
  def attachment_uuid
    self.uuid.gsub(/-/, '')[0..9] if self.uuid
  end

  # returns true for worldwide operation, i.e. if no geographic location is selected,
  # false if there is a country code associated
  def single_geo_location
    @single_geo_location ? !!@single_geo_location : !self.country_code.nil?
  end
  
  # setter for single geo location
  def single_geo_location=(value)
    value = value.is_a?(FalseClass) || (value.is_a?(String) && value.match(/0|false/)) ? false : true
    self.country_code = nil unless value
    @single_geo_location = value
  end
  
  # retrieves a reputation points based on an action if associated to this tier
  def find_reputation_threshold_action_points(action)
    if tp = self.reputation_thresholds.find(:first, 
        :conditions => ["reward_rates.action = ?", action.to_s])
      tp
    elsif self.parent && (ptp = self.parent.reputation_thresholds.find(:first, 
        :conditions => ["reward_rates.action = ?", action.to_s]))
      ptp
    end
  end

  # returns a valid currency for country code, e.g. "US" -> "USD", "DE" -> "EUR"
  def country_to_currency_code(country_code)
    Utility.country_to_currency_code(country_code)
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
    self.activation_code = Digest::SHA1.hexdigest(Time.now.to_s.split(//).sort_by {rand}.join)
    self.send_registration
  end
  
  def do_delete
    self.deleted_at = Time.now.utc
  end

  def do_activate
    @activated = true
    self.activated_at = Time.now.utc
    self.deleted_at = self.activation_code = nil
    
    # assign root
    if self.country_code
      if root = self.class.find_worldwide_by_permalink_and_active(self.permalink)
        self.parent = root
      end
    else
      transaction do 
        self.class.find(:all, :conditions => [
          "tiers.permalink = ? AND tiers.country_code IS NOT NULL AND tiers.parent_id IS NULL", self.permalink
        ], :lock => true).each do |tier|
          tier.update_attribute(:parent, self)
        end
      end
    end
    
    # send activation mail
    self.send_activation
    
    # adds "welcome" kase to new community
    if self.kases.empty?
      if template = Kase.find_template_by_language(self.language_code.blank? ? 'en' : self.language_code)
        welcome = self.clone_kase_template(template)
        self.kases.reload
      end
    end
  end
  
  # Make sure that to the user unkown child instances
  # are saved if they were updated with new data
  def save_subsidiaries
    children.each do |child|
      child.save! if child.modified?
    end
  end
  
  # send registration email
  def send_registration
    TierMailer.deliver_registration(self)
  end
  
  # send activation email
  def send_activation
    TierMailer.deliver_activation(self)
  end
  
  # builds a duplicate from this instance and replaces some placeholders
  # with information from organization 
  def clone_kase_template(template)
    kase = template.clone
    
    kase.template = false
    kase.tier = self
    kase.person = self.created_by
    kase.title = kase.title % {:name => self.name}
    kase.title = kase.title % {:type => self.class.human_name}
    kase.description = kase.description % {:name => self.name}
    kase.description = kase.description % {:type => self.class.human_name}
    kase.description = kase.description % {:url => "http://#{Utility.site_domain}/#{kase.permalink}"}
    kase.save(false)
    kase.activate!
    kase
  end

  # destroys all associated kases through kontext
  def destroy_all_kases_and_kontexts
    self.all_kases.destroy_all
    self.kontexts.destroy_all
  end

end
