require File.dirname(__FILE__) + '/../test_helper'

class ProductTest < ActiveSupport::TestCase
  all_fixtures

  def setup
    I18n.locale = :"en-US"
  end

  # Replace this with your real tests.
  def test_simple_find_like_by_sku
    promotables = Product.find_like_by_sku('SU00101')
    assert_equal 2, promotables.size
    assert promotables.first.is_subscribable?
    assert promotables.first.is_partner_subscription?
  end

  def test_find_like_by_sku
    promotables = Product.find_like_by_sku('SU00101', :conditions => [
      "language_code LIKE ? AND country_code LIKE ?",
      'de',
      'DE'
    ])
    assert_equal 1, promotables.size
    assert_equal 'SU00101DE-DE', promotables.first.sku
  end
  
  def test_find_by_sku
    product = Product.find_by_sku('SU00103EN-US')
    assert product, "1 year subscription was found"
    assert_equal 'SU00103EN-US', product.sku
  end
  
  def test_should_create
    product = create_product
    assert product.valid?
  end
  
  def test_should_activate_suspend_unsuspend
    product = create_product
    assert product.valid?
    assert_equal :pending, product.current_state
    assert product.activate!
    assert_equal :active, product.current_state
    assert !product.activated_at.blank?
    saved_activated_at = product.activated_at
    assert product.suspend!
    assert_equal :suspended, product.current_state
    assert product.unsuspend!
    assert_equal :active, product.current_state
    assert_equal saved_activated_at.to_s, product.activated_at.to_s
  end

  def test_should_create_permalink
    product = create_product :name => 'The Fox jumps over the fence'
    assert product.valid?
    assert 'the-fox-jumps-over-the-fence', product.permalink
  end

  def test_has_many_kases_through_kontext
    membership = topics(:three_month_partner_membership_en)
    kase = create_idea(:title => 'Expires early')
    assert kase.valid?
    assert kase.activate!

    assert_difference Kontext, :count, 1 do 
      membership.kases << kase
    end
    
    assert membership.save
    membership.reload
    assert_equal 1, membership.kases.count
    assert_difference Kontext, :count, -1 do 
      membership.kases.delete(kase)
    end
    membership.reload
    assert_equal 0, membership.kases.count
  end

  def test_should_find_available_purchasing_credits
    ps = Product.find_available_purchasing_credits
    assert_equal 1, ps.size
  end
  
  def test_should_get_price_by_currency
    qm = topics(:three_month_partner_membership_en)
    I18n.switch_locale :"en-US" do
      assert_equal '29.85', qm.price.to_s
      assert_equal 'USD', qm.price.currency
    end
    I18n.switch_locale :"de-DE" do
      assert_equal '24.85', qm.price.to_s
      assert_equal 'EUR', qm.price.currency
    end
  end
  
  def test_should_create_cart_line_item_for_usd_membership
    qm = topics(:three_month_partner_membership_en)
    person = people(:homer)
    line_item = person.cart.cart_line_item(qm)
    assert_equal "Three-Month Partner Membership", line_item.name
    assert_equal "29.85", line_item.price.to_s
    assert_equal "USD", line_item.price.currency
    assert_equal "3 months partner membership for $29.85 ($9.95 per month)", line_item.description
  end

  def test_should_create_cart_line_item_for_eur_membership
    I18n.switch_locale :"de-DE" do
      qm = topics(:three_month_partner_membership_de)
      person = people(:barney)
      line_item = person.cart.cart_line_item(qm)
      
      assert_equal "Three-Month Partner Membership", line_item.name
      assert_equal "24.85", line_item.price.to_s
      assert_equal "EUR", line_item.price.currency
      assert_equal "3 months partner membership for 24.85 € (8.28 € per month)", line_item.description
    end
  end
  
  def test_should_create_cart_line_item_for_usd_service_fee
    pc = topics(:five_purchasing_credit_en)
    sf = topics(:service_fee_en)
    person = people(:homer)
    dependent = person.cart.add(pc)
    assert dependent
    assert_equal "5.00", dependent.price.to_s
    assert_equal "'Five' Purchasing Credit", dependent.name
    line_item = person.cart.add(sf, 1, :dependent => dependent)
    assert_equal "Service fee", line_item.name
    assert_equal "1.00", line_item.price.to_s
    assert_equal "USD", line_item.price.currency
    assert_equal "20.0% service fee on $5.00 of ''Five' Purchasing Credit'", line_item.description
  end

  def test_should_create_cart_line_item_for_eur_service_fee
    pc = topics(:five_purchasing_credit_de)
    sf = topics(:service_fee_de)
    person = people(:barney)
    dependent = person.cart.add(pc)
    assert dependent
    assert_equal "5.00", dependent.price.to_s
#    assert_equal "Kaufguthaben 'Five'", dependent.name
    assert_equal "'Five' Purchasing Credit", dependent.name
    line_item = person.cart.add(sf, 1, :dependent => dependent)
