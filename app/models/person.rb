# The person model represents all information relevant in profiles.
class Person < ActiveRecord::Base
  include QueryBase
  
  #--- constants
  SHORT_SALUTATION_MALE               = 'Mr'
  SHORT_SALUTATION_FEMALE             = 'Ms'
  PARTNER_INITIAL_RESPONSE_QUOTA      = 5
  PARTNER_MAXIMUM_RESPONSE_QUOTA      = 100
  DEFAULT_VOUCHER_QUOTA               = 25
  FIND_ALL_IDS_LIMIT                  = 1000
  MAXIMUM_IMAGE_SIZE                  = 1024

  SIGNUP_CREDIT_CENTS                 = 100
  
  MEMBER_NAME                         = "member"
  MEMBERS_NAME                        = MEMBER_NAME.pluralize
  PARTNER_NAME                        = "partner"
  PARTNERS_NAME                       = PARTNER_NAME.pluralize

  #--- accessors
  attr_accessor :registering_partner
  attr_protected :registering_partner
  attr_accessor :payment_object
  attr_protected :status
  attr_accessor :permalink_change
  
  #--- associations
  belongs_to :academic_title # Prof. Dr., etc.
  belongs_to :personal_status # Entrepreneur, Civil Servant, etc.
  has_one :user, :dependent => :delete
  has_one :piggy_bank, :as => :owner,
    :class_name => 'PiggyBankAccount',
    :dependent => :destroy

  has_many :reputations, :foreign_key => :receiver_id, :dependent => :destroy
  has_many :deposit_accounts, :dependent => :destroy
  has_and_belongs_to_many :spoken_languages

  has_many :employments, :dependent => :destroy
  has_many :employers,
    :through => :employments,
    :class_name => 'Organization',
    :source => :employer,
    :order => "memberships.created_at DESC",
    :conditions => "memberships.status = 'active'"
  has_many :organizations,
    :through => :employments,
    :class_name => 'Organization',
    :source => :employer,
    :order => "memberships.created_at DESC"

  has_many :subscriptions, :order => "subscriptions.created_at ASC", :dependent => :destroy
  has_many :partner_subscriptions, :order => "subscriptions.created_at ASC",
    :class_name => 'Subscription',
    :finder_sql => 'SELECT subscriptions.* FROM subscriptions ' + 
      'INNER JOIN topics ON topics.id = subscriptions.product_id ' +
      'WHERE subscriptions.person_id = #{id} AND topics.sku_type = \'#{Product::SKU_TYPE_PARTNER_SUBSCRIPTION}\''
  has_many :subscribables,
    :through => :subscriptions,
    :source => :product,
    :order => 'subscriptions.created_at ASC'
           
  has_many :kases, :dependent => :destroy
  has_many :accepted_kases, :class_name => 'Kase', :foreign_key => 'assigned_person_id'
  has_many :assets, :dependent => :destroy
  has_many :responses, :dependent => :destroy
  has_many :responded_kases, :through => :responses, :source => :kase, :foreign_key => :person_id

  has_many :comments, :class_name => 'Comment', :foreign_key => :sender_id, :dependent => :nullify
  has_many :received_comments, :class_name => 'Comment', :foreign_key => :receiver_id, :dependent => :nullify
  
  has_many :clarifications_received, :class_name => 'Clarification', :foreign_key => :receiver_id
  has_many :clarifications_sent, :class_name => 'Clarification', :foreign_key => :sender_id
  has_many :clarifiable_kases,
    :through => :clarifications_received,
    :source => :kase,
    :foreign_key => :commentable_id,
    :conditions => "comments.commentable_type = 'Kase'"
  has_many :clarifiable_responses,
    :through => :clarifications_received,
    :source => :response,
    :foreign_key => :commentable_id,
    :conditions => "comments.commentable_type = 'Response'"

  has_many :sent_invitations, :class_name => 'Invitation', :foreign_key => :sender_id, :dependent => :destroy
  has_many :received_invitations, :class_name => 'Invitation', :foreign_key => :receiver_id
  has_many :invitees,
    :through => :sent_invitations,
    :source => :invitee,
    :foreign_key => :receiver_id, # :invitee_id,
    :class_name => 'Person'
  has_many :invitors,
    :through => :received_invitations,
    :source => :invitor,
    :foreign_key => :sender_id,  # :invitor_id,
    :class_name => 'Person'
  has_many :created_organizations,
    :class_name => 'Organization',
    :foreign_key => :created_by_id,
    :dependent => :nullify
  has_many :created_products,
    :class_name => 'Product',
    :foreign_key => :created_by_id,
    :dependent => :nullify
  has_many :received_votes,
    :class_name => 'Vote',
    :finder_sql => 'SELECT DISTINCT votes.* from votes ' +
      'LEFT OUTER JOIN kases ON kases.id = votes.voteable_id AND votes.voteable_type = \'Kase\'' +
      'LEFT OUTER JOIN responses ON responses.id = votes.voteable_id AND votes.voteable_type = \'Response\' ' +
      'WHERE kases.person_id = #{id} OR responses.person_id = #{id} ' +
      'ORDER BY votes.id',
    :counter_sql => 'SELECT COUNT(DISTINCT votes.id) FROM votes ' +
      'LEFT OUTER JOIN kases ON kases.id = votes.voteable_id AND votes.voteable_type = \'Kase\'' +
      'LEFT OUTER JOIN responses ON responses.id = votes.voteable_id AND votes.voteable_type = \'Response\' ' +
      'WHERE kases.person_id = #{id} OR responses.person_id = #{id} ' +
      'ORDER BY votes.id'
  has_many :received_up_votes,
    :class_name => 'Vote',
    :finder_sql => 'SELECT DISTINCT votes.* from votes ' +
      'LEFT OUTER JOIN kases ON kases.id = votes.voteable_id AND votes.voteable_type = \'Kase\'' +
      'LEFT OUTER JOIN responses ON responses.id = votes.voteable_id AND votes.voteable_type = \'Response\' ' +
      'WHERE (kases.person_id = #{id} OR responses.person_id = #{id}) ' +
      '  AND votes.vote > 0 ' +
      'ORDER BY votes.id',
    :counter_sql => 'SELECT COUNT(DISTINCT votes.id) FROM votes ' +
      'LEFT OUTER JOIN kases ON kases.id = votes.voteable_id AND votes.voteable_type = \'Kase\'' +
      'LEFT OUTER JOIN responses ON responses.id = votes.voteable_id AND votes.voteable_type = \'Response\' ' +
      'WHERE (kases.person_id = #{id} OR responses.person_id = #{id}) ' +
      '  AND votes.vote > 0 ' +
      'ORDER BY votes.id'
  has_many :received_down_votes,
    :class_name => 'Vote',
    :finder_sql => 'SELECT DISTINCT votes.* from votes ' +
      'LEFT OUTER JOIN kases ON kases.id = votes.voteable_id AND votes.voteable_type = \'Kase\'' +
      'LEFT OUTER JOIN responses ON responses.id = votes.voteable_id AND votes.voteable_type = \'Response\' ' +
      'WHERE (kases.person_id = #{id} OR responses.person_id = #{id}) ' +
      '  AND votes.vote < 0 ' +
      'ORDER BY votes.id',
    :counter_sql => 'SELECT COUNT(DISTINCT votes.id) FROM votes ' +
      'LEFT OUTER JOIN kases ON kases.id = votes.voteable_id AND votes.voteable_type = \'Kase\'' +
      'LEFT OUTER JOIN responses ON responses.id = votes.voteable_id AND votes.voteable_type = \'Response\' ' +
      'WHERE (kases.person_id = #{id} OR responses.person_id = #{id}) ' +
      '  AND votes.vote < 0 ' +
      'ORDER BY votes.id'

  self.keep_translations_in_model = true
  translates :summary, :base_as_default => true
  can_be_flagged :reasons => [:privacy, :inappropriate, :abuse, :crass_commercialism, :spam]
  acts_as_addressable :personal, :business, :billing, :has_one => true
  acts_as_taggable_types :want_expertises, :have_expertises, :interests,
    :universities, :industries, :academic_degrees, :professions,
    :professional_titles
  acts_as_mappable :default_units => :kms
  acts_as_authorizable
  acts_as_buyer
  acts_as_seller
  acts_as_poller
  acts_as_bidder
 	acts_as_follower
 	acts_as_followable
  has_friendships
  acts_as_visitable
  acts_as_rater :rateables => {:rated_responses => 'Response'}
  has_many :response_ratings,
    :class_name => 'Rating',
    :source => :person,
    :through => :responses
  acts_as_voter :voteables => { :voted_responses => 'Response', :voted_comments => 'Comment' }
  has_attached_file :avatar, 
    :storage => %w(development test).include?(RAILS_ENV) ? :filesystem : :s3,
    :s3_credentials => "#{RAILS_ROOT}/config/amazon_s3.yml",
    :s3_permissions => 'public-read',
    :s3_headers => {'Expires' => 1.year.from_now.httpdate},
    :bucket => "#{SERVICE_DOMAIN}-#{RAILS_ENV}",
    :styles => {:thumb => "35x35#", :profile => "113x113#", :landscape => "320x200>", :portrait => "200x266>"},
    :url => "/images/application/:class/:attachment/:uuid/:style_:basename.:extension",
    :path => "#{%w(development test).include?(RAILS_ENV) ? "#{RAILS_ROOT}/public/" : ''}images/application/:class/:attachment/:uuid/:style_:basename.:extension"
  has_friendly_id :custom_id, 
    :use_slug => true,
    :cache_column => :permalink,
    :approximate_ascii => true

  #--- named_scope
  named_scope :visible, :select => "DISTINCT people.*", 
    :conditions => ["people.status NOT IN(?)", ['created']]
  named_scope :members, :select => "DISTINCT people.*", 
    :conditions => ["people.status IN(?)", ['member']]
  named_scope :partners, :select => "DISTINCT people.*", 
    :conditions => ["people.status IN(?)", ['partner']]

  #--- state machine
  acts_as_state_machine :initial => :created, :column => :status
  state :created
  state :member, :enter => :enter_member, :after => :after_member
  state :partner, :enter => :enter_partner, :exit => :exit_partner
  
  event :activate do
    transitions :from => :created, :to => :member
  end

  event :upgrade do
    transitions :from => :member, :to => :partner
  end

  event :downgrade do
    transitions :from => :partner, :to => :member
  end
  
  event :expire do
    transitions :from => :partner, :to => :member, :guard => :partner_subscription_expired?
  end

  #--- validations
  validates_associated :personal_address, :message => I18n.t('activerecord.errors.messages.address_invalid')
