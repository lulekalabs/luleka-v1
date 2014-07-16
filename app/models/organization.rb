# Organization is the super class of Company, Agency or all other related
# sub classes of organizations. An organization has employees. Each 
# organization can have one or more products and services.
class Organization < Tier
  #--- associations
  has_many :products, :dependent => :destroy,
    :class_name => 'Product',
    :foreign_key => :tier_id,
    :order => "topics.name ASC"
  has_many :recent_products,
    :class_name => 'Product',
    :foreign_key => :tier_id,
    :limit => 5,
    :order => "topics.activated_at DESC",
    :conditions => ["topics.status = ?", 'active']
  has_many :popular_products,
    :class_name => 'Product',
    :foreign_key => :tier_id,
    :order => "COUNT(kases.id) DESC",
    :limit => 5,
    :finder_sql => 'SELECT DISTINCT topics.* FROM topics ' + 
      'INNER JOIN kontexts ON kontexts.topic_id = topics.id ' +
      'INNER JOIN kases ON kases.id = kontexts.kase_id ' +
      'WHERE kontexts.tier_id = #{id} AND ' +
      'topics.status IN (\'active\')'
  has_many :claimings, :class_name => 'Claiming',
    :foreign_key => :tier_id, :dependent => :destroy
  has_many :employments, :class_name => 'Employment',
    :foreign_key => :tier_id, :dependent => :destroy
  has_many :employees,
    :through => :employments,
    :class_name => 'Person',
    :source => :employee,
    :conditions => "memberships.status IN ('active', 'moderator', 'admin')"
  has_many :admins,
    :through => :employments,
    :class_name => 'Person',
    :source => :employee,
    :conditions => "memberships.status IN ('admin')"
  has_many :moderators,
    :through => :employments,
    :class_name => 'Person',
    :source => :employee,
    :conditions => "memberships.status IN ('moderator')"
  has_many :partners,
    :through => :employments,
    :class_name => 'Person',
    :source => :employee,
    :conditions => "people.status IN ('partner')"
  
  #--- class methods
  class << self

    def kind
      :organization
    end
    
    def topic_class
      Product
    end

    def membership_class
      Employment
    end
    
    # returns probono headquarters company instance
    def probono
      find_worldwide_by_permalink_and_active(
        'luleka', true, :include => :piggy_bank)
    end
    
  end
  
  #--- instance methods
  
  # returns a string representation for class/instance type
  # kind setter is generated and used on new action
  def kind
    @kind || :organization
  end

  def validate
    super
    validate_tax_code if self.tax_code
  end
  
end