#    assert_equal "Bearbeitungsgebühr", line_item.name
    assert_equal "Service fee", line_item.name
    assert_equal "1.00", line_item.price.to_s
    assert_equal "EUR", line_item.price.currency
#    assert_equal "20,0% Bearbeitungsgebühr auf den Betrag von 5,00 € von 'Kaufguthaben 'Five''", line_item.description
    assert_equal "20.0% service fee on 5.00 € of ''Five' Purchasing Credit'", line_item.description
  end

  def test_should_get_sku_attributes
    attribs = Product.sku_attributes('PR00401DE-DE')
    assert_equal 'PR', attribs[:sku_type]
    assert_equal 4, attribs[:sku_id]
    assert_equal 1, attribs[:sku_variant_id]
    assert_equal 'de', attribs[:language_code]
    assert_equal 'DE', attribs[:country_code]
  end

  def test_should_not_get_sku_attributes
    attribs = Product.sku_attributes('')
    assert_nil attribs[:sku_type]
    assert_nil attribs[:sku_id]
    assert_nil attribs[:sku_variant_id]
    assert_nil attribs[:language_code]
    assert_nil attribs[:country_code]
  end
  
  def test_should_set_sku
    assert_equal "SU00101EN-EN", Product.new(:sku => "SU00101EN-EN").sku
    assert_equal 'SU00104DE-DE', Product.new(:sku => 'SU00104DE-DE').sku
    assert_equal 'XX99999BN-XO', Product.new(:sku => 'xx99999bn-xo').sku
  end
    
  def test_should_find_or_build
    expert_membership = Service.find_or_build(valid_expert_membership_attributes)
    assert expert_membership.valid?
    assert expert_membership.new_record?
    assert expert_membership.save
    assert_equal 'SU00100EN-US', expert_membership.sku
    id = expert_membership.id

    expert_membership = Service.find_or_build(valid_expert_membership_attributes)
    assert !expert_membership.new_record?
    assert_equal id, expert_membership.id, 'records identical'
    assert_equal 'SU00100EN-US', expert_membership.sku
  end

  def test_should_find_or_build_with_product
    em = Product.find_or_build(valid_expert_membership_attributes(:sku => 'SU00100EN-US'))
    assert em.new_record?, "should be new product"
    assert_equal 'Product', em[:type]
    assert_equal :product, em.kind
    assert em.save
    em = Product.find_or_build(valid_expert_membership_attributes(:sku => 'SU00100EN-US'))
    assert !em.new_record?, "should not be new product"
  end

  def test_should_find_or_build_with_service
    em = Service.find_or_build(valid_expert_membership_attributes(:sku => 'SU00100EN-US'))
    assert em.new_record?, "should be new product"
    assert_equal 'Service', em[:type]
    assert_equal :service, em.kind
    assert em.save
    em = Service.find_or_build(valid_expert_membership_attributes(:sku => 'SU00100EN-US'))
    assert !em.new_record?, "should not be new product"
  end
  
  def test_should_not_require_language_code
    product = Product.new(valid_product_attributes(:language_code => nil))
    assert product.valid?
    assert !product.errors.invalid?(:language_code)
  end

  def test_should_find_three_month_partner_membership
    membership = Product.three_month_partner_membership(:country_code => 'US', :language_code => 'en')
    assert_equal membership, topics(:three_month_partner_membership_en)

    membership = Product.three_month_partner_membership(:country_code => 'DE', :language_code => 'de')
    assert_equal membership, topics(:three_month_partner_membership_de)

    membership = Product.three_month_partner_membership
    assert_equal topics(:three_month_partner_membership_en).id, membership.id
  end

  def test_should_store_and_retrieve_cart_line_item_from_session
    person = people(:homer)
    cart = person.cart
    cart.add topics(:three_month_partner_membership_en)
    assert_equal 1, cart.line_items.size
    assert_equal CartLineItem, cart.line_items.first.class
    assert_equal topics(:three_month_partner_membership_en), cart.line_items.first.product
    assert cart.line_items.first.name
    assert cart.line_items.first.description
      
    session = cart.to_yaml
    
    current_cart = YAML.load(session.to_s)
    assert_equal 1, current_cart.line_items.size
    assert_equal topics(:three_month_partner_membership_en), current_cart.line_items.first.product
    
    # pass on Rails 1.8.6, fails on Rails 2.0.2
    # this is because a yamled object cannot be saved
    # the code exists in FrontApplicationController::load_cart_from_session
    # =>     assert current_cart.line_items[0].save
    # =>     assert_nil current_cart.line_items[0].id, 'this should fail with Rails 2.x'
    
    saved_card_line_item = current_cart.line_items[0]
    current_cart.line_items[0] = current_cart.line_items[0].clone