#  validates_presence_of :personal_address, :message => I18n.t('activerecord.errors.messages.address_invalid'),
#    :if => Proc.new {|p| p.user ? ![:passive, :pending].include?(p.user.current_state) : false}
  validates_associated :business_address, :message => I18n.t('activerecord.errors.messages.address_invalid')
#  validates_presence_of :business_address, :message => I18n.t('activerecord.errors.messages.address_invalid'),
#    :if => Proc.new {|p| p.partner? || p.registering_partner?}
  validates_associated :billing_address, :message => I18n.t('activerecord.errors.messages.address_invalid')
#  validates_presence_of :billing_address, :message => I18n.t('activerecord.errors.messages.address_invalid'),
#    :if => Proc.new {|p| p.partner? || p.registering_partner?}
  validates_uniqueness_of :email, :unless => :skip_uniqueness_validation?
  
  validates_attachment_size :avatar, :in => 1..MAXIMUM_IMAGE_SIZE.kilobyte,
    :message => I18n.t('activerecord.errors.messages.image_size') % {:size => "#{MAXIMUM_IMAGE_SIZE}KB"}
  validates_attachment_content_type :avatar, :content_type => Utility.image_content_types,
    :message => I18n.t('activerecord.errors.messages.image_types') % {
      :extensions => Utility::VALID_IMAGE_FILE_EXTENSIONS.map(&:upcase).to_sentence.chop_period
    }

  validates_presence_of :gender
  validates_inclusion_of :gender, :in => %w(m f)
  validates_presence_of :first_name, :last_name
#  validates_uniqueness_of :permalink, :case_sensitive => false, :as => :custom_id, :unless => :skip_uniqueness_validation?
  validates_format_of :custom_id, :with => /^[a-zA-Z0-9-]+$/,
    :if => Proc.new {|p| p.user ? ![:passive, :pending].include?(p.user.current_state) : false}
  validates_size_of :custom_id, :within => User::LOGIN_MIN_CHARACTERS..User::LOGIN_MAX_CHARACTERS,
    :if => Proc.new {|p| p.user ? ![:passive, :pending].include?(p.user.current_state) : false}
  validates_confirmation_of :custom_id,
    :if => Proc.new {|p| p.user ? ![:passive, :pending].include?(p.user.current_state) : false}
  validates_format_of :twitter_name, :with => /^[a-zA-Z0-9_]+$/, :allow_nil => true
  validates_size_of :twitter_name, :within => 1..15, :allow_nil => true
  validates_size_of :summary, :within => 5..100, :allow_nil => true, :allow_blank => true
