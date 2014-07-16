require File.dirname(__FILE__) + '/../test_helper'

class ClaimingTest < ActiveSupport::TestCase
  all_fixtures

  # Replace this with your real tests.
  def test_should_create
    claiming = create_claiming
    assert claiming.valid?
    assert !claiming.new_record?
  end

  # Replace this with your real tests.
  def test_should_not_validate_double_claiming
    claiming = create_claiming
    assert claiming.valid?
    claiming = create_claiming
    assert !claiming.valid?
  end

  def test_should_validate_phone
    claiming = build_claiming(:phone => '+2123 123123', :email => nil)
    assert claiming.valid?
  end

  def test_should_validate_email
    claiming = build_claiming(:email => 'homer@luleka.de')
    assert claiming.valid?
    assert !claiming.errors.invalid?(:email)
  end

  def test_should_not_validate_email_outside_worldwide_orgs
    claiming = build_claiming(:email => 'homer@yahoo.com')
    assert !claiming.valid?
    assert claiming.errors.invalid?(:email)
  end
  
  def test_should_not_validate_email_or_phone
    claiming = build_claiming(:phone => nil, :email => nil)
    assert !claiming.valid?

    claiming = build_claiming(:phone => nil, :email => 'not a valid email')
    assert !claiming.valid?
    assert claiming.errors.invalid?(:email)
  end
  
  def test_email_domain
    claiming = build_claiming(:email => 'steve@apple.com')
    assert_equal 'apple.com', claiming.email_domain
  end

  def test_should_add_product_claimings
    claiming = create_claiming(:organization => tiers(:luleka))
    claiming.organization.products.active.current_region.each do |product|
      product_claiming = claiming.children.create valid_claiming_attributes(:product => product)
      assert product_claiming.valid?
    end
    assert_equal 4, claiming.products.size
  end
  
  def test_should_assign_products_using_product_ids
    claiming = create_claiming(:organization => tiers(:luleka))
    ids = claiming.organization.products.active.current_region.map(&:id).map(&:to_s)
    assert_difference Claiming, :count, ids.size do
      claiming.product_ids = ids
    end
    claiming.reload
    assert_equal claiming.product_ids.to_set, claiming.organization.products.active.current_region.map(&:id).to_set
  end

  def test_should_assign_products_using_product_ids_with_new_record
    claiming = build_claiming(:organization => tiers(:luleka))
    ids = claiming.organization.products.active.current_region.map(&:id).map(&:to_s)
    claiming.product_ids = ids
    assert_difference Claiming, :count, ids.size + 1 do
      claiming.save
    end
    claiming.reload
    assert_equal claiming.product_ids.sort, claiming.organization.products.active.current_region.map(&:id).sort
  end

  def test_should_get_product_ids_for_new_record
    claiming = build_claiming(:organization => tiers(:luleka))
    ids = claiming.organization.products.active.current_region.map(&:id).map(&:to_s)
    claiming.product_ids = ids
    claiming.product_ids.each do |id|
      assert claiming.organization.products.map(&:id).include?(id), "claiming organization product id #{id}, present"
    end
    assert_equal claiming.organization.products.size, claiming.product_ids.size
  end

  def test_should_get_products_association
    claiming = create_claiming(:organization => tiers(:luleka))
    ids = claiming.organization.products.active.current_region.map(&:id).map(&:to_s)
    claiming.product_ids = ids
    claiming.product_ids.each do |id|
      assert claiming.organization.products.map(&:id).include?(id), "claiming organization product id #{id}, present"
    end
    assert_equal claiming.organization.products.size, claiming.product_ids.size
  end

  def test_should_get_products_association_for_new_record
    claiming = build_claiming(:organization => tiers(:luleka))
    ids = claiming.organization.products.active.current_region.map(&:id).map(&:to_s)
    claiming.product_ids = ids
    claiming.organization.products.active.current_region.each do |p|
      assert claiming.products.map(&:id).include?(p.id), "claiming organization product id #{p.id}, present"
    end
  end

  def test_should_work_root?
    claiming = create_claiming
    assert claiming.root?, 'root? method should work'
  end
  
  def test_should_be_passive_on_new
    cl = build_claiming
    assert_equal :queued, cl.current_state
  end
  
  def test_should_accept
    person = people(:lisa)
    cl = create_claiming(:person => person, :organization => tiers(:powerplant), :role => "Bottle Washer")
    cl.register!
    assert_equal :pending, cl.current_state
    assert !tiers(:powerplant).employees.include?(person), "should not include lisa"
    assert_difference Employment, :count do
      cl.accept!
      assert tiers(:powerplant).employees.reload
      assert tiers(:powerplant).employees.include?(person), "should include lisa"
      assert ActionMailer::Base.deliveries.last.body.include?("employee")
      assert_equal "Bottle Washer", person.employments.first.role
    end
    assert_equal :accepted, cl.current_state
    assert tiers(:powerplant).reload.employees.include?(people(:lisa)), "lisa should now be an employee of powerplant"
  end

  def test_should_not_assign_products_already_claimed
    cl = build_claiming(
      :person => people(:lisa),
      :organization => tiers(:luleka),
      :products => tiers(:luleka).products.active.current_region
    )
    assert_equal tiers(:luleka), cl.organization
    assert_equal 4, cl.products.size
    assert_difference Claiming, :count, 5 do
      cl.save
      cl.register!
    end
  end

  def test_should_get_email_with_organization
    claiming = build_claiming(:organization => tiers(:luleka), :email => "")
    assert_nil claiming.email_name
    assert_equal "", claiming.email
    claiming.email_name = "steve"
    assert_equal "steve", claiming.email_name
    assert_equal "steve@luleka.net", claiming.email
    assert claiming.valid?
    assert claiming.save

    claiming = Claiming.find_by_id(claiming.id)
    assert_equal "steve", claiming.email_name
    assert_equal "steve@luleka.net", claiming.email
    
    claiming.email_name = "homer"
    assert_equal "homer", claiming.email_name
    assert_equal "homer@luleka.net", claiming.email
  end

  def test_should_get_email_name_without_organization
    claiming = build_claiming(:organization => nil, :email => "me@luleka.net")
    assert_equal "me", claiming.email_name
    assert_equal "me@luleka.net", claiming.email
    claiming.email_name = "steve"
    assert_equal "steve@luleka.net", claiming.email
  end

  def test_should_not_get_email_without_anything
    claiming = build_claiming(:organization => nil, :email => nil)
    assert_nil claiming.email_name
    assert_nil claiming.email
  end

  def test_should_email_name_with_no_existing_email
    attributes = valid_claiming_attributes(:organization => tiers(:luleka))
    attributes.delete(:email)
    claiming = Claiming.new(attributes.merge(:email_name => "steve"))
    assert_equal "steve", claiming.email_name
    assert_equal "steve@luleka.net", claiming.email
    assert claiming.valid?
    assert claiming.save
    claiming = Claiming.find_by_id(claiming.id)
    assert_equal "steve", claiming.email_name
    assert_equal "steve@luleka.net", claiming.email
  end

  def test_should_email_name_with_existing_email
    claiming = build_claiming(:organization => tiers(:luleka), :email_name => "steve")
    assert_equal "steve", claiming.email_name
    assert_equal "steve@luleka.net", claiming.email
    assert claiming.valid?
    assert claiming.save
    claiming = Claiming.find_by_id(claiming.id)
    assert_equal "steve", claiming.email_name
    assert_equal "steve@luleka.net", claiming.email
  end

  def test_should_get_content_attributes
    claiming = build_claiming(:email => "sam@luleka.tst", :phone => "+1 (123) 123-4567",
      :role => "Product Manager", :message => "What a message")
    attributes = claiming.content_attributes
    assert_equal 4, attributes.to_a.size
    assert_equal "sam@luleka.tst", attributes[:email]
    assert_equal "+1 (123) 123-4567", attributes[:phone]
    assert_equal "Product Manager", attributes[:role]
    assert_equal "What a message", attributes[:message]
  end

  def test_should_create_organization_claiming
    assert_difference Claiming, :count do
      organization = tiers(:luleka)
      assert claiming = create_claiming(:organization => organization)
      assert_equal claiming, organization.claimings.first
      assert_equal claiming, 
        organization.claimings.find_by_activation_code_and_person(claiming.activation_code, claiming.person)
    end
  end

end
