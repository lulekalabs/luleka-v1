# Kases are cases, but due to Ruby language naming conflicts (case statement),
# cannot start with 'c'.
# Kases are either questions, problems, praises, or ideas
class Kase < ActiveRecord::Base
  include QueryBase
  include InlineAuthenticationBase
  include ActionView::Helpers::DateHelper
  
  #--- constants
  ALL_ID = "all"

  #--- attributes
  attr_protected :status, :price

  #--- associations
  belongs_to :person           # author, owner
  belongs_to :severity
  has_many :responses, :dependent => :destroy,
    :order => "responses.created_at ASC"
  has_many :rewards, :dependent => :destroy,
    :order => "rewards.created_at ASC"
  has_many :assets, :as => :assetable, :dependent => :destroy
  has_many :comments, :as => :commentable, :dependent => :destroy
  has_many :clarifications, :as => :commentable, :dependent => :destroy,
    :order => 'parent_id ASC, created_at ASC'
  has_many :clarification_requests, :as => :commentable,
    :order => 'parent_id ASC, created_at ASC'
  has_many :clarification_responses, :as => :commentable,
    :order => 'parent_id ASC, created_at ASC'
  has_many :kontexts
  has_many :tiers,
    :through => :kontexts,
    :source => :tier,
    :foreign_key => :tier_id,
    :class_name => 'Tier'
  has_many :organizations,
    :through => :kontexts,
    :source => :tier,
    :foreign_key => :tier_id,
    :class_name => 'Organization'
  has_many :topics,
    :through => :kontexts,
    :source => :topic,
    :foreign_key => :topic_id,
    :class_name => 'Topic'
  has_many :products,
    :through => :kontexts,
    :source => :topic,
    :foreign_key => :topic_id,
    :class_name => 'Product'
  has_many :locations,
    :through => :kontexts,
    :source => :location,
    :foreign_key => :location_id,
    :class_name => 'Location'
  has_many :cart_line_items, :as => :product, :dependent => :destroy
  has_many :participants,
    :class_name => 'Person',
    :order => 'kases.updated_at, responses.updated_at DESC, comments.updated_at DESC',
    :finder_sql => 'SELECT DISTINCT people.* FROM people ' +
      'LEFT OUTER JOIN kases ON kases.person_id = people.id ' +
      'LEFT OUTER JOIN responses ON responses.person_id = people.id ' +
      'LEFT OUTER JOIN comments kase_comments ON kase_comments.sender_id = people.id ' + 
      'LEFT OUTER JOIN comments response_comments ON response_comments.sender_id = people.id ' +
      'WHERE kases.id = #{id} OR responses.kase_id = #{id} ' +
      '  OR (kase_comments.commentable_id = #{id} AND kase_comments.commentable_type = \'Kase\') ' +
      '  OR (response_comments.commentable_id = responses.id AND responses.kase_id = #{id} ' +
      '    AND response_comments.commentable_type = \'Response\') '

  #--- validations
  validates_presence_of :title, :description
  validates_length_of :title, :within => 5..120
  validates_length_of :description, :within => 15..2000
  validates_presence_of :sender_email, :unless => :person?
  validates_email_format_of :sender_email, :unless => :person?

  #--- mixins
  money :price, :cents => :price_cents, :currency => :currency
  acts_as_taggable :emotions, :filter_class => 'BadWord'
  acts_as_authorizable
  acts_as_visitable
  acts_as_voteable
  acts_as_mappable :default_units => :kms
  acts_as_followable
  has_friendly_id :title, 
    :use_slug => true,
    :cache_column => :permalink,
    :approximate_ascii => true
  can_be_flagged :reasons => [:privacy, :inappropriate, :abuse, :crass_commercialism, :spam]

  #--- named_scope
  named_scope :created, :select => "DISTINCT kases.*", 
    :conditions => ["kases.status IN(?)", ['created']]
  named_scope :open, :select => "DISTINCT kases.*", 
    :conditions => ["kases.status IN(?)", ['open']]
  named_scope :active, :select => "DISTINCT kases.*", 
    :conditions => ["kases.status NOT IN(?)", ['created', 'deleted', 'suspended']]
  named_scope :most_active, :select => "DISTINCT kases.*", :order => "kases.updated_at DESC",
    :conditions => ["kases.status NOT IN(?)", ['created', 'deleted', 'suspended']]
  named_scope :least_active, :select => "DISTINCT kases.*", :order => "kases.updated_at ASC",
    :conditions => ["kases.status NOT IN(?)", ['created', 'deleted', 'suspended']]
  named_scope :most_recent, :select => "DISTINCT kases.*", :order => "kases.created_at DESC",
    :conditions => ["kases.status NOT IN(?)", ['created', 'deleted', 'suspended']]
  named_scope :least_recent, :select => "DISTINCT kases.*", :order => "kases.created_at DESC",
    :conditions => ["kases.status NOT IN(?)", ['created', 'deleted', 'suspended']]
  named_scope :current_locale_first, :order => "kases.country_code = '#{Utility.country_code}', " +
    "kases.language_code = '#{Utility.language_code}'"
  named_scope :current_language_first, :order => "kases.language_code = '#{Utility.language_code}'"
  named_scope :current_country_first, :order => "kases.country_code = '#{Utility.country_code}'"

  #--- state machine
  acts_as_state_machine :initial => :created, :column => :status
  state :created
  state :open, :enter => :do_open, :after => :after_open
  state :resolved, :enter => :do_resolve
  state :closed, :enter => :do_close
  state :suspended, :enter => :do_suspend, :exit => :do_unsuspend, :after => :after_suspended
  state :deleted, :enter => :do_delete, :after => :after_deleted

  event :activate do
    transitions :from => :created, :to => :open, :guard => :can_activate?
  end

  event :solve do
    transitions :from => :open, :to => :resolved
  end
  
  event :cancel do
    transitions :from => [:created, :open], :to => :closed
  end

  event :suspend do
    transitions :from => [:created, :open, :resolved, :closed], :to => :suspended
  end
  
  event :delete do
    transitions :from => [:created, :open, :resolved, :closed, :suspended], :to => :deleted
  end

  event :unsuspend do
    transitions :from => :suspended, :to => :closed,
      :guard => Proc.new {|k| !k.closed_at.blank?}
    transitions :from => :suspended, :to => :resolved,
      :guard => Proc.new {|k| !k.resolved_at.blank?}
    transitions :from => :suspended, :to => :open,
      :guard => Proc.new {|k| !k.opened_at.blank? && k.has_not_expired?}
    transitions :from => :suspended, :to => :closed,
      :guard => Proc.new {|k| !k.opened_at.blank? && k.has_expired?}
  end

  #--- callbacks
  after_save :save_tier, :save_topics, :save_products, :save_location
  before_validation_on_create :reset_attributes
  before_create :convert_happened_at_to_utc, :create_and_send_activation_code
  after_create :update_associated_count
  
  #--- class methods
  class << self

    def finder_name
      :find_by_permalink
    end
    
    def finder_options
      {:include => [:tiers, :person]}
    end

    # override from active record ext
    def content_column_names
      content_columns.map(&:name) - %w(updated_at created_at resolved_at closed_at suspended_at
        deleted_at expires_at started_at auctioned_at happened_at opened_at
        comments_count visits_count status)
    end
    
    # returns all param_ids as array
    #
    # e.g.
    #
    #   [:question_id, :problem_id, :praise_id, :idea_id]
    #
    def subclass_param_ids
      subclasses.map {|k| "#{k.name.underscore}_id"}.map(&:to_sym)
    end
    
    # returns self and subclass param_ids
    def self_and_subclass_param_ids
      subclass_param_ids.insert(0, self_param_id)
    end
    
    def self_and_subclasses
      [self] + subclasses
    end
    
    # returns the param id, e.g. :tier_id
    def self_param_id
      "#{name.underscore}_id".to_sym
    end
    
    # infers the controller name from class name
    def controller_name
      self.name.underscore.pluralize
    end
    
    # type casts to the class specified in :type parameter
    #
    # E.g.
    #
    #   d = Kase.new(:type => :idea)
    #   d.kind == :idea  # -> true
    #   Kase.new(:type => "Problem") ->  Problem
    #
    def new_with_cast(*a, &b)  
      if (h = a.first).is_a? Hash and (type = h[:type] || h['type']) and 
        (k = type.class == Class ? type : (type.class == Symbol ? klass(type): type.constantize)) != self
        raise "type not descendent of Kase" unless k < self  # klass should be a descendant of us  
        return k.new(*a, &b)  
      end  
      new_without_cast(*a, &b)  
    end  
    alias_method_chain :new, :cast

    # finds a kase class by kind/type, e.g. Kase.klass(:idea) -> Idea
    def klass(a_kind=nil)
      ordered_subclasses.each do |sc|
        return sc if !a_kind.blank? && sc.kind == a_kind.to_sym
      end
      Kase
    end

    # make subclasses method public
    public :subclasses

    # subclasses in logical order
    def ordered_subclasses
      [Question, Idea, Problem, Praise]
    end
    
    # is subclassed in Problem, Question, etc. and returns a symbol of
    # type :kase, :problem, :question, etc.
    def kind
      # returns nil, overridden and returning :question, :problem, etc. in sublcass
    end

    def human_headline
      raise "Define in subclass, e.g. 'What makes the world go round?'"
    end
    
    # finds template for current language
    def find_template_by_language(language_code=Utility.language_code)
      find(:first, :conditions => ["kases.template = ? AND kases.language_code = ?", true, language_code])
    end
    
    # overrides default finder and makes sure only active users are returned
    def find_by_permalink(permalink, options={})
      find(permalink, find_options_for_visible(options))