#  validates_presence_of :tax_code, :allow_empty => true, :if => Proc.new {|p| p.partner? || p.registering_partner?}
  
  #--- access rights
  allows_display_of :first_name,  :if => Proc.new {|o| o.accepts_right? :first_name, User.current_user}
  allows_display_of :middle_name, :if => Proc.new {|o| o.accepts_right? :middle_name, User.current_user}
  allows_display_of :last_name,   :if => Proc.new {|o| o.accepts_right? :last_name, User.current_user}
  allows_display_of :email,       :if => :never?
  allows_display_of :avatar,      :if => Proc.new {|o| o.accepts_right? :avatar, User.current_user}
  allows_display_of :tax_code,    :if => :never?

  #--- class methods
  class << self

    def kind
      :person
    end

    def member_s
      MEMBER_NAME
    end
    
    def member_t
      MEMBER_NAME.t
    end
    
    def partner_s
      PARTNER_NAME
    end

    def partner_t
      PARTNER_NAME.t
    end

    def finder_name
      :find_by_permalink
    end
    
    def finder_options
      {:include => [:user]}
    end

    # returns all expired partners
    def find_all_expired_partners
      find(:all, find_options_for_expired_partners)
    end

    # returns all soon to expire partners, 7 days prior to the expiration date
    def find_all_soon_to_expire_partners
      find(:all, find_options_for_expired_partners(-7)) - find_all_expired_partners
    end
    
    def find_options_for_expired_partners(days=0)
      joins = ["LEFT OUTER JOIN subscriptions ON people.id = subscriptions.person_id"]
      joins << "LEFT OUTER JOIN topics ON topics.id = subscriptions.product_id "
      
      conditions = sanitize_sql(["people.status IN (?)", ["partner"]])
      conditions << " AND "
      conditions << sanitize_sql(["topics.sku_type = ?", Product::SKU_TYPE_PARTNER_SUBSCRIPTION])
      
      select =  "people.*, "
      select << "SUM(CASE WHEN DATE_ADD(DATE_ADD(subscriptions.last_renewal_on, INTERVAL subscriptions.length_in_issues MONTH), INTERVAL #{days} DAY) < NOW() THEN 1 ELSE 0 END) AS total_expired, "
      select << "SUM(CASE WHEN DATE_ADD(DATE_ADD(subscriptions.last_renewal_on, INTERVAL subscriptions.length_in_issues MONTH), INTERVAL #{days} DAY) > NOW() THEN 1 ELSE 0 END) AS total_alive, "
      select << "COUNT(subscriptions.id) AS total"

      group_and_having = "subscriptions.id HAVING total > 0 AND total_expired > 0 AND total_alive = 0"
      
      {
        :select => select, 
        :joins => joins.join(" "),
        :conditions => conditions, 
        :group => group_and_having
      }
    end

    # overrides default finder and makes sure only active users are returned
    def find_by_permalink(permalink, options={})
      find(permalink, find_options_for_active(options))
    end
    
    # find options for permalink
    def find_options_for_find_by_permalink(permalink, options={})
      {:conditions => ["people.permalink = ? AND people.status IN (?)", permalink, ['member', 'partner']]}.merge_finder_options(options)
    end
    
    def find_all_active(options={})
      conditions = ["status IN (?)", ['member', 'partner']]
      conditions = sanitize_and_merge_conditions(conditions, options[:conditions]) if options[:conditions]
      find(:all, {
        :conditions => conditions,
        :order => "addresses.country_code ASC", :include => :personal_address
      }.merge(options))
    end

    # finds all partners
    def find_all_partners(options={})
      conditions = ["status IN (?)", ['partner']]
      conditions = sanitize_and_merge_conditions(conditions, options[:conditions]) if options[:conditions]
      find(:all, {
        :conditions => conditions,
        :order => "addresses.country_code ASC", :include => :personal_address
      }.merge(options))
    end
    
    # returns a conditions options for active
    def find_options_for_active(options={})
      {:conditions => ["people.status IN (?)", ['member', 'partner']]}.merge_finder_options(options)
    end
    
    # returns an array of ids by conditions
    def find_all_ids(options={})
      find(:all, options.merge({:select => 'id', :limit => FIND_ALL_IDS_LIMIT})).map(&:id) 
    end

    # Goes through all partners and sees if the response quotas need updating
    # Quota is the number of responses (answers) a partner is allowed to 
    # post per month
    # TODO obsolete, remove!
    def find_and_update_all_response_quotas
      Person.find(:all, :conditions => [
          "people.status = ? AND (response_quota_updated_at < ? OR response_quota_updated_at IS NULL)",
          'partner', Time.now.utc.last_month
        ], :order => 'response_quota_updated_at ASC').each do |partner|
        partner.calculate_and_update_response_quota
      end
    end

    # find options for partners
    def find_options_for_partner_status
      {:conditions => ["people.status IN (?)", ["partner"]]}
    end

    # find options for members
    def find_options_for_member_status
      {:conditions => ["people.status IN (?)", ["member"]]}
    end

    # finds all partners matching/qualify (are qualified for) a kase
    def find_matching_partners_for(kase, options={})
      kase ? (@find_matching_partners_for_cache ||= kase.find_matching_partners(options)) : []
    end
    
    # finds all employees of organization
    def find_employees_of(organization, options={})
      @find_employees_of_cache ||= Person.find(:all, options.merge_finder_options(find_options_for_employees_of(options)))
    end
    
    # finder options for finding employees of organization X
    def find_options_for_employees_of(organization, options={})
      {
        :joins => sanitize_sql(["LEFT OUTER JOIN memberships ON people.id = memberships.person_id"]) + ' ' +
          sanitize_sql(["LEFT OUTER JOIN tiers ON (tiers.id = memberships.tier_id AND tiers.type IN (?))",
            Organization.self_and_subclasses.map(&:name)]),
        :conditions => ["tiers.id = ?", organization.object_id]
      }.merge_finder_options(options.merge(Employment.find_options_for_active_state))
    end

    # finds all members of tier
    def find_members_of(tier, options={})
      Person.find(:all, options.merge_finder_options(find_options_for_members_of(tier)))
    end

    # finder options for finding members of tier X
    def find_options_for_members_of(tier, options={})
      {
        :joins => sanitize_sql(["LEFT OUTER JOIN memberships ON people.id = memberships.person_id"]) + ' ' +
          sanitize_sql(["LEFT OUTER JOIN tiers ON (tiers.id = memberships.tier_id AND tiers.type IN (?))",
            tier.class.self_and_subclasses.map(&:name)]),
        :conditions => ["tiers.id = ?", tier.id]
      }.merge_finder_options(options.merge(Membership.find_options_for_active_state))
    end
    
    # finds all featured by language and country code or nil if not important
    def find_all_featured(options={})
      find(:all, find_options_for_featured_by_language_code_and_country_code(nil, nil, options))
    end

    # finds all featured by language and country code or nil if not important
    def find_all_featured_by_language_code_and_country_code(language_code, country_code, options={})
      find(:all, find_options_for_featured_by_language_code_and_country_code(language_code, country_code, options))
    end
    
    # find options for finding featured people
    def find_options_for_featured_by_language_code_and_country_code(language_code, country_code, options={})
      conditions = sanitize_sql({:featured => true})
      conditions += sanitize_sql([" AND people.status IN (?)", ['member', 'partner']])
      conditions += sanitize_sql([" AND users.language = ?", language_code]) if language_code