#   assert_equal saved_card_line_item.attributes, current_cart.line_items[0].attributes
    assert current_cart.line_items[0].save
    assert current_cart.line_items[0].id, 'should be saved'
  end

  def test_should_assign_organization
    p = Product.new({
      :name => 'Wonderful',
      :language_code => 'de',
      :organization => tiers(:powerplant),
      :site_url => 'http://www.powerplant.gov'
    })
    assert_equal tiers(:powerplant), p.organization 
    assert_equal tiers(:powerplant), p.tier
    p.save
    p = Product.find_by_id(p.id)
    assert_equal tiers(:powerplant), p.organization 
    assert_equal tiers(:powerplant), p.tier
  end

  def test_assign_prices
    assert_difference Product, :count do 
      assert_difference ProductPrice, :count, 2 do 
        # price 25 us$
        assert usd_25_credit = ProductPrice.create(
          :currency => 'USD',
          :cents => 2500
        )
        assert usd_25_credit.valid?
        # price 25 eur
        assert eur_25_credit = ProductPrice.create(
          :currency => 'EUR',
          :cents => 2500
        )
        assert eur_25_credit.valid?
        # 25 purchasing credit
        assert credit_25 = Product.find_or_build(
          :organization => tiers(:luleka_us),
          :sku => 'PC00402EN-US',
          :name => "TWENTYFIVE Purchasing Credit",
          :name_de => "Kaufguthaben TWENTYFIVE",
          :unit => 'piece',
          :pieces => 1,
          :taxable => false,
          :internal => true,
          :description => "%{unit_price} purchasing credit",
          :description_de => "Kaufguthaben über %{unit_price}"
        )
        assert credit_25.save(false)
        credit_25.prices << usd_25_credit
        credit_25.prices << eur_25_credit
        credit_25.save                                       
        credit_25.register!
        credit_25.activate!
        assert_equal 2, credit_25.prices.count
        assert_equal ["$25.00", "25.00 €"].to_set, credit_25.prices.map(&:price).map(&:format).to_set
      end
    end
  end

  def test_find_service_fee
    assert fee = Product.find_service_fee(:country_code => 'DE'), 'should find fee'
    assert 'DE', fee.language_code

    assert fee = Product.service_fee(:country_code => 'DE'), 'should find fee'
    assert 'DE', fee.language_code
  end
  
  def test_should_convert_simple_sku
    options = Product.sku_attributes("SU99999EN-US")
    assert_equal 'en', options[:language_code]
    assert_equal 'US', options[:country_code]
    assert_equal 'SU', options[:sku_type]
    assert_equal 999, options[:sku_id]
    assert_equal 99, options[:sku_variant_id]
  end

  def test_should_convert_ww_sku
    options = Product.sku_attributes("SU99999XX-WW")
    assert_nil options[:language_code], 'any language skus should be nil in language_code'
    assert_nil options[:country_code], 'worldwide skus should be nil in country_code'
    assert_equal 'SU', options[:sku_type]
    assert_equal 999, options[:sku_id]
    assert_equal 99, options[:sku_variant_id]
  end
  
  def test_should_find_or_build_worldwide_product
    assert_difference Service, :count do
      service = Service.find_or_build(
        :organization => tiers(:luleka),
        :sku => 'SU99999XX-WW',
        :name => 'Thirty-six month of partner membership',
        :name_de => 'Sechundreissig Monate Mitgliedschaft',
        :name_es => 'Trenta-y-seis meses de miembro socio',
        :unit => 'month',
        :pieces => 36,
        :internal => true,
        :description => "Thirty-six month of partner membership",
        :description_de => "Sechundreissig Monate Mitgliedschaft",
        :description_es => "Trenta-y-seis meses de miembro socio"
      )
      assert_equal 'SU99999XX-WW', service.sku
      assert service.valid?, "service should be valid"
      assert service.save, "service should save"
      assert_nil service.country_code
      assert_nil service.language_code
    end
  end

  def test_should_find_available_products_worldwide
    product_ww = Product.find_or_build(
      :organization => tiers(:luleka),
      :sku => 'SU99999XX-WW',
      :name => 'worldwide',
      :name_de => 'weltweit',
      :name_es => 'mundial',
      :unit => 'month',
      :pieces => 1,
      :internal => true,
      :description => "worldwide",
      :description_de => "weltweit",
      :description_es => "mundial"
    )
    assert product_ww.save, "should save ww product"
    assert_equal true, product_ww.register!, "should register ww product"
    assert_equal true, product_ww.activate!, "should activate ww product"
    
    product_us = Product.find_or_build(
      :organization => tiers(:luleka),
      :sku => 'SU99999EN-US',
      :name => 'states',
      :unit => 'month',
      :pieces => 1,
      :internal => true,
      :description => "states"
    )
    assert product_us.save, "should save de product"
    assert_equal true, product_us.register!, "should register us product"
    assert_equal true, product_us.activate!, "should activate us product"
    
    products = Product.find_available_products
    assert !products.include?(product_us), "should include the us product"
    assert products.include?(product_ww), "should not include the worldwide product"
  end


  protected 
  
  def valid_expert_membership_attributes(options={})
    {
      :organization => tiers(:luleka),
      :sku => 'SU00100EN-US',
      :name => "1 Month Luleka Partner Membership",
      :unit => 'month',
      :pieces => 1,
      :internal => true,
      :description => "One month Luleka Partner membership for %{price}"
    }.merge(options)
  end

end