=begin      
      unless result = find(:first, find_options_for_find_by_permalink(permalink))
        raise ActiveRecord::RecordNotFound, "Couldn't find #{name} with ID=#{permalink}"
      end
      result.friendly_id_status.name = permalink if result
      result
=end      
    end
    
    # find options for permalink
    def find_options_for_find_by_permalink(permalink, options={})
      {:conditions => ["kases.permalink = ?", permalink]}.merge_finder_options(options.merge_finder_options(
        Kase.find_options_for_visible))
    end
    
    # returns an array of ids by conditions
    def find_all_ids(options={})
      find(:all, options.merge({:select => 'id'})).map(&:id) 
    end
    
    # find options to include kase types
    def find_options_for_type(options={})
      {:conditions => ["kases.type IN (?)", self_and_subclasses.map(&:name)]}.merge_finder_options(options)
    end

    # find options for active kases ordered by the most recent kase updated first
    # resembles the "active?" instance method, returns records for states NOT in:
    #
    #   * created
    #   * suspended
    #   * deleted
    #   * closed
    #   * resolved
    #
    def find_options_for_active(options={})
      {:conditions => ["kases.status NOT IN (?)", ["created", "suspended", "deleted", "closed", "resolved"]],
        :order => "kases.updated_at DESC"}.merge_finder_options(options)
    end

    # find options for active kases ordered by the most recent kase updated first
    # resembles the "active?" instance method, returns records for states NOT in:
    #
    #   * created
    #   * suspended
    #   * deleted
    #   * closed
    #   * resolved
    #
    def find_options_for_recent(options={})
      {:conditions => ["kases.status NOT IN (?)", ["created", "suspended", "deleted", "closed", "resolved"]],
        :order => "kases.updated_at DESC"}.merge_finder_options(options)
    end

    # returns all visible kases
    def find_all_visible(options={})
      find(:all, find_options_for_visible(options))
    end

    # find options for "visible" kases, terms of "einsehbar"
    # resembles "visible?" instance method, returns records for states NOT in:
    #
    #   * created
    #   * suspended
    #   * deleted
    #
    def find_options_for_visible(options={})
      {:conditions => ["kases.status NOT IN (?) AND kases.template != ?", ["created", "suspended", "deleted"], true],
        :order => "kases.updated_at DESC"}.merge_finder_options(options)
    end

    # find options for "living" kases, terms of alive
    # resembles "alive?" instance method, returns records for states NOT in:
    #
    #   * suspended
    #   * deleted
    #   * closed
    #
    def find_options_for_alive(options={})
      {:conditions => ["kases.status NOT IN (?) AND kases.template != ?", ["suspended", "deleted", "closed"], true],
        :order => "kases.updated_at DESC"}.merge_finder_options(options)
    end

    # find options for open kases ordered by the most recent kase updated first
    def find_options_for_open(options={})
      {:conditions => ["kases.status IN (?) AND kases.template != ?", ["open"], true],
        :order => "kases.updated_at DESC"}.merge_finder_options(options)
    end
    
    # find options for open kases that are rewarded $$$, ordered by the most recent kase updated first
    def find_options_for_open_rewarded(options={})
      {:conditions => ["kases.status IN (?) AND kases.price_cents > 0 AND kases.template != ?", ["open"], true],
        :order => "kases.updated_at DESC"}.merge_finder_options(options)
    end

    # find options for popular kases, order by most to least popular
    def find_options_for_popular(options={})
      if votes_sum_column?
        {
          :conditions => find_options_for_alive[:conditions],
          :order => "kases.followers_count DESC, kases.votes_sum DESC, kases.responses_count DESC, kases.views_count DESC"
        }.merge_finder_options(options)
      else
        {
          :select => "kases.*, SUM(COALESCE(votes.vote, 0)) AS summarized",
          :joins => "LEFT OUTER JOIN votes ON " +
            "votes.voteable_id = #{table_name}.#{primary_key} AND " + 
            "votes.voteable_type = '#{base_class.name}' ",
          :conditions => ["kases.status NOT IN (?) AND kases.template != ?", ["deleted", "suspended"], true],
          :order => "summarized DESC",
          :group => "#{table_name}.#{primary_key}"
        }.merge_finder_options(options)
      end
    end

    # find options for solved kases ordered by the most recent kase updated first
    def find_options_for_solved(options={})
      {:conditions => ["kases.status IN (?) AND kases.template != ?", ["solved"], true], 
        :order => "kases.updated_at DESC"}.merge_finder_options(options)
    end

    # returns true if a $$$ reward can be offered for this kase
    # overridden in problem and question
    def allows_reward?
      false
    end

    # returns an array of classes of kind Kase: Problem, Question, Praise, Idea
    def klasses
      [Problem, Question, Praise, Idea]
    end
    
    # updates only geo location columns with plane SQL
    def update_geo_location(record)
      result = Kase.connection.update("UPDATE #{table_name} " + 
        "SET #{table_name}.lng = #{record.lng ? sanitize_sql(record.lng) : 'NULL'}, " +
        "#{table_name}.lat = #{record.lat ? sanitize_sql(record.lat) : 'NULL'} " +
        "WHERE #{table_name}.id = #{sanitize_sql(record.id)}")
      result
    end

    # finds all featured kases
    def find_all_featured(options={})
      find(:all, find_options_for_featured_by_language_code(nil, options).merge({:include => :person}))
    end

    # finds all featured by language code
    def find_all_featured_by_language_code(language_code, options={})
      find(:all, find_options_for_featured_by_language_code(language_code, options).merge({:include => :person}))
    end
    
    # find first featured kase by random and language code
    def find_first_featured_by_random(options={})
      featured = find_all_featured(options)
      featured[rand(featured.size)]
    end
    
    # find first featured kase by random and language code
    def find_first_featured_by_random_and_language_code(language_code=nil, options={})
      featured = find_all_featured_by_language_code(language_code, options)
      featured[rand(featured.size)]
    end

    # find options for finding features kases
    def find_options_for_featured_by_language_code(language_code, options={})
      conditions = {:featured => true}
      conditions.merge!({:language_code => language_code}) if language_code
      {:conditions => conditions, :order => "kases.created_at DESC"}.merge(options)
    end

    # finds all expired kases
    def find_all_expired(options={})
      find(:all, find_options_for_expired(options))
    end

    def find_in_batches_options_for_expired(options={})
      find_options_for_expired.merge({:order => nil, :batch_size => 100})
    end
    
    def find_options_for_expired(options={})
      conditions =  sanitize_sql(["kases.status NOT IN (?)", ["closed", "deleted", "suspended"]])
      conditions << " AND "
      conditions << sanitize_sql(["kases.expires_at IS NOT NULL AND kases.expires_at < ?", Time.now.utc])
      {:conditions => conditions, :order => "kases.created_at DESC"}.merge_finder_options(options)
    end
    
    # finds all that have not been published
    def find_all_pending_publication
      find(:all, :conditions => ["kases.status = ? AND kases.published_at < ?", 
        'created', Time.now.utc - 30.days])
    end
    
    # overrides additional query find options from query base
    def find_class_options_for_query_with_and(query, options={})
      find_options_for_visible(options)
    end

    # overrides query columns from query base
    def find_by_query_columns
      ['title', 'description']
    end
    
    # find kases that match the given person's profile
    def find_matching_kases_for_person(person, options={})
      find(:all, find_options_for_matching_kases_for_person(person, options))
    end

    # find options for matching kases for given person:
    #
    #   * Person's have expertises matches kase tags or
    #   * Person's response tags with at least 2 positive votes matches kase tags
    #   * Person's spoken languages matches kase language
    #
    def find_options_for_matching_kases_for_person(person, options={})
      select = "DISTINCT kases.*"
      group = "#{table_name}.#{primary_key}"

      # kases tags
      joins = "LEFT OUTER JOIN taggings kases_taggings ON kases_taggings.taggable_id = kases.id AND kases_taggings.taggable_type = 'Kase' " + 
        "LEFT OUTER JOIN tags kases_tags ON kases_tags.id = kases_taggings.tag_id "

      # person's tags
      have_expertise_tags = "SELECT DISTINCT people_tags.name FROM tags AS people_tags " +
        "LEFT OUTER JOIN taggings people_taggings ON people_taggings.tag_id = people_tags.id " + 
          "WHERE people_taggings.taggable_id = #{person.id} AND people_taggings.taggable_type = 'Person' AND " +
            "people_taggings.context IN ('have_expertises')"

      responses_tags = "SELECT DISTINCT kases_tags.name FROM tags AS kases_tags " +
        "LEFT OUTER JOIN taggings kases_taggings ON kases_tags.id = kases_taggings.tag_id " +
          "LEFT OUTER JOIN kases ON kases_taggings.taggable_id = kases.id AND kases_taggings.taggable_type = 'Kase' " +
            "LEFT OUTER JOIN responses kases_responses ON kases_responses.kase_id = kases.id " +
              "WHERE kases_responses.person_id = #{person.id} AND kases_responses.votes_sum > 1"
              
      # combine have expertise and response tags
      conditions = "(kases_tags.name IN (#{have_expertise_tags}) OR kases_tags.name IN (#{responses_tags})) "

      # spoken languages
      person_spoken_language_codes = "SELECT spoken_languages.code FROM spoken_languages " +
        "LEFT OUTER JOIN people_spoken_languages ON people_spoken_languages.spoken_language_id = spoken_languages.id " +
          "WHERE people_spoken_languages.person_id = #{person.id}"
      conditions += "AND kases.language_code IN (#{person_spoken_language_codes})"

      {
        :select => select,
        :joins => joins,
        :group => group,
        :conditions => conditions
      }.merge_finder_options(find_options_for_visible(options))
    end

  end

  #--- instance methods

  # returns true if this case is NOT in either of
  # in terms of somebody can "do" something with it
  #
  #   * created
  #   * suspended
  #   * deleted
  #   * closed
  #   * resolved
  #
  def active?
    !(self.created? || self.suspended? || self.deleted? || self.closed? || self.resolved?)
  end

  # returns true if this case is NOT in either of
  # in terms of "einsehbar"
  #
  #   * created
  #   * suspended
  #   * deleted
  #
  def visible?
    !(self.created? || self.suspended? || self.deleted?)
  end
  
  # returns true if this case is NOT in either of
  # in terms of "post mortem"
  #
  #   * suspended
  #   * deleted
  #   * closed
  #
  def alive?
    !(self.closed? || self.suspended? || self.deleted?)
  end
  
  # returns true if 
  #
  #   * given person is the owner, or
  #   * has sufficient reputation points to edit
  #   * the kase is alive, states created, open, etc.
  #
  def editable?
    self.alive? || self.new_record?
  end

  # returns true if it can be edited by given person
  def can_be_edited_by?(editor, tier=nil)
    self.editable? && (editor == self.person || Reputation::Threshold.valid?(:edit_post, editor, :tier => tier))
  end
  
  # e.g. @kase.can_be_voted_up_by?(@person)
  def can_be_voted_up_by?(editor, tier=nil)
    self.alive? && Reputation::Threshold.valid?(:vote_up, editor, :tier => tier)
  end

  # dito
  def can_be_voted_down_by?(editor, tier=nil)
    self.alive? && Reputation::Threshold.valid?(:vote_down, editor, :tier => tier)
  end
  
  def can_be_adding_tag_by?(editor, tier=nil)
    self.alive? && (editor == self.person || Reputation::Threshold.valid?(:newtag_kase, editor, :tier => tier))
  end

  # if editor can add tags
  def can_be_retagged_by?(editor, tier=nil)
    self.alive? && (editor == self.person || Reputation::Threshold.valid?(:retag_kase, editor, :tier => tier))
  end

  # @kase.can_be_deleted_by? @person
  def can_be_deleted_by?(editor, tier=nil)
    editor == self.person || Reputation::Threshold.valid?(:moderate, editor, :tier => tier)
  end

  def can_be_closed_by?(editor, tier=nil)
    self.alive? && (editor == self.person || Reputation::Threshold.valid?(:moderate, editor, :tier => tier))
  end

  # if editor can add e.g. an image
  def can_be_adding_asset_by?(editor)
    !!editor && editor == self.person && self.alive?
  end
  
  # intercepted price getter
  # overrides money price getter, to add default currency
  def price_with_default
    self.currency.nil? ? Money.new(self.price_cents || 0, self.default_currency) : self.price_without_default
  end
  alias_method_chain :price, :default
  
  # builds a response
  #
  # e.g.
  #
  #   r = @kase.build_response(sender, :description => "I don't understand...")
  #   r.activate!
  #
  def build_response(sender, options={}, force=false)
    self.responses.build(response_options(sender, options)) if force || allows_response?(sender)
  end
  
  # creates a response on this kase
  def create_response(sender, options={}, force=false)
    response = nil
    if force || allows_response?(sender)
      response = self.responses.create(response_options(sender, options))
      response.activate! if response.valid?
    end
    response
  end

  # options for create/build response
  def response_options(sender, options={})
    options.merge({:person => sender, :kase => self})
  end
  
  # returns false if this kase cannot be responded to anymore
  def allows_response?(responder=nil)
    self.active? && self.open?
  end
  
  # same as allows response but requires a responder person instance
  def allows_response_by(responder)
    self.allows_response?(responder)
  end
  
  # builds a comment
  #
  # e.g.
  #
  #   c = build_comment(sender, :message => "I don't understand...")
  #   c.activate!
  #
  def build_comment(sender, options={})
    self.comments.build(comment_options(sender, options))
  end
  
  # creates a comment on this kase
  def create_comment(sender, options={})
    comment = self.comments.create(comment_options(sender, options))
    comment.activate! if comment.valid?
    comment
  end

  # options for create/build comment
  def comment_options(sender, options={})
    options.merge({:sender => sender, :receiver => self.person, :commentable => self})
  end
  
  # returns false if this kase cannot be commented
  def allows_comment?(a_person=nil)
    self.alive?
  end

  # ensure we return valid number for comments count
  def comments_count
    self[:comments_count] || 0
  end

  # builds a clarification request to this kase's owner from the person you supply
  # the request can then be replied to using the request's instance's build_reply
  # method.
  #
  # e.g.
  #
  #   c = create_clarification(sender, :message => "I don't understand...")
  #   c.activate!
  #
  def build_clarification(sender, options={})
    self.clarifications.build(clarification_options(sender, options))
  end
  
  # builds clarification request
  def build_clarification_request(sender, options={})
    build_clarification(sender, options.merge(:type => :clarification_request)) if self.allows_clarification_request?(sender)
  end

  # Creates a clarification request
  def create_clarification_request(sender, options={})
    if self.allows_clarification_request?(sender)
      request = self.clarifications.create(clarification_options(sender, options))
      @pending_clarification_request_cache = nil
      request.activate! if request.valid?
      request
    end
  end

  # builds clarification response
  def build_clarification_response(sender, options={})
    if self.allows_clarification_response?(sender) && request = self.pending_clarification_request
      request.build_reply(options)
    end
  end

  # create clarification response
  def create_clarification_response(sender, options={})
    if response = self.build_clarification_response(sender, options)
      if response.save
        @pending_clarification_request_cache = nil
        response.activate!
      end
    end
    response
  end
  
  # returns the latest pending clarification request
  def pending_clarification_request
    @pending_clarification_request_cache || @pending_clarification_request_cache = if self.pending_clarification_requests?
      self.clarification_requests.active.find(:all, :order => "id DESC, created_at DESC", :limit => 1)[0]
    else
      nil
    end
  end

  # options for create/build clarification
  def clarification_options(sender, options={})
    options.merge({:type => :clarification_request, :sender => sender, :receiver => self.person, 
      :clarifiable => self}.merge(options))
  end

  # returns true if
  #
  #   * not commentable
  #   * person to test is different than owner
  #   * open and no pending clarification requests
  #
  def allows_clarification_request?(a_person=nil)
    self.alive? && 
    (a_person ? self.person != a_person : false) && !self.pending_clarification_requests?
  end
  
  # Returns true if a request exists, the person is the case owner, etc.
  def allows_clarification_response?(a_person)
    self.alive? && self.pending_clarification_requests?
  end
  
  # Checks if there is a pending clarification request
  def pending_clarification_requests?
    self.clarification_requests_count > self.clarification_responses_count
  end
  
  # returns true if this case is past it's expiration date or false if this case does not expire
  def has_expired?
    self.expires_at ? self.expires_at < Time.now.utc : false
  end
  
  # Returns true if there is still time left to solve this case or true if this case does not expire
  def has_not_expired?
    self.expires_at ? self.expires_at > Time.now.utc : true
  end
  
  # is there still enough time left to solve this case within time_to_solve period?
  def has_time_to_solve?
    self.expires_at ? Time.now.utc + self.time_to_solve < self.expires_at : true
  end
  
  def has_not_enough_time_to_solve?
    self.expires_at ? Time.now.utc + self.time_to_solve > self.expires_at : false
  end

  # how much time does someone need to solve this kase?
  def time_to_solve
    1.hour
  end
  
  # any active or paid reward attached?
  def offers_reward?
    !self.rewards.visible.empty?
  end

  # true if there is one and only one visible reward offered by the kase owner
  def owner_only_offers_reward?
    self.rewards_count == 1 && self.rewards.visible[0].sender == self.person
  end

  # The owner is the one who created the case (issue)
  # TODO check if obsolete?
  def owner
    self.person
  end
  
  # TODO check if obsolete?
  def owner=(value)
    self.person = value if a_person
  end

  # The currency of the issue depends on the owner's default_currency
  def default_currency
    self.person ? self.person.default_currency : 'USD'
  end
  
  # is subclassed in Problem, Question, etc. and returns a symbol of
  # type :kase, :problem, :question, etc.
  def kind
    self.class.kind
  end

  #--- tier
  
  # assign a tier to the kase kontext
  def tier=(a_tier)
    if new_record?
      @tier_cache = a_tier
    else
      if @tier_cache
        self.kontexts.create(
          :kase => self,
          :tier => a_tier
        )
        @tier_cache = nil
      else
        if a_tier == nil
          self.kontexts.select {|k| k.tier || k.topic}.each {|k| k.destroy}
          self.tiers.reload
        elsif a_tier != self.tier
          self.kontexts.select {|k| k.tier || k.topic}.each {|k| k.destroy}
          self.kontexts.create(
            :kase => self,
            :tier => a_tier
          )
          self.tiers.reload
        end
      end
    end
    a_tier
  end

  # called after_save to assign and create the tier kontext for new kases
  def save_tier
    self.tier = @tier_cache if @tier_cache
  end
  
  # gets the assigned tier, nil if none
  def tier
    @tier_cache || self.tiers[0]
  end
  
  # returns true if there is a tier associated
  def tier?
    !!self.tier
  end

  # assigns tier by id
  def tier_id=(id)
    self.tier = Tier.find_by_id(id.to_i)
  end
  
  # gets tier by id
  def tier_id
    self.tier.id if self.tier
  end

  #--- organization

  def organization=(an_organization)
    self.tier = an_organization
  end

  # gets organization
  def organization
    self.tier if tier.is_a?(Organization)
  end
  
  # returns true if there is an organization associated
  def organization?
    self.tier? && self.tier.is_a?(Organization)
  end
  
  # assigns organization by id
  def organization_id=(id)
    self.organization = Organization.find_by_id(id.to_i)
  end
  
  # gets organization by id
  def organization_id
    self.organization.id if self.organization && self.organization.is_a?(Organization)
  end

  #--- topics
  
  # assigns topics to the root claiming
  def topic_ids=(ids)
    self.topics = Topic.active.find(:all, :conditions => ["id IN (?)", ids.map(&:to_i)])
  end

  # returns an array of assigned topic ids
  def topic_ids
    new_record? ? (@associated_topics_cache ? @associated_topics_cache.compact.map(&:id) : []) : self.topics.map(&:id)
  end

  # intercepts with the topics association and returns topics from instance
  # variable if new_record?
  def topics_with_cache
    if new_record?
      @associated_topics_cache || []
    else
      self.topics_without_cache
    end
  end
  alias_method_chain :topics, :cache
  
  # assign topics
  def topics=(some_topics)
    if new_record?
      @associated_topics_cache = some_topics
    else
      self.kontexts.reject {|k| !k.topic}.each {|p| p.destroy}
      some_topics.compact.each {|p| self.kontexts.create(
        :kase => self,
        :tier => self.organization,
        :topic => p
      )}