#      conditions += " AND " + ["addresses.country_code = ?", country_code] if country_code
      {:conditions => conditions, :order => "people.created_at DESC"}.merge(options).merge({:include => :user})
    end
    
    # find options to find all people with given spoken language
    #
    # e.g.
    #
    #   find_options_for_spoken_languages("Korean") => options for "Korean" speakers
    #   find_options_for_spoken_languages(["German", "English"]) => options for "German" OR "English" speakers
    #
    def find_options_for_spoken_languages(language_names, options={})
      language_names = [language_names].flatten
      conditions = sanitize_and_merge_conditions_with_or(*language_names.map {|name| ["(spoken_languages.name LIKE ? OR spoken_languages.native_name LIKE ?)", name, name]})
      { 
        :joins => "LEFT OUTER JOIN people_spoken_languages ON people_spoken_languages.person_id = people.id " +
          "LEFT OUTER JOIN spoken_languages ON people_spoken_languages.spoken_language_id = spoken_languages.id",
        :conditions => conditions
      }.merge_finder_options(options)
    end

    # finder options for personal status e.g. "employee", "entrepreneur"
    def find_options_for_personal_status(personal_statuses, options={})
      personal_statuses = [personal_statuses].flatten
      conditions = []
      personal_statuses.each do |status|
        PersonalStatus.localized_facets(:name).each do |facet|
          conditions << ["(personal_statuses.#{facet} LIKE ?)", status]
        end
      end
      conditions = sanitize_and_merge_conditions_with_or(*conditions)
      { 
        :joins => "LEFT OUTER JOIN personal_statuses ON personal_statuses.id = people.personal_status_id",
        :conditions => conditions
      }.merge_finder_options(options)
    end
    
    # overrides additional query find options from query base
    def find_class_options_for_query_with_or(query, options={})
      find_options_for_spoken_languages(query).merge_finder_options_with_or(
        find_options_for_personal_status(query))
    end

    # overrides additional query find options from query base
    def find_class_options_for_query_with_and(query, options={})
      find_options_for_active(options)
    end

    # overrides query columns from query base
    def find_by_query_columns
      ['first_name', 'middle_name', 'last_name', 'summary', 'status']
    end

    # kases count db column?
    def kases_count_column?
      columns.to_a.map {|a| a.name.to_sym}.include?(:kases_count)
    end

    # responses count db column?
    def responses_count_column?
      columns.to_a.map {|a| a.name.to_sym}.include?(:responses_count)
    end

    # votes received count column?
    def received_votes_count_column?
      columns.to_a.map {|a| a.name.to_sym}.include?(:received_votes_count)
    end
    
    # up votes received count column?
    def received_up_votes_count_column?
      columns.to_a.map {|a| a.name.to_sym}.include?(:received_up_votes_count)
    end

    # down votes received count column?
    def received_down_votes_count_column?
      columns.to_a.map {|a| a.name.to_sym}.include?(:received_down_votes_count)
    end
    
    # find all visible
    def find_all_visible(options={})
      find(:all, find_options_for_visible(options))
    end
    
    # find options for visible
    def find_options_for_visible(options={})
      {:conditions => ["people.status NOT IN (?)", ['created']]}.merge_finder_options(options)
    end
    
  end

  #--- callbacks
  before_create :setup_email, :create_piggy_bank
  before_save :geocode_addresses
  before_validation_on_create :generate_uuid

  def geocode_addresses
    self.before_save_address(self.personal_address)
    self.before_save_address(self.business_address)
  end

  # geocode address in case it is a personal or business address
  # assigns person's location to either personal or business address
  def before_save_address(address)
    return unless address
    if ((self.partner? && :business == address.kind) || (self.member? && :personal == address.kind))
      if !self.geo_coded? || address.changed?
        res = GeoKit::Geocoders::MultiGeocoder.geocode(address.to_s)
        if res.success
          self.lat = address.lat = res.lat
          self.lng = address.lng = res.lng
        end
      end
    end
  rescue GeoKit::Geocoders::GeocodeError => ex
    logger.error "Exception #{ex.message} caught when geocoding #{address.to_s}"
    return
  end

  #--- state machine transitions
  
  def enter_member
    send_welcome(:member)
  end
  
  def after_member
    # add sign up bonus to person's piggy bank account
    self.piggy_bank.direct_deposit(
      Money.new(Person::SIGNUP_CREDIT_CENTS, self.piggy_bank.currency),
        :description => "Starting credit as sign up bonus.".t
    ) if self.piggy_bank && self.piggy_bank.virgin?
  end

  # executed when user becomes an partner
  def enter_partner
    set_voucher_quota(voucher_quota)

    # Setup response_quota (responses per month)
    # Only assign default response_quota when this is a new partner
    calculate_and_update_response_quota

    # set partner date
    self.partner_at ||= Time.now.utc

    # send welcome
    send_welcome(:partner)
  end

  # Executed when user leaves the state as partner by state machine
  def exit_partner
    send_partner_membership_expired
  end

  def send_welcome(new_status)
    I18n.switch_locale self.default_language || Utility.language_code do 
      PersonMailer.deliver_welcome(self, new_status)
    end
  end

  def send_partner_membership_expired
    I18n.switch_locale self.default_language || Utility.language_code do 
      PersonMailer.deliver_partner_membership_expired(self)
    end
  end

  def send_partner_membership_soon_to_expire
    I18n.switch_locale self.default_language || Utility.language_code do 
      PersonMailer.deliver_partner_membership_soon_to_expire(self)
    end
  end
  
  #--- instance methods

  # allows custom slugs/permalinks
  # Accessor for managing the friendly_id. 
  # Normally returns the same value as friendly_id, unless  @custom_id has 
  # just been assigned, in which case the new slug is passed to friendly_id 
  # to persist it on save. 
  def custom_id
    if self[:custom_id].present?
      self[:custom_id]
    elsif slug? && friendly_id
      friendly_id
    elsif self.user && self.user.login
      normalize_friendly_id(FriendlyId::SlugString.new(self.user.login))
    else
      Utility.generate_random_alpha_numeric(6)
    end
  end
  
  # override default setter
  def custom_id=(value)
    self[:custom_id] = self.permalink = value
  end

  # Persist the slug based on normal friendly_id logic (new records, etc.), 
  # or if the newly assigned @custom_slug attribute doesn't match the 
  # existing friendly_id. 
  def new_slug_needed? 
    super or self[:custom_id] != friendly_id
  end

  def kind
    self.current_state
  end

  def human_name
    self.partner? ? self.class.partner_t : self.class.member_t
  end

  # used for attachment column
  def generate_uuid 
    self[:uuid] ||= Utility.generate_random_uuid
  end

  # use first 10 uuid digits to encode attachment id
  def attachment_uuid
    self.uuid.gsub(/-/, '')[0..9] if self.uuid
  end

  # called in before_create
  # copies email from user
  def setup_email
    self.email = self.user.email if self.user
  end

  # Creates a piggy bank with default_currency
  def create_piggy_bank_with_personal_details(options={})
    defaults = {:currency => self.default_currency}
    options = defaults.merge(options).symbolize_keys
    create_piggy_bank_without_personal_details(options)
  end
  alias_method_chain :create_piggy_bank, :personal_details

  # is this person qualified to solving the given issue
  def is_qualified_for?(an_issue)
    an_issue.qualifies_for?(self)
  end

  # Returns the average response rating as a real (4.45)
  # Options:
  #   :from => <date when you want to start counting>
  #   :to => <date until you want to end counting>
  def average_response_rating(options={})
    defaults = { :from => self.created_at || Time.now.utc.last_year, :to => Time.now.utc }
    options = defaults.merge(options).symbolize_keys

    @resonse_rating_average_cache || @resonse_rating_average_cache = self.response_ratings.average(
      :rating,
      :conditions => ["ratings.created_at >= ? AND ratings.created_at <= ?", options[:from], options[:to]]
    ).to_f
  end

  # Needs to be called when user becomes Expert for the first time
  def reset_response_quota
    if !ever_subscribed_as_partner?
      update_attributes(
        :default_response_quota => PARTNER_INITIAL_RESPONSE_QUOTA,
        :current_response_quota => PARTNER_INITIAL_RESPONSE_QUOTA,
        :response_quota_updated_at => Time.now.utc
      )
      return true
    end
    false
  end

  # maximum no of responses this partner can post per month
  def default_response_quota
    if quota = read_attribute(:default_response_quota) && self.partner?
      return quota
    end
    0
  end

  # Responses still left month-to-date
  def current_response_quota
    if quota = read_attribute(:current_response_quota) && self.partner?
      return quota
    end
    0
  end

  # Response Quota is the number of responses (answers) an partner is allowed to 
  # post per month.
  # The current response_quota expires at the end of a full month since last updated.
  # It is updated with the default response_quota, which starts at 5 answers per month
  # and is increased or descreased depending on the last 3 months response rating.
  # The default response_quota is changed on the following average rating:
  #   5 -> 50% increase of current default_response_quota
  #   4 -> 25% increase
  #   3 -> no change
  #   2 -> 25% decrease
  #   1 -> 50% decrease
  # if there is no average (0) over the past 3 months, no change to default_response_quota
  # Returns true if updates were made to the response_quota fields, false, if otherwise.
  def calculate_and_update_response_quota
    result = false
    return false unless self.partner?
    Person.transaction(self) do
      # first time response_quota
      if read_attribute( :response_quota_updated_at ).nil?
        result = reset_response_quota
      end
      if self.response_quota_updated_at<Time.now.utc.last_month
        # aggregate average of previous 3 months
        from_time_range = self.response_quota_updated_at.months_ago(3)
        to_time_range = self.response_quota_updated_at
