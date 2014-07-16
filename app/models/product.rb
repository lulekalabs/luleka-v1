# Product is derived from Topic.
#
# SKU apply to probono products only, SKU stands for Stock Keeping Unit
# 
#    XX 999 99 LL CC     ->   displays as XX99999LL-CC, example: SU00100DE-DE
#     \  \   \  \  \
#      \  \   \  \  +-- SKU country code (US = USA, DE = Germany, WW = Worldwide, etc.)
#       \  \   \  \
#        \  \   \  +-- SKU language code (EN = English, DE = German, XX = multi-language etc.)
#         \  \   \
#          \  \   +-- SKU variant id product, 00 = main product, 01, 02, etc. are variants
#           \  \
#            \  +-- SKU id (001, 002, 003, etc.)
#             \
#              +-- SKU type, where:
#                    SU = partner subscription
#                    PS = premium subscription (not implemented)
#                    PC = purchasing credit
#                    SF = service fee
#                    LF = listing fee
#                    PP = physcial product
#
class Product < Topic
  #--- constants
  SKU_TYPE_PARTNER_SUBSCRIPTION = 'SU'
  SKU_TYPE_PREMIUM_SUBSCRIPTION = 'PS'
  SKU_TYPE_PURCHASING_CREDIT    = 'PC'
  SKU_TYPE_SERVICE_FEE          = 'SF'
  SKU_TYPE_LISTING_FEE          = 'LF'

  #--- associations
  belongs_to :organization, :class_name => 'Organization', :foreign_key => :tier_id
  has_many :cart_line_items, :as => :product, :dependent => :destroy
  has_many :products_product_prices, :dependent => :destroy, :foreign_key => :product_id
  has_many :prices,
    :through => :products_product_prices,
    :class_name => 'ProductPrice',
    :source => :product_price

  #--- validations
  validates_presence_of :organization
  
  #--- class methods
  class << self
    
    def kind
      :product
    end
    
    # retrieves a three-month partner membership
    def three_month_partner_membership(options={})
      options[:language_code].downcase if options[:language_code]
      options[:country_code].upcase if options[:country_code]
      find(:first, :conditions => {
        :sku_type => SKU_TYPE_PARTNER_SUBSCRIPTION,
        :sku_id => 1,
        :sku_variant_id => 1,
        :language_code => options[:language_code] || Utility.language_code || 'en',
        :country_code => options[:country_code] || Utility.country_code || 'US',
        :internal => true
      })
    end

    # retrieves a two-year partner membership
    def two_year_partner_membership(options={})
      options[:language_code].downcase if options[:language_code]
      options[:country_code].upcase if options[:country_code]
      find(:first, :conditions => {
        :sku_type => SKU_TYPE_PARTNER_SUBSCRIPTION,
        :sku_id => 1,
        :sku_variant_id => 4,
        :language_code => options[:language_code] || Utility.language_code || 'en',
        :country_code => options[:country_code] || Utility.country_code || 'US',
        :internal => true
      })
    end

    # parses sku string and returns a hash of attributes
    # products available in all regions are marked with sku_country WW
    # products with multiple languages with XX
    def sku_attributes(sku)
      result = {
        :sku_type => sku[0..1] ? (sku[0..1].empty? ? nil : sku[0..1].upcase) : nil,
        :sku_id => sku[2..4] ? sku[2..4].to_i : nil,
        :sku_variant_id => sku[5..6] ? sku[5..6].to_i : nil,
        :language_code => sku[7..8] ? sku[7..8].downcase : nil,
        :country_code => sku[10..11] ? sku[10..11].upcase : nil
      }
      result.delete(:language_code) if result[:language_code] =~ /xx/i
      result.delete(:country_code) if result[:country_code] =~ /ww/i
      result.reject! {|k, v| v.blank?}
      result
    end
    
    def find_or_build(attributes={})
      if sku = attributes.delete(:sku)
        attributes.merge!(sku_attributes(sku).reject {|k,v| v == nil})
      end
      if org = attributes.delete(:organization)
        attributes.merge!(:tier_id => org.id) unless org.new_record?
      end
      unless object = find(:first, :conditions => attributes)
        object = new(attributes)
      end
      object
    end
    
    # find all available (internal) products
    #
    # it is intended that only one of one ore more identical products by sku_type, sku_id, sku_variant
    # is returned, where the country_code will win
    def find_available_products(options={})
      defaults = {
        :country_code => Utility.country_code,
        :sku_type => '%',
        :active => true,
        :internal => true
      }
      options = defaults.merge(options).symbolize_keys

      query = "topics.sku_type LIKE ?"
      query += sanitize_sql([" AND topics.status = ?", 'active']) if options[:active] == true
      query += sanitize_sql([" AND topics.internal = ?", true]) if options[:internal] == true
      if options[:language_code] && options[:country_code]
        query += " AND ((topics.language_code LIKE ? OR topics.language_code IS NULL)" +
          " AND (topics.country_code LIKE ? OR topics.country_code IS NULL))"
        conditions = [query, options[:sku_type], options[:language_code].to_s.downcase, options[:country_code].to_s.upcase]
      elsif options[:country_code]
        query += " AND (topics.country_code LIKE ? OR topics.country_code IS NULL)"
        conditions = [query, options[:sku_type], options[:country_code].to_s.upcase]
      else
        conditions = [query, options[:sku_type]]
      end
      order = "#{sanitize_sql(["topics.country_code IN (?) DESC, topics.country_code IS NULL ASC", [options[:country_code]]])}"
      group = "topics.sku_type, topics.sku_id, topics.sku_variant_id"
      
      find(:all, :include => :prices, :conditions => conditions, :order => order, :group => group)
    end

    # Find all available and active partner membership products available for 
    # the current language or language defined in options
    #
    # e.g.
    #
    #   def self.find_partner_memberships_by_language(options={})
    #
    def find_available_partner_memberships(options={})
      find_available_products(options.merge(:sku_type => Product::SKU_TYPE_PARTNER_SUBSCRIPTION))
    end

    # Find all available purchasing credits
    def find_available_purchasing_credits(options={})
      find_available_products(options.merge(:sku_type => Product::SKU_TYPE_PURCHASING_CREDIT))
    end

    # Find all available with SKU similar to provided SKU
    # XX 999 99 LL CC
    #
    # e.g.
    #
    # SU99999XX-WW     ->   any language any region
    # SU00100DE-DE     ->   germany and german
    # SU00100DE
    # SU00101
    # SU001
    #
    def find_like_by_sku(sku, options={})
      finder_options = find_options_for_like_by_sku(sku, options)
      finder_options[:conditions] ? find(:all, finder_options) : []
    end
    
    # finds the first occurance of the given sku, nil if non is found
    def find_by_sku(sku, options={})
      finder_options = find_options_for_like_by_sku(sku, options)
      finder_options[:conditions] ? find(:first, finder_options) : []
    end
    
    def find_options_for_like_by_sku(sku, options={})
      attributes = sku_attributes(sku)
      if attributes[:sku_type] && attributes[:sku_id] && attributes[:sku_variant_id] &&
          attributes[:language_code] && attributes[:country_code]
        # full sku
        conditions = [
          "sku_type LIKE ? AND sku_id = ? AND sku_variant_id = ? AND language_code LIKE ? AND country_code LIKE ?",
            attributes[:sku_type], attributes[:sku_id], attributes[:sku_variant_id],
              attributes[:language_code], attributes[:country_code]
        ]
      elsif attributes[:sku_type] && attributes[:sku_id] && attributes[:sku_variant_id] &&
              attributes[:language_code]
        # sku without country code
        conditions = [
          "sku_type LIKE ? AND sku_id = ? AND sku_variant_id = ? AND language_code LIKE ?",
            attributes[:sku_type], attributes[:sku_id], attributes[:sku_variant_id],
              attributes[:language_code]
        ]
      elsif attributes[:sku_type] && attributes[:sku_id] && attributes[:sku_variant_id]
        # only type, id and variant id
        conditions =  [
          "sku_type LIKE ? AND sku_id = ? AND sku_variant_id = ?", 
            attributes[:sku_type], attributes[:sku_id], attributes[:sku_variant_id]
        ]
      elsif attributes[:sku_type] && attributes[:sku_id]
        conditions = [
          "sku_type LIKE ? AND sku_id = ?", 
          attributes[:sku_type], attributes[:sku_id]
        ]
      end
      {
        :include => :prices,
        :order => "sku_id ASC, sku_type ASC, sku_variant_id ASC",
        :conditions => sanitize_sql(conditions)
      }.merge_finder_options(options)
    end

    # Finds sales comission = service fee
    # Cart instance will calculate the relative 
    # service fee.
    def find_service_fee(options={})
      find_available_products(options.merge(:sku_type => Product::SKU_TYPE_SERVICE_FEE)).first
    end
    alias_method :service_fee, :find_service_fee
    
  end
  
  #--- instance methods
  
  alias_method :sku_language_code, :language_code
  alias_method :sku_language_code=, :language_code=
  alias_method :sku_country_code, :country_code
  alias_method :sku_country_code=, :country_code=
  
  # returns a string representation for class/instance type
  def kind
    self.class.kind
  end
  
  # Make the unit a symbol
  def unit
    self[:unit] ? self[:unit].to_sym : :piece
  end

  # unit setter
  def unit=(a_unit)
    self[:unit] = a_unit.to_s if a_unit
  end

  # returns the unit string
  def unit_s
    self.unit.to_s if self.unit
  end
  
  # translated unit, e.g. month -> Monat
  def unit_t
    I18n.t "#{self.unit_s}", :count => 1
  end

  # SKU stands for stock keeping unit, and it used only for Propono products
  # Returns a formatted sku number
  #
  # e.g.
  #
  #   SU00101EN-EN  for english, US
  #   SU00101XX-WW  for any language, worldwide
  #
  def sku
    (sku_type || 'xx').upcase + 
    sku_id.to_s.rjust(3, '0') +
    sku_variant_id.to_s.rjust(2, '0') +
    (language_code || 'XX').upcase + '-' +
    (country_code || 'WW').upcase 
  end
  
  # assigns a sku string, breaks it up into components and stores its values
  # e.g. SU00101EN-EN 
  def sku=(a_sku)
    self.attributes = Product.sku_attributes(a_sku).reject {|k, v| v == nil}
  end

  # True if the product can be subscribed over a period of time
  # right now, only partner can be subscribed
  def is_subscribable?
    is_partner_subscription? || is_premium_subscription?
  end
  alias_method :subscribable?, :is_subscribable?
  
  # True if product is an partner subscription
  def is_partner_subscription?
    sku_type.to_s == Product::SKU_TYPE_PARTNER_SUBSCRIPTION && self.internal?
  end
  alias_method :is_partner_membership?, :is_partner_subscription?
  
  # True if the product sku_type is a purchasing credit
  def is_purchasing_credit?
    sku_type.to_s == Product::SKU_TYPE_PURCHASING_CREDIT && self.internal?
  end

  # premium subscription
  def is_premium_subscription?
    sku_type.to_s == Product::SKU_TYPE_PREMIUM_SUBSCRIPTION && self.internal?
  end
  alias_method :is_premium_membership?, :is_premium_subscription?

  # True if service fee
  def is_service_fee?
    sku_type.to_s == Product::SKU_TYPE_SERVICE_FEE && self.internal?
  end
  
  # True if product is a listing fee
  # NOTE not currently used/implemented
  def is_listing_fee?
    sku_type.to_s == Product::SKU_TYPE_LISTING_FEE && self.internal?
  end

  # returs true if this is a probono product
  def internal?
    self.internal
  end
  
  # returns true if product is taxable
  def taxable?
    self[:taxable]
  end

  # returns the product price based on
  def price(currency_code=nil)
    selected_currency = currency_code || Utility.currency_code
    unless @product_price_cache && @product_price_cache.currency == selected_currency
      @product_price_cache = self.find_price_by_currency(selected_currency)
    end
    @product_price_cache.price if @product_price_cache
  end
  
  # some product prices are made up of a percentage, e.g. comission, services fee, etc.
  def price_percentage(currency_code=nil)
    selected_currency = currency_code || Utility.currency_code
    unless @product_price_cache && @product_price_cache.currency == selected_currency
      @product_price_cache = self.find_price_by_currency(selected_currency)
    end
    @product_price_cache.percentage if @product_price_cache
  end

  # price per unit
  # E.g. $2.49 (per month) if the anual subscription price is $29.95
  def unit_price(currency_code=nil)
    self.price(currency_code) / (self.pieces || 1) if self.price(currency_code)
  end

  # returns the product price by currency passed from cart_line_item
  # providing a dependent object will calculate the price depending on the price
  # and percentage of the percentage value, and adding the product price
  #
  # options:
  #   :dependent => <cart_line_item>
  #   :currency_code => <provided through cart and cart_line_item>
  #
  def copy_price(options={})
    if object = options[:dependent]
      result = self.price(options[:currency_code])
      dependent_price = object.price if object.respond_to?(:price)
      if self.price_percentage(options[:currency_code]) && self.price_percentage(options[:currency_code]).to_f > 0.0
        result += dependent_price * (self.price_percentage(options[:currency_code]) / 100)
      end
      result
    else
      self.price(options[:currency_code])
    end
  end

  # translates the product name for the cart line item
  def copy_name(options={})
    I18n.switch_locale(options[:locale] || self.language_code || Utility.locale_code) do
      self.name
    end
  end

  # prepares description for cart_line_item, when the product is added to the 
  # shopping cart
  def copy_description(options={})
    I18n.switch_locale(options[:locale] || (self.locale? ? self.locale : self.language_code) || Utility.locale_code) do
      text = self.description.to_s
      selected_currency = options[:currency_code] || Utility.currency_code
      units_text = "{{count}} #{self.unit}" / self.pieces      # Pluralize! because "%d month" , "%d months" are defined
      price_text = self.price(selected_currency).format if self.price(selected_currency)
      
      if self.pieces.to_i > 1
        unit_price_text = self.unit_price(selected_currency).format if self.unit_price(selected_currency)
        charge = "%{price} (%{unit_price} per %{unit})".t % {
          :price => price_text,
          :unit_price => unit_price_text,
          :unit => self.unit_t
        } if price_text
      else
        charge = price_text if price_text
      end
      text = text % {:unit => units_text}
      text = text % {:price => charge} if charge
      text = text % {:unit_price => self.unit_price(selected_currency) ? self.unit_price(selected_currency).format : '?'}
      text = text % {:percentage => self.price_percentage.loc} if price_percentage
      if dependent = options[:dependent]
        text = text % {
          :dependent_price => dependent.price.format,
          :dependent_name => truncate(dependent.name).to_s
        }
      end
      truncate(text, :length => 100).to_s if self.description
    end
  end
  
  protected
  
  # Try to find a price for a currency
  def find_price_by_currency(currency)
    self.prices.find_by_currency(currency)
  end
  
end