#      @associated_topics_cache = nil
      self.topics.reload
      some_topics
    end
  end

  # save topics after object has been saved
  def save_topics
    self.topics = @associated_topics_cache if @associated_topics_cache
  end

  #--- products

  # assigns products to the root claiming
  def product_ids=(ids)
    self.products = Product.find(:all, :conditions => ["id IN (?)", ids.map(&:to_i)])
  end

  # returns an array of assigned product ids
  def product_ids
    new_record? ? (@products_cache ? @products_cache.map(&:id) : []) : self.products.map(&:id)
  end

  # intercepts with the products association and returns products from instance
  # variable if new_record?
  def products_with_cache
    if new_record?
      @products_cache || []
    else
      self.products_without_cache
    end
  end
  alias_method_chain :products, :cache

  # assign products
  def products=(some_products)
    if new_record?
      @products_cache = some_products
    else
      self.kontexts.reject {|k| !k.topic}.each {|p| p.destroy}
      some_products.each {|p| self.kontexts.create(
        :kase => self,
        :tier => self.organization,
        :topic => p
      )}
      self.products.reload
      some_products
    end
  end

  # save products after object has been saved
  def save_products
    self.products = @products_cache if @products_cache
  end

  #--- location

  # assign a location using a kase kontext
  def location=(a_location)
    a_location = Location.build_from(a_location)

    if !a_location && (self.lng || self.lat)
      self.lng = self.lat = nil
    elsif a_location && (self.lng != a_location.lng || self.lat != a_location.lat)
      self.lng = a_location.lng
      self.lat = a_location.lat
    end

    if new_record?
      @location_cache = a_location
    else
      if @location_cache
        self.kontexts.create(
          :kase => self,
          :location => a_location
        ) if a_location
        @location_cache = false
      else 
        if a_location == nil
          self.kontexts.reject {|k| !k.location}.each {|k| k.destroy}
        elsif a_location != self.location
          self.kontexts.reject {|k| !k.location}.each {|k| k.destroy}
          self.kontexts.create(
            :kase => self,
            :location => a_location
          )
        end
      end
      self.update_geo_location if self.geo_location_changed?
    end
    a_location
  end

  # called after_save to assign and create the location kontext for new kases
  def save_location
    self.location = @location_cache if @location_cache || geo_location_changed?
  end
  
  # updates current lat/lng location in database columns, without validations
  def update_geo_location
    self.class.update_geo_location(self)
    self.reload
  end

  # gets the assigned location, nil if none
  def location
    @location_cache || self.locations[0]
  end
  
  # returns true if there is a location associated
  def location?
    !!self.location
  end

  # returns true if location can be edited by given person
  def can_edit_location?(editor=nil)
    editor ? self.person == editor : false
  end

  # returns true if the kase has a location associated or if the location can be edited
  # by the given person
  def has_or_can_edit_location?(editor=nil)
    self.location? || self.can_edit_location?(editor)
  end

  # returns true if a $$$ reward can be offered for this kase
  def allows_reward?
    self.class.allows_reward?
  end

  # returns the kase language code ('en', 'de', etc.) or
  # if empty the person's default language preference
  def language_code
    self[:language_code] || (self.person ? self.person.default_language : Utility.language_code)
  end
  
  # determines the language code for associated tags
  # intercepts from acts_as_taggable_type
  def tag_language_code_with_content
    self.language_code || self.tag_language_code_without_content 
  end
  alias_method_chain :tag_language_code, :content

  # overloads built-in expires_at setter and
  # makes sure that expiry_option is set to :on
  def expires_at=(value)
    self[:expires_at] = value
  end

  # converts the happened at from the user's time to utc
  def convert_happened_at_to_utc
    self[:happened_at] = self.person && self.person.user ? self.person.user.user2utc(self[:happened_at]) : self[:happened_at]
  end
  
  # returns a GeoKit::GeoLoc location instance based on the kase location
  def geo_location
    if loc = self.location
      res = GeoKit::GeoLoc.new(loc.geokit_attributes)
      res.success = !!(res.lat && res.lng)
      res
    end
  end
  
  # returns true if geo location has changed, therefore, the object is stale
  # and must be updated 
  def geo_location_changed?
    self.changed.include?("lat") || self.changed.include?("lng")
  end

  # returns true if the objec has been geo coded with lat/lng attributes
  def geo_coded?
    !!(self.lat && self.lng)
  end
  
  # returns the current kase state as string
  def current_state_s(new_state=nil)
    case state = new_state || self.current_state
    when :created then 'new'
    else "#{state}"
    end
  end

  # translates the current state
  def current_state_t(new_state=nil)
    self.current_state_s(new_state).t
  end
  
  # used to determine user id for flaggable
  def user_id
    self.person.user.id if self.person
  end

  # finds and returns all related kases to this one
  def find_matching_kases(options={})
    @find_matching_kases_cache ||= Kase.find_tagged_with(self.tags_on(:tags),
      (new_record? ? {} : {:conditions => ["kases.id <> ?", self.id]}.merge_finder_options(self.class.find_options_for_visible)).merge_finder_options(options))
  end
  
  # returns a list of people that are "qualified", "helpful" and match the kases tags
  # finds partners who's have_expertises matches this active kase's tags, except for this kase's owner
  #
  #  qualified, matching, related
  #
  def find_matching_people(options={})
    tags = self.tag_list.reject(&:blank?).uniq
    @find_matching_people_cache ||= Person.find_tagged_with(tags, {
      :conditions => ["people.id <> ?", self.person.id]
    }.merge_finder_options(options))
  end
  
  # returns partners that are qualified for this kase
  def find_matching_partners(options={})
    @find_matching_partners_cache ||= self.find_matching_people({
      :on => 'have_expertises'
    }.merge_finder_options(options.merge_finder_options(Person.find_options_for_partner_status)))
  end
  
  # builds email to share this kase with others
  def build_email_kase(options={})
    EmailKase.new({
      :kase => self,
      :subject => "%{name} wants to know what you think".t % {:name => self.person.casualize_name}
    }.merge(options))
  end
  
  # does sender's email and person's email match
  def person_match?
    (!self.sender_email && self.person? && self.person.user && !self.person.user.guest?) || 
      (self.sender_email && self.person && self.sender_email == self.person.email)
  end

  # returns true if this case is associated with a person
  def person?
    !!self.person
  end

  # updates kases count in various assocations
  def update_associated_count
    self.update_tier_kases_count
    self.update_topics_kases_count
    self.update_person_kases_count
  end
  
  # override from acts_as_voteable to update the person's received votes cache
  def update_voter_cache(voter, sweep_cache=false)
    voter.update_received_votes_cache if voter
  end
  
  # auto accept response under the following conditions:
  #
  #   * recently expired (expires) and have at least 1 responses
  #   * there is at least 1 reward that is not from the kase owner
  #   * select the top response that has at least 2 up votes, positive votes_sum and top votes_sum
  #
  def auto_accept_response!
    result = false
    if self.active? && self.has_expired? && self.responses_count >= 1 && 
        self.offers_reward? && !self.owner_only_offers_reward?
      top = self.responses.active.find(:all, :conditions => ["responses.up_votes_count >= 2 && responses.votes_sum >= 0"],
        :order => "responses.votes_sum ASC, responses.updated_at DESC", :limit => 2)
      result = top.first.accept! unless top.first.nil?
      self.responses.reload if result
    end
    result
  end
  
  # makes sure we close or resolve kases that do have rewards and expiration dates
  def expire!
    result = false
    self.auto_accept_response!
    if self.has_expired? && self.has_accepted_response?
      # Nothing to do, as response.accept! has set kase status to :resolved
      result = true
    elsif self.has_expired? && self.has_no_accepted_response?
      result = (true == self.cancel!)
    end
    self.reload if result
    result
  end
  
  # true for at least one accepted response
  def has_accepted_response?
    self.responses.accepted.any? {|response| response.accepted?}
  end

  # true for not having a single accepted response
  def has_no_accepted_response?
    !self.has_accepted_response?
  end
  
  # returns the maximum single rewarded amount in native reward currency
  # caches reward price, use sweep_max_... to sweep cache
  def max_reward_price
    @max_reward_price_cache ||= if self.offers_reward?
      result = Money.new(0, self.default_currency)
      self.rewards.visible.each {|reward| result = Money.max(result, reward.price)} # # .convert_to(self.default_currency)
      result
    end
  end

  # sweeps max reward price cache. should be called when new reward is activated/canceled
  def sweep_max_reward_price_cache
    @max_reward_price_cache = nil
  end

  # handles adding reputation based on up vote
  def repute_vote_up(voter)
    Reputation.handle(self, :vote_up, self.person, :sender => voter, :tier => self.tier)
  end

  def cancel_repute_vote_up(voter)
    Reputation.cancel(self, :vote_up, self.person, :sender => voter, :tier => self.tier)
  end

  def repute_vote_down(voter)
    Reputation.handle(self, :vote_down, self.person, :sender => voter, :validate_sender => false, :tier => self.tier)
  end

  def cancel_repute_vote_down(voter)
    Reputation.cancel(self, :vote_down, self.person, :sender => voter, :tier => self.tier)
  end

  # caches particiapnts
  def participants_count
    @participants_count ||= self.participants.to_a.size # self.participants.count("people.id", :distinct => true)
  end
  
  # cache employees
  def employees_count
    @employees_count ||= @employees.to_a.size
  end

  # helper for anonymous attribute
  def anonymous?
    !!self[:anonymous]
  end

  # returns true if there is an active reward from the same sender of this reward
  def active_reward_from?(person)
    !self.rewards.active.find(:all, :conditions => {:sender_id => person.id}).empty?
  end

  protected
  
  def validate
    # all
    self.errors.add(:base, "Select %{types}".t % {
      :types => Kase.klasses.map(&:human_name).to_sentence_with_or
    }) unless self.kind
    
    # activation email does not match person's email
    self.errors.add(:sender_email, I18n.t('activerecord.errors.messages.match_activation') % {
      :sender_email => self.sender_email,
      :registration_email => self.person.email
    }) if self.sender_email && self.person && self.sender_email != self.person.email
  end
  
  # called after create in state machine
  def reset_attributes
    self.attributes = {
      # reset time
      :opened_at => nil,
      :resolved_at => nil,
      :closed_at => nil, 
      :suspended_at => nil,
      :deleted_at => nil,
      # other
      :currency => self.person ? self.person.default_currency : nil,
      :price_cents => 0
    }
  end

  # checks, if the kase can be activated (state: open) and if the kase can be offered
  def can_activate?
    self.person && self.person_match? && self.has_not_expired?
  end

  def do_open
    update_attributes({
      :activation_code => nil,
      :sender_email => nil,
      :opened_at => Time.now.utc
    }.merge((self.opened_at ? {} : {:published_at => Time.now.utc}).merge(attributes)))
    
    send_new_post
  end

  # hit after the kase is activated and state has changed to open
  def after_open
    self.update_associated_count
  end

  def do_resolve
    update_attributes(:resolved_at => Time.now.utc)
    send_resolved
  end

  def do_close
    self.update_attribute(:closed_at, Time.now.utc)
    # cancel all rewards
    self.rewards.each {|reward| reward.cancel!} if self.offers_reward?
    send_closed
  end

  def do_suspend
    self.update_attribute(:suspended_at, Time.now.utc)
    send_suspend
  end

  def do_unsuspend
    self.update_attribute(:suspended_at, nil)
    send_unsuspend
  end

  # update count after suspend kase
  def after_suspended
    self.update_associated_count
  end

  def do_delete
    self.deleted_at = Time.now.utc
    send_delete
  end

  # update count after suspend kase
  def after_deleted
    self.update_associated_count
  end
  
  def create_and_send_activation_code
    unless self.person
      self.activation_code = Digest::SHA1.hexdigest(Time.now.to_s.split(//).sort_by {rand}.join)
      KaseMailer.deliver_activation(self) unless User.pre_active.find_by_email(self.sender_email)
    end
  end

  #--- notifiers

  def send_new_post
    I18n.switch_locale self.person.default_language do 
      KaseMailer.deliver_new_post(self, :person)
    end

=begin    
    # all friends/contacts/followers
    Utility.active_language_codes.each do |code|
      I18n.switch_locale code do
        KaseMailer.deliver_new_post(self, :friend, self.person.friends.select {|p| p.default_language == code})
      end
    end unless self.person.friends.blank?

    # all matching partners
    matches = find_matching_partners
    Utility.active_language_codes.each do |code|
      I18n.switch_locale code do
        KaseMailer.deliver_new_post(self, :match, matches.select {|p| p.default_language == code})
      end
    end unless matches.blank?
=end    
  end

  def send_resolved
    # to person/owner
    I18n.switch_locale self.person.default_language do
      KaseMailer.deliver_solved(self, :person)
    end if self.person && self.person.notify_on_kase_status
  end

  def send_closed
    send_new_state(:closed)
  end

  def send_suspend
    send_new_state(:suspended)
  end

  def send_unsuspend
    send_new_state(:unsuspended)
  end

  def send_delete
    send_new_state(:deleted)
  end

  # Send note to owner about the winner
  def send_auction_finished(winning_bidder=nil)
    winning_bidder = find_winning_bidder if winning_bidder.nil?
    KaseMailer.deliver_auctioned(self, winning_bidder) if winning_bidder
  end

  # Send note to winning bidder
  def send_auction_won(winning_bidder=nil)
    winning_bidder = find_winning_bidder if winning_bidder.nil?
    unless winning_bidder.nil?
      KaseMailer.deliver_auction_won(self, winning_bidder)
    end
  end

  def send_new_state(new_state)
    # to person/owner
    I18n.switch_locale self.person.default_language do
      KaseMailer.deliver_new_state(self, new_state, :person)
    end if self.person && self.person.notify_on_kase_status
    
    # to assigned person
=begin    
    I18n.switch_locale self.assigned_person.default_language do
      KaseMailer.deliver_new_state(self, new_state, :assigned_person)
    end if self.assigned_person && self.assigned_person.notify_on_kase_status
=end    
  end

  # update kase_count in tier association. we only count "visible" kases
  def update_tier_kases_count
    if self.tier
      ua = {}
      ua.merge!(:kases_count => self.tier.kases.count("kases.id", self.class.find_options_for_visible({:distinct => true}))) if self.tier.class.columns.to_a.map {|a| a.name.to_sym}.include?(:kases_count)
      ua.merge!(:people_count => self.tier.people.count) if self.tier.class.columns.to_a.map {|a| a.name.to_sym}.include?(:people_count)
      unless ua.empty?
        self.tier.class.transaction do 
          self.tier.lock!
          self.tier.update_attributes(ua)
        end
      end
    end
  end
  
  # update kase_count in topic association. we only count "visible" kases
  def update_topics_kases_count
    self.topics.each do |topic|
      ua = {}
      ua.merge!(:kases_count => topic.kases.count("kases.id", self.class.find_options_for_visible({:distinct => true}))) if topic.class.columns.to_a.map {|a| a.name.to_sym}.include?(:kases_count)
      ua.merge!(:people_count => topic.people.count) if topic.class.columns.to_a.map {|a| a.name.to_sym}.include?(:people_count)
      unless ua.empty?
        topic.class.transaction do 
          topic.lock!
          topic.update_attributes(ua)
        end
      end
    end
  end

  # update kases_count in person association. we only count "visible" kases
  def update_person_kases_count
    if self.person
      ua = {}
      ua.merge!(:kases_count => self.person.kases_count(true)) if self.person.class.kases_count_column?
      unless ua.empty?
        self.person.class.transaction do 
          self.person.lock!
          self.person.update_attributes(ua)
        end
      end
    end
  end

  # make sure we normalize correctly
  def normalize_friendly_id(slug_string)
    return super if self.language_code ? self.language_code == "en" : I18n.locale_language == :en
    options = friendly_id_config.babosa_options
    language = Utility.english_language_name(self.language_code || I18n.locale_language) || :english
    slug_string.normalize! options.merge(:transliterations => "#{language}".underscore.to_sym)
  end

end