#        last_3m_average = self.response_ratings.average( :rating, :conditions => ["ratings.created_at >= ? AND ratings.created_at <= ?", from_time_range, to_time_range] )
        last_3m_average = self.average_response_rating(:from => from_time_range, :to => to_time_range)
        case last_3m_average
        when 1
          self.default_response_quota -= (self.default_response_quota*(0.5)).round   # reduce quota by 50%
        when 2
          self.default_response_quota -= (self.default_response_quota*(0.25)).round  # reduce quota by 25%
        when 4
          self.default_response_quota += (self.default_response_quota*(0.25)).round  # increase quota by 25%
        when 5
          self.default_response_quota += (self.default_response_quota*(0.5)).round   # increase quota by 50%
        end
        # update default, current response_quota and time stamp
        if [1, 2, 4, 5].include?( last_3m_average )
          self.default_response_quota = self.default_response_quota > Person::PARTNER_MAXIMUM_RESPONSE_QUOTA ? Person::PARTNER_MAXIMUM_RESPONSE_QUOTA : self.default_response_quota
          self.default_response_quota = self.default_response_quota < 0 ? 0 : self.default_response_quota
          result = update_attributes( :default_response_quota => self.default_response_quota,
                                      :current_response_quota => self.default_response_quota,
                                      :response_quota_updated_at => self.response_quota_updated_at.next_month )
        else
          result = update_attributes( :response_quota_updated_at, self.response_quota_updated_at.next_month )
        end
      end
    end
    result
  end

  # Resets the quota on how many voucher can be sent by this person voucher_quota
  def set_voucher_quota(a_quota=nil)
    if self.new_record?
      self[:voucher_quota] = a_quota.nil? ? Person::DEFAULT_VOUCHER_QUOTA : a_quota
    else
      update_attribute( :voucher_quota, a_quota.nil? ? Person::DEFAULT_VOUCHER_QUOTA : a_quota )
    end
  end

  # descrements voucher quota by 1 if available
  def decrement_voucher_quota
    self.decrement!(:voucher_quota) if self.voucher_quota > 0
  end
  
  # are there any vouchers left to send? remember we have a voucher quota
  def has_voucher_quota?
    return true if self.read_attribute(:voucher_quota).to_i > 0
    false
  end

  # returns the number of vouchers that can be passed on
  # alias for column voucher_quota, so we don't forget.
  def voucher_quota
    self[:voucher_quota]
  end

  # check if a person is in the list of previous invitors
  # this is used to check if a person has been invited before already
  # in order to avoid spam
  def is_invitor_of?(a_person)
    return true if self.invitees.find_by_id(a_person.id)
    false
  end
    
  # Simple wrapper/helper around the create_invitation method. Returns
  # an invitation instance
  def invite_as_contact(a_person, options={})
    invitation = self.create_invitation({ :invitee => a_person }.merge(options))
    invitation.open!
    invitation
  end

  # Is used to invite a new or existing user to your friends list
  # this will return an invitation instance that is valid or not.
  # The invitation.status tells the state of the invitation, which
  # at this point is "delivered" if sent or "sealed" if there were
  # errors. The invitation will be visible on the person object as:
  # 
  #   person.sent_invitations
  #   person.received_invitations
  #   
  # and invitors and invitees can be queried like
  #  
  #   person.invitees  (are those who have been invited by this person)
  #   person.invitors  (are those who have invited this person)
  #
  # Usage:
  # 
  # To invite an existing user, only specify at least the invitee
  #
  #  create_invitation :invitee => another_person, :with_voucher => false,
  #    :message => "Hello!"
  #
  # If you want to invite a new user, you need to provide more info, like:
  # 
  #   create_invitation :first_name => "Bla", :lastname => "Blup",
  #     :email => "bal@blup.com", :email_confirmation => "bal@blup.com",
  #     :message => "Hello!", :with_voucher => true || false
  #
  def create_invitation(options={})
    defaults = {:invitor => self, :language => self.default_language}
    options = defaults.merge(options).symbolize_keys
    
    invitation = Invitation.new(options)

    # complement already registered users
    if invitation.valid? && invitation.has_no_registered_invitee? && invitation.email
      if (invitee = Person.find_by_email(invitation.email)) && invitee.active?
        invitation.invitee = invitee
        invitation.first_name = invitee.first_name
        invitation.last_name = invitee.last_name
      end
    end

    if invitation.save
      invitation.send!
      self.invitees.reload
    end
    invitation
  end
  
  # Extends the bid() from acts_as_bidder
  # TODO:
  # - Void bidders that have been outbid!
  # - Callback function to support the void :before_outbid, :after_outbid
  # - 
  def bid_with_payment(a_bid, a_biddable)
    piggy_bank.authorize(a_bid, self, :expires_at => self.expires_at)
    if bid_without_payment(a_bid, a_biddable)
      # best bid accepted
      a_biddable.send_issue_auction_current_winning_bid(self, a_bid)
    else
      # bid declined
    end
  end
  alias_method_chain :bid, :payment

  def registering_partner?
    self.registering_partner == true
  end
  
  def registering_partner!
    self.registering_partner = true
  end

  # Returns a cart instance and sets a cart instance variable
  # if the cart is empty.
  # see plugin merchant_sidekick
  #
  # E.g.
  #
  #   cart = person.cart   -> returns a cart
  #   cart.add Product.find_three_month_partner_membership
  #
  def cart
    @cart || @cart = Cart.new(self.default_currency, :locale => self.default_locale)
  end

  # Currency set when user signed up
  # Returns currency code, e.g. EUR
  def default_currency
    self.user ? self.user.default_currency : (Utility.active_currency_codes.find {|c| c == Utility.currency_code} || "USD")
  end
  alias_method :default_currency_code, :default_currency
  
  # Language set when user signed up
  # Returns language code in uppercase, e.g. 'en'
  def default_language
    return self.user.language.downcase if self.user && self.user.language
    # default language code from application helper
    Utility.language_code
  end
  alias_method :default_language_code, :default_language

  # Tries to figure out the country location
  # of this user from the contact addresses given.
  # If non can be found, current language is returned. 
  def default_country
    return self.user.country.upcase if self.user && self.user.country
    if self.partner?
      if address = business_address
        return address.country_code.to_s.upcase
      end
    else
      if address = personal_address
        return address.country_code.to_s.upcase
      end
    end
    # default country from application helper
    Utility.country_code
  end
  alias_method :default_country_code, :default_country
  
  # sets the address default country
  def default_country=(value)
    if self.partner?
      address = self.business_address || self.build_business_address
      return self.business_address.country_code = value.to_s.upcase
    else
      address = personal_address || self.build_personal_address
      return self.personal_address.country_code = value.to_s.upcase
    end
  end
  
  # Return the locale inferred from the person's (user's) langugage settins
  # and the country selection. The country selection itself is inferred from 
  # the associated address, e.g. :person_address or :business_address.
  # If the locale cannot be inferred, the locale defaults to the default 
  # language portion or otherwise the apps default locale.
  #
  # E.g.
  # 
  #   :"de-DE"  (German - Germany)
  #   :"es-AR"  (Spanish - Argentina)
  #
  def default_locale
    self.user ? self.user.default_locale : :"en-US"
  end

  # Sums up all sales orders and normalizes currencies to default_currency
  def total_earning
    return @total_earning_cache if @total_earning_cache
    @total_earning_cache = Money.new(1, self.default_currency)
    self.sales_orders.each {|o| @total_earning_cache += o.total}
    @total_earning_cache = @total_earning_cache - Money.new(1, self.default_currency)
  end

  # Sums up all purchase orders and normalizes currencies to default_currency
  def total_spending
    return @total_spending_cache if @total_spending_cache
    @total_spending_cache = Money.new(1, self.default_currency)
    self.purchase_orders.each {|o| @total_spending_cache += o.total}
    @total_spending_cache = @total_spending_cache - Money.new(1, self.default_currency)
  end

  # profit or loss = earning - spending
  def total_profit
    self.total_earning - self.total_spending
  end

  # Returns the Date when the partner membership expires on
  # Sums up the date of all partner membership purchases
  # nil when all subscriptions have expired or never have been subscriptions
  def partner_membership_expires_on
    return @partner_membership_expires_on if @partner_membership_expires_on 
    expires_on = false
    self.partner_subscriptions.each do |sub|
      if expires_on
        expires_on = sub.expires_on if sub.expires_on > expires_on
      else
        expires_on = sub.expires_on
      end
    end
    self.partner_membership_expires_on = expires_on
  end
  alias_method :partner_expires_on, :partner_membership_expires_on

  # setter mostly used to clear the cash
  # currently used in subscripion do_activate
  def partner_membership_expires_on=(a_date)
    @partner_membership_expires_on = a_date
  end
  
  # has this person ever subscribed as partner before?
  def ever_subscribed_as_partner?
    !!self.partner_membership_expires_on
  end
  
  # returns true if person's partner membership subscription still alive?
  def is_partner_membership_active?
    @partner_membership_expires_on_cache || @partner_membership_expires_on_cache = partner_membership_expires_on
    @partner_membership_expires_on_cache ? @partner_membership_expires_on_cache > Date.today : false
  end
  
  # returns true, if a partner has just signed up for the first time and the membership is active
  def is_new_partner?
    if is_partner_membership_active?
      1 == self.partner_subscriptions.size
    else
      false
    end
  end
  
  # returns true if the person's membership subscription has expired?
  def is_partner_membership_expired?
    !is_partner_membership_active?
  end
  alias_method :partner_subscription_expired?, :is_partner_membership_expired?
  
  # Add as subscription if product line is subscribable...huhh?
  # If the 'product' is a subscription, it will be added to the
  # subscriptions and packages associations of the person
  def add_as_subscribable(product)
    subscription = nil
    transaction do 
      subscription = Subscription.create(
        :length_in_issues => case product.unit
          when :day then product.pieces * 0.03
          when :month then product.pieces
          when :year then product.pieces * 12
        end,
        :product => product,
        :person => self
      )
      self.reload if subscription.activate!
    end if product && product.is_subscribable?
    subscription
  end

  # finds all partner who's have expertise matches my want_expertises
  def find_matching_partners(options={})
    list = self.want_expertise_list
    Person.find_tagged_with(list, {
      :on => 'have_expertises',
      :conditions => ["people.id <> ?", self.id]
    }.merge_finder_options(options.merge_finder_options(Person.find_options_for_partner_status)))
  end

  # finds all members who's want expertises matches my have_expertises
  def find_matching_people(options={})
    list = self.have_expertise_list
    Person.find_tagged_with(list, {
      :on => 'want_expertises',
      :conditions => ["people.id <> ?", self.id]
    }.merge_finder_options(options.merge_finder_options(Person.find_options_for_member_status)))
  end

  # finds all kases matching with person's have_expertises, spoken languages and well answerered responses
  def find_matching_kases(options={})
    Kase.find_matching_kases_for_person(self, options)
  end

  # returns the deposit account for :deposit_type, or nil if not found
  def find_deposit_account(deposit_type)
    self.deposit_accounts.select {|i| i.kind == deposit_type.to_sym}.first
  end

  # Build a deposit account for a deposit method, like :paypal
  # Will be able to implement others
  def find_or_build_deposit_account(deposit_type, options={})
    unless account = find_deposit_account(deposit_type)
      account = self.deposit_accounts.build(options.merge(:type => deposit_type))
      raise "#{deposit_type.to_s.humanize} deposit account type not implemented." if account.class == DepositAccount
    else
      account.attributes = options
      account.person = self
    end
    account
  end

  # Find the current employment of the person
  def current_employment
    if employment = self.employments.select {|e| e.status == Employment.status(self.personal_status.english_name)}
      return employment.first
    end
    nil
  end
    
  # Find the current company the person is employed
  def current_company
    if employment = current_employment
      return employment.employer
    end
    nil
  end
    
  # company_name getter
  def company_name
    if my_company = self.current_company
      return my_company.name
    end
    nil
  end
  
  # getter for company_url
  def company_url
    if my_employment = self.current_employment
      return my_employment.company_url
    end
    nil
  end

  # setter for company_url
  def company_url=(an_url)
    if employment=current_employment
      if employment.new_record?
        employment.company_url = an_url
      else
        employment.update_attribute( :company_url, an_url )
      end
    else
      employment=self.employments.create( :status => Employment.status( self.personal_status.english_name ).to_s, :company_url => an_url )
    end
    employment.company_url
  end

  # Returns translated membership name
  def current_state_t(a_status=self.current_state)
    case a_status.to_sym
    when :member then self.member_t
    when :partner then self.partner_t
    end
  end

  def member_s
    self.class.member_s
  end
  
  def member_t
    self.class.member_t
  end
  
  def partner_s
    self.class.partner_s
  end

  def partner_t
    self.class.partner_t
  end

  # getter
  def first_name
    self[:first_name]
  end
  alias_method :firstname, :first_name
  
  # setter
  def first_name=(name)
    self[:first_name] = name
  end
  alias_method :firstname=, :first_name=

  # getter
  def middle_name
    self[:middle_name]
  end
  alias_method :middlename, :middle_name
  
  # setter
  def middle_name=(name)
    self[:middle_name] = name
  end
  alias_method :middlename=, :middle_name=

  # getter
  def last_name
    self[:last_name]
  end
  alias_method :lastname, :last_name
  
  # setter
  def last_name=(name)
    self[:last_name] = name
  end
  alias_method :lastname=, :last_name=

  # Returns 'f' for female and 'm' for male
  def gender
    self[:gender]
  end
  
  # gender setter
  def gender=(value)
    self[:gender] = case value.to_s.downcase
    when /^m/, /^male/ then "m"
    when /^f/, /^female/ then "f"
    end
  end

  # returns true if person is male
  def is_male?
    'm' == self.gender.to_s ? true : false
  end

  # makes this person male
  def is_male!
    self.gender = 'm'
  end
  
  # is this person female?
  def is_female?
    'f' == self.gender.to_s ? true : false
  end

  # make this user female
  def is_female!
    self.gender = 'f'
  end

  # creates a name string of academic_title, first_name, middle_name, and last_name
  # 
  # academic_title is optional if :title => true
  # middle_name is printed unless :middle => false
  #
  # e.g. given a person with academic title, first-, middle- and last name
  #
  #   Dr. Adam B. Smith   # -> :title => true
  #   Adam B. Smith       # -> no options
  #   Adam Smith          # -> :middle => false
  #
  def name(options={})
    defaults = {:title => false, :middle => true}
    options = defaults.merge(options).symbolize_keys
    
    result = []
    result << self.academic_title.to_s if options[:title] && self.academic_title
    result << self.first_name
    result << self.middle_name if options[:middle]
    result << self.last_name
    result.compact.map {|m| m.to_s.strip}.reject {|i| i.empty?}.join(' ')
  end

  # only return username if this person is not a friend, otherwise, returns name
  #
  # e.g.
  # 
  #   @person.username_or_name  ->   Adam Smith
  #   @person.username_or_name  ->   adam_smith (for show_name == false)
  #
  def username_or_name
    self.show_name? ? self.name : self.user.login
  end
  
  # only return username if this person is not a friend, otherwise, returns title and name
  def username_or_title_and_name
    self.show_name? ? self.title_and_name : self.user.login
  end

  # helper for show_name attribute, show_name? by default returns true
  def show_name?
    !!self[:show_name]
  end
  
  # dummy, used in case/create find person name
  #
  # TODO find a heuristic to split the name string and predict which part is first,
  # and which part is last name
  def name=(a_name)
  end
  
  # returns a email formatted with name
  #
  # e.g.
  #
  #   Dan Nye <dan_n.yahoo.com>
  #   dan_n.yahoo.com
  #
  def name_and_email
    self.name.blank? ? self.email : "#{self.name} <#{self.email}>"
  end

  # returns the name if available, otherwise, the email address
  # this is used in invitations, where the invitee does only have email.
  def name_or_email
    self.name.blank? ? self.email : self.name
  end
  
  # When prefers_casual is set to true, the name is abreviated to the first
  # name only, otherwise, the more formal name, full name, is used.
  #
  # e.g.
  #
  #   "Adam" vs. "Sir Adam Smith"
  #   "Adam" vs. "Otto Walkes"
  #
  def casualize_name(casual=nil)
    if casual == true
      self.first_name
    elsif casual == false
      self.name(:title => true)
    elsif !casual && self.prefers_casual?
      self.first_name
    else
      self.name(:title => true)
    end
  end

  # returns the !untranslated! salutation 
  #
  # e.g.
  #
  #   Prof Dr.
  #   Sir
  #   Ms
  #   Mr
  #
  def salutation
    if self.academic_title
      return self.academic_title.english_name
    else
      if self.gender == 'm'
        return SHORT_SALUTATION_MALE
      elsif self.gender == 'f'
        return SHORT_SALUTATION_FEMALE
      end
    end
  end
  
  # returns the translated salutation
  #
  # e.g.
  #
  #   Prof Dr.
  #   Herr     # -> for Mr
  #   Frau     # -> for Ms  
  #
  def salutation_t
    if self.academic_title
      self.academic_title.name
    else
      if self.gender == 'm'
        return "Mr".tn(:salutation)
      elsif self.gender == 'f'
        return "Ms".tn(:salutation)
      end
    end
  end

  # returns !untranslated! saluation and name depending on gender / academic_title
  #
  # e.g.
  #
  #   Prof. Dr. Ronald T. McCain
  #   Ms Ann Smith
  #
  def salutation_and_name(options={})
    result = []
    result << self.salutation if salutation
    result << self.name(options)
    result.compact.map {|m| m.to_s.strip}.reject {|i| i.empty?}.join(' ')
  end
  
  # returns TRANSLATED saluation and name depending on gender / academic_title
  def salutation_and_name_t(options={})
    result = []
    result << self.salutation_t if salutation
    result << self.name(options)
    result.compact.map {|m| m.to_s.strip}.reject {|i| i.empty?}.join(' ')
  end
  alias_method :salutation_and_name_display, :salutation_and_name_t

  # returns title with name (if exists), first and last name
  #
  # e.g.
  #
  #   "Prof. Dr. Adam Smith"
  #   "Adam Smith"
  #
  def title_and_name
    self.name({:title => true, :middle => false})
  end
  alias_method :title_and_name_t, :title_and_name

  # returns title (if exists) with first, middle, and last name 
  #
  # e.g.
  #
  #   "Prof. Dr. Adam K. Smith"
  #   "Adam K. Smith"
  #
  def title_and_full_name
    self.name({:title => true, :middle => true})
  end
  alias_method :title_and_full_name_t, :title_and_full_name

  # either show the login username or the full name with title based on show name
  def username_or_title_and_full_name
    self.show_name? ? self.title_and_full_name : self.user.login
  end

  # returns !untranslated! salutation and name or
  # just the first name depending on casual or prefers_casual?
  #
  # e.g.
  #
  #   Adam
  #   Prof. Dr. Adam R. Smith
  #   Mr Rob Smith
  #
  def casualize_salutation_and_name(casual=nil, options={})
    if casual == true
      self.first_name
    elsif casual == false
      self.salutation_and_name(options)
    elsif !casual && self.prefers_casual?
      self.first_name
    else
      self.salutation_and_name(options)
    end
  end

  # dito, but TRANSLATED
  def casualize_salutation_and_name_t(casual=nil, options={})
    if casual == true
      self.first_name
    elsif casual == false
      self.salutation_and_name_t(options)
    elsif !casual && self.prefers_casual?
      self.first_name
    else
      self.salutation_and_name_t(options)
    end
  end
    
  # Custom Validators
  def validate
    validates_url(:home_page_url, self.home_page_url) unless String(self.home_page_url).empty?
    validates_url(:blog_url, self.blog_url) unless String(self.blog_url).empty?
    validate_tax_code
  end
  
  def validate_tax_code
    if !self.tax_code.to_s.empty? && (self.partner? || self.registering_partner?) &&
        !LocalizedTaxSelect::localized_taxes_array(self.default_country).empty?
      errors.add(:tax_code, "invalid, check examples %{example}".t  % {
        :example => self.tax_code_example
      }) unless self.tax_code =~ self.tax_code_regexp
    end
  end
  
  # builds a regexp based on the person tax region
  def tax_code_regexp
    @tax_code_regexp_cache ||= Utility.tax_regexp(self.default_country)
  end
  
  # returns a string of tax id examples with abbreviated tax names
  #
  # e.g.
  #
  #   000-00-0000 for SSN or 99-0000000 for TIN
  #
  def tax_code_example
    Utility.tax_example_in_words(self.default_country)
  end
  
  # URL validator
  def validates_url(attrib_name, url_value)
    begin
      uri = URI.parse(url_value)
      raise unless [URI::HTTP, URI::HTTPS, URI::Generic].include?(uri.class)
#      Net::HTTP.get( url_value, '/' )
    rescue URI::InvalidURIError
      errors.add( attrib_name.to_sym, "invalid URL format".t )
    rescue Exception => e
      errors.add( attrib_name.to_sym, "invalid URL address".t )
    end
  end

  # overrides from acts_as_addressable, used when creating the order,
  # used in Order class
  def find_billing_address_or_clone_from(from_address, options={})
    find_or_clone_address(:billing, from_address, {
      :first_name => self.first_name,
      :last_name => self.last_name
    }.merge(options))
  end

  # copies first_name, middle_name, last_name, academic_title, gender
  # to billing address
  def build_billing_address_with_copy(attributes={})
    build_billing_address_without_copy({
      :first_name => self.first_name,
      :middle_name => self.first_name,
      :last_name => self.last_name,
      :gender => self.gender,
      :academic_title => self.academic_title
    }.merge(attributes))
  end
  # alias_method_chain :build_billing_address, :copy

  # overrides acts_as_addressable
  # builds default billing address or fills default parameters,
  # unless there is a billing address
  def find_or_build_billing_address(options={})
    return self.build_billing_address({
      :academic_title_id => self.academic_title ? self.academic_title_id : nil,
      :gender => self.gender,
      :first_name => self.first_name,
      :last_name => self.last_name,
      :country_code => (self.business_address || self.personal_address).country_code,
      :country => (self.business_address || self.personal_address).country,
      :province_code => (self.business_address || self.personal_address).province_code,
      :province => (self.business_address || self.personal_address).province,
    }.merge((self.business_address || self.personal_address).content_attributes)) unless self.billing_address
    self.billing_address
  end

  # purchases the given purchasable items with the payment object, see purchase_and_authorize.
  # if a purchasable is a partner subscription and the transaction is valid, this person
  # will automatically be upgraded to a partner.
  def purchase_and_pay(cart_or_purchasables, a_payment_object, payment_options={})
    order, payment = purchase_and_authorize(cart_or_purchasables, a_payment_object, payment_options)
    if order && payment.success?
      transaction do 
        payment = order.capture(payment_options)
        if payment.success?
          order.line_items.each do |line_item|
            purchasable = line_item.sellable.product
            if purchasable.is_a?(Voucher)
              purchasable.redeem!(false)
            elsif purchasable.is_a?(Product)
              if purchasable.is_partner_subscription?
                self.add_as_subscribable(purchasable)
              elsif purchasable.is_purchasing_credit?
                self.piggy_bank.direct_deposit(line_item.net_total)
              end
            end
          end
        end
      end
    end
    return order, payment
  end

  # creates order and authorizes the payment using
  # the given payment object.
  # takes a cart or purchasable items like a product or cart line items
  # returns order and payment object (see merchant sidekick)
  def purchase_and_authorize(cart_or_purchasables, a_payment_object, payment_options={})
    order, payment = nil, nil
    self.payment_object = a_payment_object
    purchase_items = []
    
    if cart_or_purchasables.is_a?(Cart)
      purchase_items = cart_or_purchasables.line_items
    else
      [cart_or_purchasables].flatten.each {|p| purchase_items << self.cart.cart_line_item(p)}
    end

    unless purchase_items.compact.empty?
      order = self.purchase(purchase_items)
      payment = order.authorize(self.payment_object, payment_options)
    end
    return order, payment
  end

  # returns a 3 month partner membership product for this person
  def three_month_partner_membership
    Product.three_month_partner_membership(:language_code => self.default_language,
      :country_code => self.default_country)
  end

  # returns a 12 month partner membership product for this person
  def two_year_partner_membership
    Product.two_year_partner_membership(:language_code => self.default_language,
      :country_code => self.default_country)
  end

  # returns true if this person has been registered
  def active?
    self.member? || self.partner?
  end

  # set the permalink attribute so we know the permalink
  # has changed by the user. generally, we allow the permalink
  # to be changed only once.
  def permalink=(new_permalink)
    self.permalink_change = true
    self[:permalink] = new_permalink
  end

  # returns true if the objec has been geo coded with lat/lng attributes
  def geo_coded?
    !!(self.lat && self.lng)
  end

  # returns a GeoKit::GeoLoc location instance based on the person's location information
  def geo_location
    if self.personal_address || self.business_address
      loc = Location.build_from(self.partner? ? self.business_address : self.personal_address)
      res = GeoKit::GeoLoc.new(loc.geokit_attributes)
      res.success = !!(res.lat && res.lng)
      res
    end
  end

  # returns true if geo location has changed, therefore, the object is stale
  # and must be updated on Address after_save 
  def geo_location_changed?
    self.changed.include?("lat") || self.changed.include?("lng")
  end

  # makes sure that we store the protocol, if not, we will add http://... by default
  def home_page_url=(page)
    unless page.blank?
      uri = URI.parse(page)
      if [URI::HTTP, URI::HTTPS].include?(uri.class)
        self[:home_page_url] = page
      else
        self[:home_page_url] = "http://#{page}"
      end
    end
  rescue URI::InvalidURIError => ex
    logger.error "Exception #{ex.message} caught when assigning home_page_url #{page}"
    self[:home_page_url] = nil
  end

  # makes sure that we store the protocol, if not, we will add http://... by default
  def blog_url=(page)
    unless page.blank?
      uri = URI.parse(page)
      if [URI::HTTP, URI::HTTPS].include?(uri.class)
        self[:blog_url] = page
      else
        self[:blog_url] = "http://#{page}"
      end
    end
  rescue URI::InvalidURIError => ex
    logger.error "Exception #{ex.message} caught when assigning blog_url #{page}"
    self[:blog_url] = nil
  end
  
  # makes sure that empty strings convert to nil
  def twitter_name=(name)
    self[:twitter_name] = name.blank? ? nil : name
  end
  
  # returns the full twitter url to this person's twitter account
  def twitter_url
    "http://twitter.com/#{self.twitter_name}" if self.twitter_name
  end
  
  # used to determine user id for flaggable
  def user_id
    self.user.id if self.user
  end
  
  # builds email to send info to user
  def build_email(options={})
    Email.new({
      :sender => self
    }.merge(options))
  end

  # returns kases count either from counter cache or through count query
  def kases_count(sweep_cache=false)
    if self.class.kases_count_column?
      @kases_count_cache = nil if sweep_cache
      @kases_count_cache ||= self[:kases_count] && !sweep_cache ? self[:kases_count] : self.kases.count("kases.id", Kase.find_options_for_visible({:distinct => true}))
    else
      @kases_count_cache ||= self.kases.count("kases.id", Kase.find_options_for_visible({:distinct => true}))
    end
  end

  # updates kases count counter
  def update_kases_count
    if self.class.kases_count_column?
      self.update_attribute(:kases_count, 
        self[:kases_count] = self.kases_count(true))
      self[:kases_count]
    end
  end

  # returns responses count either from counter cache or through count query
  def responses_count(sweep_cache=false)
    if self.class.responses_count_column?
      @responses_count_cache = nil if sweep_cache
      @responses_count_cache ||= self[:responses_count] && !sweep_cache ? self[:responses_count] : self.responses.count("responses.id", Response.find_options_for_visible({:distinct => true}))
    else
      @responses_count_cache ||= self.responses.count("responses.id", Response.find_options_for_visible({:distinct => true}))
    end
  end

  # updates responses count counter
  def update_responses_count
    if self.class.responses_count_column?
      self.update_attribute(:responses_count, 
        self[:responses_count] = self.responses_count(true))
      self[:responses_count]
    end
  end

  # returns votes received count either from counter cache or through count query
  def received_votes_count(sweep_cache=false)
    if self.class.received_votes_count_column?
      @received_votes_count_cache = nil if sweep_cache
      @received_votes_count_cache ||= self[:received_votes_count] && !sweep_cache ? self[:received_votes_count] : self.received_votes.count("votes.id", {:distinct => true})
    else
      @received_votes_count_cache ||= self.received_votes.count("votes.id", {:distinct => true})
    end
  end

  # returns up votes received count either from counter cache or through count query
  def received_up_votes_count(sweep_cache=false)
    if self.class.received_up_votes_count_column?
      @received_up_votes_count_cache = nil if sweep_cache
      @received_up_votes_count_cache ||= self[:received_up_votes_count] && !sweep_cache ? self[:received_up_votes_count] : self.received_up_votes.count("votes.id", {:distinct => true})
    else
      @received_up_votes_count_cache ||= self.received_up_votes.count("votes.id", {:distinct => true})
    end
  end

  # returns down votes received count either from counter cache or through count query
  def received_down_votes_count(sweep_cache=false)
    if self.class.received_down_votes_count_column?
      @received_down_votes_count_cache = nil if sweep_cache
      @received_down_votes_count_cache ||= self[:received_down_votes_count] && !sweep_cache ? self[:received_down_votes_count] : self.received_down_votes.count("votes.id", {:distinct => true})
    else
      @received_down_votes_count_cache ||= self.received_down_votes.count("votes.id", {:distinct => true})
    end
  end

  # updates all received vote cache
  def update_received_votes_cache
    ua = {}
    ua[:received_votes_count] = self.received_votes_count(true) if self.class.received_votes_count_column?
    ua[:received_up_votes_count] = self.received_up_votes_count(true) if self.class.received_up_votes_count_column?
    ua[:received_down_votes_count] = self.received_down_votes_count(true) if self.class.received_down_votes_count_column?
    self.update_attributes(ua)
  end

  # intercept globalized summary to return any localized column content as default
  #
  # e.g. 
  #
  # on locale "en-US" with self[:summary_es] == "Chico bueno!" and self[:summary] = nil, we return
  #  "Chico bueno!"
  #
  def summary_with_any_as_default
    summary_without_any_as_default || self.class.localized_facets_without_base(:summary).map {|m| send(m)}.compact.first
  end
  alias_method_chain :summary, :any_as_default

  # transfer piggy bank funds from one person to another person's or tier's account
  def transfer_funds_to(receiver, amount, options={})
    self.piggy_bank.transfer(receiver.piggy_bank, amount, options)
  end
  
  # does this person have the right to vote content up, depending on reputation points
  def can_vote_up?
    self.reputation_points >= Reputation::Threshold.vote_up # e.g. 15
  end
  
  # does this person have the right to vote content down, depending on reputation points
  def can_vote_down?
    self.reputation_points >= Reputation::Threshold.vote_down # e.g. 100
  end

  # extends clone and copies assocations
  def clone
    record = super

    # clone personal address
    if self.personal_address
      record.build_personal_address
      record.personal_address.attributes = self.personal_address.attributes
    end
    
    # clone personal address
    if self.business_address
      record.build_business_address
      record.business_address.attributes = self.business_address.attributes
    end
    
    # clone billing address
    if self.business_address
      record.build_billing_address
      record.billing_address.attributes = self.billing_address.attributes
    end
    
    record
  end

  # make sure unquiness for name validation is skipped on validate
  def skip_uniqueness_validation!
    @skip_uniqueness_validation = true
  end
  
  # returns true if uniqueness for name should be skipped, set with @record.skip_uniqueness_validation!
  def skip_uniqueness_validation?
    !!@skip_uniqueness_validation
  end
  
  # total reputation points of this person or if valid tier is given, the collected
  # reputation for the given tier. Reputation is global global tier reputation, 
  # e.g. person's reputation for luleka, is luleka(WW), luleka(DE), luleka(US)
  def reputation_points(tier=nil)
    if tier
      tier = tier.parent ? tier.parent : tier
      @cached_tier_reputation_points ||= {}
      @cached_tier_reputation_points["#{tier.site_name}"] ||= Reputation.sum(:points, 
        :conditions => {:receiver_id => self.id, :tier_id => tier.id, :status => "active"})
    else
      # contents of the reputation count cache column
      self[:reputation_points]
    end
  end 
  
  # clears the cache in case we need to clear it from another instance, e.g. @reputation
  def clear_reputation_points_cache(tier=nil)
    @cached_tier_reputation_points ||= {}
    tier ? @cached_tier_reputation_points.delete(tier.site_name) : @cached_tier_reputation_points = {}
  end

  protected
  
  # make sure we normalize slug correctly
  def normalize_friendly_id(slug_string)
    return super if self.default_language ? self.default_language == "en" : I18n.locale_language == :en
    options = friendly_id_config.babosa_options
    language = Utility.english_language_name(self.default_language || I18n.locale_language) || :english
    slug_string.normalize! options.merge(:transliterations => "#{language}".underscore.to_sym)
  end
  
end
