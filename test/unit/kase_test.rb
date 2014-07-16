require File.dirname(__FILE__) + '/../test_helper'

class KaseTest < ActiveSupport::TestCase
  all_fixtures
  
  def setup
    I18n.locale = :"en-US"
    GeoKit::Geocoders::MultiGeocoder.stubs(:geocode).returns(valid_geo_location)
    ExchangeRate.setup_money_bank
    ActionMailer::Base.deliveries.clear
    
    tiers(:powerplant).update_attributes(
      :accept_default_reputation_points => true, 
        :accept_default_reputation_threshold => true, 
          :accept_person_total_reputation_points => true)
  end

  def test_simple_create
    kase = build_idea
    kase.save!
    assert kase
    kase = Kase.find_by_id kase.id
    assert_equal :created, kase.current_state
  end

  def test_should_validate_discussion_type_for_idea
    assert_difference Idea, :count do
      idea = Idea.create({
        :person => people(:homer),
        :severity => Severity.normal,
        :title => 'A new idea',
        :description => 'We have a new idea'
      })
      assert idea.valid?, 'idea should be valid'
    end
  end

  def test_should_validate_discussion_type_for_praise
    praise = Praise.new({
      :person => people(:homer),
      :severity => Severity.normal,
      :title => 'A new praise',
      :description => 'We have a new praise'
    })
    assert praise.valid?, 'praise should be valid'
  end

  def test_should_not_validate_no_title
    assert problem = build_problem(:title => nil)
    assert !problem.valid?
    assert problem.errors.on(:title)
  end

  def test_should_not_validate_short_title
    assert problem = build_problem(:title => "a" * 4)
    assert !problem.valid?
    assert problem.errors.on(:title)
  end

  def test_should_not_validate_long_title
    assert problem = build_problem(:title => "a" * 121)
    assert !problem.valid?
    assert problem.errors.on(:title)
  end

  def test_should_not_validate_no_description
    assert problem = build_problem(:description => nil)
    assert !problem.valid?
    assert problem.errors.on(:description)
  end

  def test_should_not_validate_short_description
    assert problem = build_problem(:description => "a" * 14)
    assert !problem.valid?
    assert problem.errors.on(:description)
  end

  def test_should_not_validate_long_description
    assert problem = build_problem(:description => "a" * 2001)
    assert !problem.valid?
    assert problem.errors.on(:description)
  end

  def test_current_state_s
    kase = create_idea
    assert_equal "new", kase.current_state_s
  end

  def test_current_state_t
    kase = create_idea
    assert_equal "new", kase.current_state_t
  end

  def test_should_instantiate_with_type_and_class_name
    assert_equal 'Problem', Kase.new(:type => Problem).class.name
    assert_equal 'Problem', Kase.new(:type => 'Problem').class.name

    assert_equal 'Question', Kase.new(:type => Question).class.name
    assert_equal 'Question', Kase.new(:type => 'Question').class.name
    
    assert_equal 'Idea', Kase.new(:type => Idea).class.name
    assert_equal 'Idea', Kase.new(:type => 'Idea').class.name
    
    assert_equal 'Praise', Kase.new(:type => Praise).class.name
    assert_equal 'Praise', Kase.new(:type => 'Praise').class.name
  end

  def test_should_instantiate_with_type_and_kind
    assert_equal 'Problem', Kase.new(:type => :problem).class.name
    assert_equal 'Question', Kase.new(:type => :question).class.name
    assert_equal 'Idea', Kase.new(:type => :idea).class.name
    assert_equal 'Praise', Kase.new(:type => :praise).class.name
  end

  def test_should_not_instantiate_class_with_invalid_type
    assert_equal 'Kase', Kase.new(:type => :bogus).class.name
  end
  
  def test_simple_kase_should_not_validate
    kase = build_kase
    assert !kase.valid?
  end

  def test_should_create_permalink
    kase = build_idea(:title => "Das ist das Haus von Nikolaus")
    assert kase.save
    assert_equal 'das-ist-das-haus-von-nikolaus', kase.permalink
  end

  def test_should_find_by_permalink
    kase = create_idea(:title => "Das ist das Haus von Nikolaus")
    assert kase.activate!, "kase should should activate"
    assert kase.visible?, "kase should be visible"
    assert_equal kase, Kase.find_by_permalink('das-ist-das-haus-von-nikolaus')
  end

  def test_not_find_by_permalink
    kase = create_idea(:title => "Das ist das Haus von Nikolaus")
    assert !kase.visible?, "kase should not be visible"
    assert_raises ActiveRecord::RecordNotFound do
      Kase.find_by_permalink('das-ist-das-haus-von-nikolaus')
    end
  end

  def test_should_find_by_slug
    kase = Idea.create(:title => "Das ist das Haus von Nikolaus", 
      :description => "Das ist das Haus von Nikolaus und bla bla bla",
      :sender_email => "bla@blu.com")
    kase.title = "Das ist jetzt ein ganz anderer Titel"
    assert_equal true, kase.save, "should save after title change"
    assert_equal 'das-ist-jetzt-ein-ganz-anderer-titel', kase.friendly_id
    assert_nothing_raised do
      found = Kase.find('das-ist-jetzt-ein-ganz-anderer-titel')
      assert_equal true, found.friendly_id_status.best?, "should not have better id"
    end
    assert_nothing_raised do
      found = Kase.find('das-ist-das-haus-von-nikolaus')
      assert_equal false, found.friendly_id_status.best?, "should have better id"
    end
  end
  
  def test_should_find_by_permalink_with_changed_title
    kase = create_idea(:title => "Das ist das Haus von Nikolaus")
    assert kase.activate!, "kase should activate"
    assert kase.visible?, "kase should be visible"
    assert_equal kase, Kase.find_by_permalink('das-ist-das-haus-von-nikolaus')
    kase.title = "Das ist jetzt ein ganz anderer Titel"
    assert_equal true, kase.save, "should save after title change"
    assert_equal 'das-ist-jetzt-ein-ganz-anderer-titel', kase.friendly_id
    assert_nothing_raised do
      found = Kase.find('das-ist-jetzt-ein-ganz-anderer-titel')
      assert_equal true, found.friendly_id_status.best?, "should not have better id"
    end
    assert_nothing_raised do
      found = Kase.find('das-ist-das-haus-von-nikolaus')
      assert_equal false, found.friendly_id_status.best?, "should have better id"
    end
  end

  #--- associations
  def test_has_many_comments
    kase = build_idea
    comment = kase.comments.build({
      :message => "hello comment", :sender => people(:homer),
      :receiver => people(:marge), :commentable => kase})
    assert comment.valid?, 'comment should be valid'
    assert kase.save
    assert kase
    kase = Kase.find_by_id kase.id
    assert_equal 'hello comment', kase.comments.first.message
  end

  def test_has_many_responses
    assert kase = create_problem
    assert kase.valid?, "kase should be valid"
    assert kase.activate!, "kase should be activated"
    assert response = kase.responses.create({
      :description => "this is my great answer",
      :person => people(:bart)
    })
    response.activate!
    person = response.person
    assert person, "should have a person associated"
    
    assert response.valid?, "response should be valid"
    kase.reload
    assert_equal 1, kase.responses_count
    assert_equal 1, person.responses_count
    assert response, kase.responses.first
    response.suspend!
    response.reload
    person.reload
    kase.reload
    assert_equal 0, kase.responses_count
    assert_equal 0, person.responses_count
  end

  def test_has_many_assets
    kase = build_kase
    assert kase.assets.empty?
  end

  def test_has_many_clarifications
    kase = build_kase
    assert kase.clarifications.empty?
  end

  def test_has_many_clarification_requests
    kase = build_kase
    assert kase.clarification_requests.empty?
  end

  def test_has_many_clarification_responses
    kase = build_kase
    assert kase.clarification_responses.empty?
  end

  def test_should_set_organization_with_new_record_and_save
    kase = nil
    assert_no_difference Kontext, :count do
      kase = build_idea(:organization => tiers(:powerplant))
    end
    assert_equal tiers(:powerplant), kase.organization
    assert_difference Kontext, :count, 1 do
      kase.save
    end
    kase = Kase.find_by_id(kase.id)
    assert_equal tiers(:powerplant), kase.organization
    assert_equal true, kase.organization?
  end

  def test_should_set_organization
    kase = nil
    assert_difference Kontext, :count, 1 do
      kase = create_idea(:organization => tiers(:powerplant))
    end
    assert_equal tiers(:powerplant), kase.organization
    kase = Kase.find_by_id(kase.id)
    assert_equal tiers(:powerplant), kase.organization
  end

  def test_should_set_organization_to_nil
    kase = nil
    assert_difference Kontext, :count, 1 do
      kase = create_idea(:organization => tiers(:powerplant))
    end
    assert_equal tiers(:powerplant), kase.organization
    assert_difference Kontext, :count, -1 do
      kase.organization = nil
    end
    assert_nil kase.organization
    kase = Kase.find_by_id(kase.id)
    assert_nil kase.organization
  end

  def test_should_set_organization_to_nil_with_new_record
    kase = nil
    assert_no_difference Kontext, :count do
      kase = build_kase(:organization => tiers(:powerplant))
    end
    assert_equal tiers(:powerplant), kase.organization
    assert_no_difference Kontext, :count do
      kase.organization = nil
    end
    assert_nil kase.organization
  end

  def test_should_reset_organization
    kase = nil
    assert_difference Kontext, :count, 1 do
      kase = create_idea(:organization => tiers(:powerplant))
    end
    assert_equal tiers(:powerplant), kase.organization
    assert_no_difference Kontext, :count do
      kase.organization = tiers(:luleka)
    end
    assert_equal tiers(:luleka), kase.organization
    kase = Kase.find_by_id(kase.id)
    assert_equal tiers(:luleka), kase.organization
  end

  def test_should_assign_products_using_product_ids
    kase = nil
    assert_difference Kontext, :count, 1 do
      kase = create_idea(:organization => tiers(:powerplant))
    end
    ids = kase.organization.products.active.current_region.map(&:id).map(&:to_s)
    assert_no_difference Product, :count do
      assert_difference Kontext, :count, ids.size do
        kase.product_ids = ids
      end
    end
    kase = Kase.find_by_id(kase.id)
    kase.product_ids.each do |i|
      assert ids.map(&:to_i).include?(i), "product id #{i} assigned correctly"
    end
    assert_equal ids.map(&:to_i).size, kase.products.size
  end

  def test_should_reassign_products_using_product_ids
    kase = nil
    assert_difference Kontext, :count, 1 do
      kase = create_idea(:organization => tiers(:powerplant))
    end
    ids = kase.organization.products.active.current_region.map(&:id).map(&:to_s)
    assert_no_difference Product, :count do
      assert_difference Kontext, :count, 2 do
        kase.product_ids = [ids[0], ids[1]]
      end
    end
    kase = Kase.find_by_id(kase.id)
    kase.product_ids.each do |i|
      assert [ids[0], ids[1]].map(&:to_i).include?(i), "product id #{i} assigned correctly"
    end
    assert_equal 2, kase.products.size
    # now reassign
    assert_no_difference Product, :count do
      assert_difference Kontext, :count, -1 do   # 2 are deleted and 1 added
        kase.product_ids = [ids[2]]
      end
    end
    kase = Kase.find_by_id(kase.id)
    kase.product_ids.each do |i|
      assert [ids[2]].map(&:to_i).include?(i), "product id #{i} assigned correctly"
    end
    assert_equal 1, kase.products.size
  end

  def test_should_assign_products_using_product_ids_with_new_record_and_save
    kase = nil
    assert_no_difference Kontext, :count do
      kase = build_idea(:organization => tiers(:powerplant))
    end
    ids = kase.organization.products.active.current_region.map(&:id).map(&:to_s)
    assert_no_difference Kontext, :count do
      kase.product_ids = ids
    end
    assert_difference Kontext, :count, ids.size + 1 do
      kase.save
    end
    kase = Kase.find_by_id(kase.id)
    assert tiers(:powerplant), kase.organization
    kase.product_ids.each do |i|
      assert kase.organization.products.map(&:id).include?(i), "product id #{i} assigned correctly"
    end
    assert_equal ids.size, kase.product_ids.size
    assert_equal ids.size, kase.products.size
  end

  def test_should_reassign_products_using_product_ids_with_new_record_and_save
    kase = nil
    assert_no_difference Kontext, :count do
      kase = build_idea(:organization => tiers(:powerplant))
    end
    ids = kase.organization.products.active.current_region.map(&:id).map(&:to_s)
    # before save
    assert_no_difference Product, :count do
      assert_no_difference Kontext, :count do
        kase.product_ids = [ids[0], ids[1]]
      end
    end
    # now save
    assert_no_difference Product, :count do
      assert_difference Kontext, :count, 2 + 1 do  # saves the two product + organization context
        kase.save
      end
    end
    # reload
    kase = Kase.find_by_id(kase.id)
    kase.product_ids.each do |i|
      assert [ids[0], ids[1]].map(&:to_i).include?(i), "product id #{i} assigned correctly"
    end
    assert_equal 2, kase.products.size
    # now reassign
    assert_no_difference Product, :count do
      assert_difference Kontext, :count, -1 do   # 2 are deleted and 1 added
        kase.product_ids = [ids[2]]
      end
    end
    kase = Kase.find_by_id(kase.id)
    kase.product_ids.each do |i|
      assert [ids[2]].map(&:to_i).include?(i), "product id #{i} assigned correctly"
    end
    assert_equal 1, kase.products.size
  end
  
  def test_should_reassign_organization_after_assigning_organization_and_products
    kase = nil
    assert_difference Kontext, :count, 1 + tiers(:powerplant).products.size do
      kase = create_idea(
        :organization => tiers(:powerplant),
        :product_ids => tiers(:powerplant).products.map(&:id).map(&:to_s)
      )
    end
    assert kase.valid?
    assert_difference Kontext, :count, - tiers(:powerplant).products.size do 
      kase.organization = tiers(:luleka)
    end
    kase = Kase.find_by_id(kase.id)
    assert_equal tiers(:luleka), kase.organization
  end

  def test_has_many_tiers_through_kontext
    problem = create_problem
    powerplant = tiers(:powerplant)
    assert problem.valid?
    assert_difference Kontext, :count, 1 do 
      problem.tiers << powerplant
    end
    assert problem.save
    problem.reload
    assert_equal 1, problem.tiers.count
    assert_difference Kontext, :count, -1 do 
      problem.tiers.delete(powerplant)
    end
    problem.reload
    assert_equal 0, problem.tiers.count
  end

  def test_should_get_and_set_tier
    kase = create_idea
    assert_difference Kontext, :count, 1 do
      kase.tier = tiers(:powerplant)
    end
    kase.reload
    assert_equal tiers(:powerplant), kase.tier
    assert_difference Kontext, :count, 0 do
      kase.tier = tiers(:luleka)
    end
    kase.reload
    assert_equal tiers(:luleka), kase.tier
    assert_difference Kontext, :count, -1 do
      kase.tier = nil
    end
    assert_nil kase.tier
  end

  def test_should_get_and_set_tier_id
    kase = create_idea
    assert_difference Kontext, :count, 1 do
      kase.tier_id = "#{tiers(:powerplant).id}"
    end
    kase.reload
    assert_equal tiers(:powerplant).id, kase.tier_id
    assert_difference Kontext, :count, 0 do
      kase.tier_id = tiers(:luleka).id
    end
    kase.reload
    assert_equal tiers(:luleka).id, kase.tier_id
    assert_difference Kontext, :count, -1 do
      kase.tier_id = nil
    end
    assert_nil kase.tier_id
  end

  def test_has_many_organizations_through_kontext
    problem = create_problem
    powerplant = tiers(:powerplant)
    assert problem.valid?
    assert_difference Kontext, :count, 1 do 
      problem.organizations << powerplant
    end
    assert problem.save
    problem.reload
    assert_equal 1, problem.organizations.count
    assert_difference Kontext, :count, -1 do 
      problem.organizations.delete(powerplant)
    end
    problem.reload
    assert_equal 0, problem.organizations.count
  end

  def test_should_get_and_set_organization
    kase = create_idea
    assert_difference Kontext, :count, 1 do
      kase.organization = tiers(:powerplant)
    end
    kase.reload
    assert_equal tiers(:powerplant), kase.organization
    assert_difference Kontext, :count, 0 do
      kase.organization = tiers(:luleka)
    end
    kase.reload
    assert_equal tiers(:luleka), kase.organization
    assert_difference Kontext, :count, -1 do
      kase.organization = nil
    end
    assert_nil kase.organization
  end

  def test_should_get_and_set_organization_id
    kase = create_idea
    assert_difference Kontext, :count, 1 do
      kase.organization_id = "#{tiers(:powerplant).id}"
    end
    kase.reload
    assert_equal tiers(:powerplant).id, kase.organization_id
    assert_difference Kontext, :count, 0 do
      kase.organization_id = tiers(:luleka).id
    end
    kase.reload
    assert_equal tiers(:luleka).id, kase.organization_id
    assert_difference Kontext, :count, -1 do
      kase.organization_id = nil
    end
    assert_nil kase.organization_id
  end

  #--- topics
  
  def test_has_many_topics_through_kontext
    kase = create_idea
    assert kase.valid?
    reaktor = create_product(:name => 'Reaktor', :organization => tiers(:powerplant))
    assert reaktor.valid?
    assert_difference Kontext, :count, 1 do 
      kase.topics << reaktor
    end
    kase.save
    kase = Kase.find_by_id(kase.id)
    assert_equal 1, kase.topics.count
    assert_difference Kontext, :count, -1 do 
      kase.topics.delete(reaktor)
    end
    kase.reload
    assert_equal 0, kase.topics.count
  end

  def test_should_assign_topics_using_topic_ids_with_new_record
    kase = build_kase(:organization => tiers(:powerplant))
    ids = kase.organization.products.active.current_region.map(&:id).map(&:to_s)
    assert_no_difference Kontext, :count do
      kase.topic_ids = ids
    end
    kase.topic_ids.each do |i|
      assert kase.organization.products.map(&:id).include?(i), "topic id #{i} assigned correctly"
    end
    assert_equal kase.organization.products.size, kase.topics.size
  end

  def test_should_get_topics_association
    kase = create_idea(:organization => tiers(:powerplant))
    ids = kase.organization.products.active.current_region.map(&:id).map(&:to_s)
    assert_difference Kontext, :count, ids.size do
      kase.topic_ids = ids
    end
    kase.reload
    kase.topic_ids.each do |id|
      assert kase.organization.products.map(&:id).include?(id), "topic id #{id} present"
    end
    assert_equal kase.organization.products.size, kase.topic_ids.size
  end

  def test_should_get_topics_association_for_new_record
    kase = build_kase(:organization => tiers(:luleka))
    ids = kase.organization.products.active.current_region.map(&:id).map(&:to_s)
    kase.topic_ids = ids
    kase.organization.products.active.current_region.each do |p|
      assert kase.topics.map(&:id).include?(p.id), "kase topic id #{p.id} present"
    end
    assert_equal ids.size, kase.topics.size
  end

  #--- products
   
  def test_has_many_products_through_kontext
    kase = create_idea
    assert kase.valid?
    reaktor = create_product(:name => 'Reaktor', :organization => tiers(:powerplant))
    assert reaktor.valid?
    assert_difference Kontext, :count, 1 do 
      kase.products << reaktor
    end
    kase.save
    kase = Kase.find_by_id(kase.id)
    assert_equal 1, kase.products.count
    assert_difference Kontext, :count, -1 do 
      kase.products.delete(reaktor)
    end
    kase.reload
    assert_equal 0, kase.products.count
  end

  def test_should_assign_products_using_product_ids_with_new_record
    kase = build_kase(:organization => tiers(:powerplant))
    ids = kase.organization.products.active.current_region.map(&:id).map(&:to_s)
    assert_no_difference Kontext, :count do
      kase.product_ids = ids
    end
    kase.product_ids.each do |i|
      assert kase.organization.products.map(&:id).include?(i), "product id #{i} assigned correctly"
    end
    assert_equal kase.organization.products.size, kase.products.size
  end

  def test_should_get_products_association
    kase = create_idea(:organization => tiers(:powerplant))
    ids = kase.organization.products.active.current_region.map(&:id).map(&:to_s)
    assert_difference Kontext, :count, ids.size do
      kase.product_ids = ids
    end
    kase.reload
    kase.product_ids.each do |id|
      assert kase.organization.products.map(&:id).include?(id), "product id #{id} present"
    end
    assert_equal kase.organization.products.size, kase.product_ids.size
  end

  def test_should_get_products_association_for_new_record
    kase = build_kase(:organization => tiers(:luleka))
    ids = kase.organization.products.active.current_region.map(&:id).map(&:to_s)
    kase.product_ids = ids
    kase.organization.products.active.current_region.each do |p|
      assert kase.products.map(&:id).include?(p.id), "kase product id #{p.id} present"
    end
    assert_equal ids.size, kase.products.size
  end

  def test_should_allow_reward
    problem = create_problem
    assert problem.allows_reward?
    assert Problem.allows_reward?
    
    question = create_question
    assert question.allows_reward?
    assert Question.allows_reward?
  end
  
  def test_should_not_allow_reward
    idea = create_idea
    assert !idea.allows_reward?
    assert !Idea.allows_reward?
    
    praise = create_praise
    assert !praise.allows_reward?
    assert !Praise.allows_reward?
  end

  def test_should_return_kind
    assert_equal :question, Question.kind
    assert_equal 'Question', Question.human_name
    assert_equal :question, build_question.kind

    assert_equal :problem, Problem.kind
    assert_equal 'Problem', Problem.human_name
    assert_equal :problem, build_problem.kind

    assert_equal :idea, Idea.kind
    assert_equal 'Idea', Idea.human_name
    assert_equal :idea, build_idea.kind

    assert_equal :praise, Praise.kind
    assert_equal 'Praise', Praise.human_name
    assert_equal :praise, build_praise.kind
  end

  def test_should_return_kind_for_kase
    assert_nil Kase.kind
    assert_equal 'Concern', Kase.human_name
    
    assert_nil build_kase.kind
  end
  
  def test_should_return_klasses
    assert_equal 4, Kase.klasses.size
    [Problem, Question, Idea, Praise].each do |k|
      assert Kase.klasses.include?(k)
    end
  end
  
  def test_should_return_language_code
    kase = build_kase(:person => people(:homer), :language_code => 'ru')
    assert_equal 'ru', kase.language_code

    kase = build_kase(:person => people(:homer))
    assert_equal 'en', kase.language_code
  end

  def test_should_create_tags_with_language_code
    assert_difference Kase, :count do 
      assert_difference Tag, :count, 3 do 
        kase = create_problem(:title => "Test Tags", :person => people(:homer), :language_code => 'es', 
          :tag_list => ["uno", "dos", "tres"])
        assert_equal "es", kase.language_code
        assert kase.tags.any? {|t| t.language_code == "es"}, "should have language code tags"
      end
    end
  end

  def test_should_return_persons_language_code
    kase = build_kase(:person => people(:bart))  # bart speaks german
    assert_equal 'de', kase.language_code
  end

  def test_should_return_current_language_code
    I18n.switch_locale :"es-ES" do
      kase = build_kase(:person => nil)  # bart speaks german
      assert_equal 'es', kase.language_code
    end
  end

  def test_should_assign_severity
    kase = create_idea(:severity => Severity.critical)
    assert kase.valid?
    assert_equal severities(:critical), kase.severity
  end

  def test_should_expire_at
    expiry_date = Time.now.utc + 3.days
    kase = create_problem(:expires_at => expiry_date)
    assert_equal expiry_date.to_i, kase.expires_at.to_i
  end

  def test_should_set_location_with_new_record_and_save
    kase = nil
    location = create_location
    assert_no_difference Kontext, :count do
      kase = build_idea(:location => location)
      assert_equal -122.443287, kase.lng
      assert_equal 37.720592, kase.lat
    end
    assert_equal location, kase.location
    assert_difference Kontext, :count, 1 do
      kase.save
    end
    kase = Kase.find_by_id(kase.id)
    assert_equal location, kase.location
    assert_equal true, kase.location?
    assert_equal -122.443, kase.lng
    assert_equal 37.7206, kase.lat
  end

  def test_should_set_location
    kase = nil
    location = create_location
    assert_difference Kontext, :count, 1 do
      kase = create_idea(:location => location)
      assert_equal -122.443, kase.lng
      assert_equal 37.7206, kase.lat
    end
    assert_equal location, kase.location
    kase = Kase.find_by_id(kase.id)
    assert_equal location, kase.location
    assert_equal -122.443, kase.lng
    assert_equal 37.7206, kase.lat
  end

  def test_should_set_location_to_nil_and_destroy
    kase = nil
    location = create_location
    assert_difference Kontext, :count, 1 do
      kase = create_idea(:location => location)
    end
    assert_equal location, kase.location
    assert_difference Kontext, :count, -1 do
      kase.location = nil
      assert_equal nil, kase.lng
      assert_equal nil, kase.lat
    end
    assert_nil kase.location
    kase = Kase.find_by_id(kase.id)
    assert_nil kase.location
    assert_equal nil, kase.lng
    assert_equal nil, kase.lat
  end

  def test_should_set_location_to_empty_and_destroy
    kase = nil
    location = create_location
    assert_difference Kontext, :count, 1 do
      kase = create_idea(:location => location)
      assert_equal -122.443, kase.lng
      assert_equal 37.7206, kase.lat
    end
    assert_equal location, kase.location
    assert_difference Kontext, :count, -1 do
      kase.location = ''
    end
    assert_nil kase.location
    kase = Kase.find_by_id(kase.id)
    assert_nil kase.location
    assert_equal nil, kase.lng
    assert_equal nil, kase.lat
  end

  def test_should_set_location_to_nil_with_new_record
    kase = nil
    location = create_location
    assert_no_difference Kontext, :count do
      kase = build_idea(:location => location)
      assert_equal -122.443287, kase.lng
      assert_equal 37.720592, kase.lat
    end
    assert_equal location, kase.location
    assert_no_difference Kontext, :count do
      kase.location = nil
      assert_equal nil, kase.lng
      assert_equal nil, kase.lat
      kase.save
    end
    kase = Kase.find_by_id(kase.id)
    assert_nil kase.location
    assert_equal nil, kase.lng
    assert_equal nil, kase.lat
  end

  def test_should_reset_location
    kase = nil
    loc_a = create_location(:street => 'A Street', :lat => 1, :lng => -1)
    loc_b = create_location(:street => 'B Street', :lat => 5, :lng => -5)
    assert_difference Kontext, :count, 1 do
      kase = create_idea(:location => loc_a)
      assert_equal -1, kase.lng
      assert_equal 1, kase.lat
    end
    assert_equal loc_a, kase.location
    assert_no_difference Kontext, :count do
      kase.location = loc_b
      assert_equal -5, kase.lng
      assert_equal 5, kase.lat
    end
    assert_equal loc_b, kase.location
    kase = Kase.find_by_id(kase.id)
    assert_equal loc_b, kase.location
    assert_equal -5, kase.lng
    assert_equal 5, kase.lat
  end

  def test_should_assign_location_as_string_delimited_address
    assert_difference Location, :count do
      assert_difference Kontext, :count do
        kase = build_idea
        kase.location = "100 Rousseau St., San Francisco, CA, 94112, US"
        assert kase.valid?
        kase.save
        assert_equal 37.7206.round(2), kase.location.lat.round(2)
        assert_equal -122.443.round(2), kase.location.lng.round(2)
        assert_equal 37.7206.round(2), kase.lat.round(2)
        assert_equal -122.443.round(2), kase.lng.round(2)
        assert_equal '100 Rousseau St', kase.location.street
        assert_equal 'San Francisco', kase.location.city
        assert_equal 'CA', kase.location.province_code
        assert_equal '94112', kase.location.postal_code
        assert_equal 'US', kase.location.country_code
      end
    end
  end
  
  def test_should_get_geo_location
    kase = build_idea
    kase.location = "100 Rousseau St., San Francisco, CA, 94112, US"
    assert kase.save
    assert geo = kase.geo_location, "should have geo location"
    assert_equal "San Francisco", geo.city
    assert_equal "94112", geo.zip
  end
  
  def test_should_assign_location_as_geo_string_coordinate
    assert_difference Location, :count do
      assert_difference Kontext, :count do
        kase = build_idea
        kase.location = "geo:lat=37.720592 geo:lng=-122.443287"
        assert kase.valid?
        kase.save
        assert_equal 37.7206.round(2), kase.location.lat.round(2)
        assert_equal -122.443.round(2), kase.location.lng.round(2)
      end
    end
  end

  def test_should_be_geo_coded
    idea = build_idea(:lat => 11.222323, :lng => 48.3434)
    assert idea.geo_coded?, "idea should be geocoded"
  end

  def test_should_be_editable
    idea = build_idea
    assert idea.editable?, "new idea should be editable"
  end

  def test_should_be_editable_by
    idea = create_idea
    assert_equal true, idea.valid?
    assert idea.can_be_edited_by?(idea.person), "should be editable by owner"
    assert idea.can_be_edited_by?(people(:aaron).repute_and_return(Reputation::Threshold.edit_post)),
      "should be editable by person with > #{Reputation::Threshold.edit_post} repuation"
    assert idea.can_be_edited_by?(people(:aaron).repute_and_return(Reputation::Threshold.moderate)),
      "should be editable by person with > #{Reputation::Threshold.moderate} repuation"
  end

  def test_should_create_unique_permalinks
    assert_difference Kase, :count, 3 do 
      k1 = create_idea(:title => "welcome")
      k2 = create_idea(:title => "welcome")
      k3 = create_idea(:title => "welcome")
    
      assert "welcome", k1.permalink
      assert "welcome--2", k2.permalink
      assert "welcome--3", k3.permalink
    end
  end

  def test_should_not_be_editable
    idea = create_idea(:created_at => Time.now.utc - 15.minutes)
    assert idea.cancel!
    assert_equal :closed, idea.current_state
    assert !idea.editable?, "should not be editable"
  end

  def test_has_many_clarifications
    assert problem = create_problem
    assert problem.clarifications.empty?
  end

  def test_should_build_clarification_request
    assert_no_difference Clarification, :count do 
      request = build_clarification_request(people(:aaron))
      problem = request.clarifiable
      assert_equal "ClarificationRequest", request.class.name
      assert_equal people(:aaron), request.sender
      assert_equal problem.person, request.receiver
      assert_equal problem, request.clarifiable
      assert_equal "question about your problem", request.message
    end
  end

  def test_should_build_clarification_response
    assert_no_difference ClarificationResponse, :count do 
      request = create_clarification_request(people(:aaron))
      kase = request.clarifiable
      assert response = kase.build_clarification_response(kase.person, :message => "reply to the clarification request"),
        "should build a clarification response"
    end
  end

  def test_should_create_clarification_response
    assert_difference ClarificationResponse, :count do 
      request = create_clarification_request(people(:aaron))
      kase = request.clarifiable
      assert response = kase.create_clarification_response(kase.person, :message => "reply to the clarification request"),
        "should build a clarification response"
      assert response.active?, 'clarification should be active'
      kase.reload
      assert_equal kase, response.clarifiable
      assert_equal kase.person, response.sender
      assert_equal people(:aaron), response.receiver
      assert_equal "reply to the clarification request", response.message
      assert !kase.pending_clarification_requests?, "should not have any pending requests"
    end
  end

  def test_should_create_multiple_clarification_requests_and_responses
    assert_difference ClarificationRequest, :count, 2 do 
      assert_difference ClarificationResponse, :count, 2 do 
        request = create_clarification_request(people(:aaron))
        kase = request.clarifiable
        assert response = kase.create_clarification_response(kase.person, :message => "reply to the clarification request"),
          "should build a clarification response"
        assert response.active?, 'clarification should be active'
        kase.reload
        assert !kase.pending_clarification_requests?, "should not have any pending requests"
        
        assert request = kase.create_clarification_request(people(:aaron), :message => "another request")
        kase.reload
        
        assert_equal request, kase.pending_clarification_request
        assert response = kase.create_clarification_response(kase.person, :message => "another response")
      end
    end
  end
  
  def test_should_not_allow_clarification_request
    assert problem = create_problem
    assert !problem.allows_clarification_request?(problem.person), "should not allow clarification"
  end

  def test_create_clarification_request
    assert_difference Clarification, :count, 2 do 
      request = create_clarification_request(people(:aaron))
      problem = request.clarifiable
      
      assert_equal "ClarificationRequest", request.class.name
      assert_equal people(:aaron), request.sender
      assert_equal problem.person, request.receiver
      assert_equal problem, request.clarifiable
      assert_equal "question about your problem", request.message
      assert_equal request, problem.clarifications.first
      problem.reload
      assert_equal 1, problem.clarification_requests_count
      assert_equal 0, problem.clarification_responses_count
      assert problem.pending_clarification_requests?, 'should have pending clarification request'
      assert problem.allows_clarification_response?(problem.person), 'should clarification reply'
      assert response = request.create_reply(:message => "yes, you are right")
      assert response.valid?, 'response should be valid'
    end
  end
  
  def test_has_many_comments
    assert problem = create_problem
    assert problem.comments.empty?
  end

  def test_build_comment
    assert_no_difference Comment, :count do 
      assert problem = create_problem
      assert problem.allows_comment?(people(:aaron)), "should allow comment"
      assert comment = problem.build_comment(people(:aaron), :message => "comment about your problem")
      assert_equal "Comment", comment.class.name
      assert_equal people(:aaron), comment.sender
      assert_equal problem.person, comment.receiver
      assert_equal problem, comment.commentable
      assert_equal "comment about your problem", comment.message
    end
  end
  
  def test_should_allow_comment
    assert kase = create_problem({
    })
    assert kase.allows_comment?(people(:aaron)), 'should allow comment'
    
    assert kase.activate!
    assert kase.open?, 'kase should be open'
    assert kase.allows_comment?(people(:aaron)), 'should allow comment'
  end

  def test_should_not_allow_comment
    assert kase = create_problem({})
    assert kase.cancel!, "should close kase"
    assert_equal :closed, kase.current_state
    assert !kase.allows_comment?(kase.person), 'should not allow comment of kase person'
    assert !kase.allows_comment?(people(:aaron)), 'should not allow comment on closed discussion'
  end

  def test_create_comment
    Comment.class_eval do
      def repliable?(a_person=nil)
        true
      end
    end
    
    assert_difference Comment, :count, 2 do 
      assert problem = create_problem
      assert problem.allows_comment?(people(:aaron)), "should allow comment"
      assert comment = problem.create_comment(people(:aaron), :message => "comment about your problem")
      assert_equal :active, comment.current_state
      assert_equal "Comment", comment.class.name
      assert_equal people(:aaron), comment.sender
      assert_equal problem.person, comment.receiver
      assert_equal problem, comment.commentable
      assert_equal "comment about your problem", comment.message
      assert_equal comment, problem.comments.first
      assert comment.repliable?, 'comment should be repliable'
      assert reply = comment.create_reply(:message => "reply about your comment")
      assert reply.valid?, 'reply should be valid'
    end
  end

  def test_user_id
    kase = create_problem
    assert_equal kase.person.user.id, kase.user_id
  end
  
  def test_flag_with_user_flags
    kase = create_problem
    user = users(:lisa)
    
    flag = user.flags.create :flaggable => kase, :reason => :spam, :description => "not acceptable spam"
    assert_equal flag, user.flags.first
    assert_equal "not acceptable spam", flag.description
    assert_equal :spam, flag.reason
    assert_equal user.id, flag.user_id
    assert_equal kase.user_id, flag.flaggable_user_id
  end
  
  def test_flag_with_flaggable_add_flag
    kase = create_problem
    user = users(:lisa)
    
    kase.add_flag(:user => user, :reason => :spam, :description => "not acceptable spam")
    flag = kase.flags.first
    assert_equal flag, user.flags.first
    assert_equal "not acceptable spam", flag.description
    assert_equal :spam, flag.reason
    assert_equal user.id, flag.user_id
    assert_equal kase.user_id, flag.flaggable_user_id
  end
  
  def test_find_matching_partners
    assert kase = build_problem(:person => people(:aaron), :title => "reactor exploded")
    kase.tag_with 'powerplants'
    assert kase.save
    partners = kase.find_matching_partners
    assert_equal [people(:homer)], partners
  end
  
  def test_should_has_not_expired?
    assert build_problem(:expires_at => Time.now.utc + 1.hour).has_not_expired?
    assert build_problem(:expires_at => nil).has_not_expired?
  end

  def test_should_not_has_not_expired?
    assert !build_problem(:expires_at => Time.now.utc - 1.hour).has_not_expired?
  end

  def test_should_has_expired?
    assert build_problem(:expires_at => Time.now.utc - 1.hour).has_expired?
  end

  def test_should_not_has_expired?
    assert !build_problem(:expires_at => Time.now.utc + 1.hour).has_expired?
    assert !build_problem(:expires_at => nil).has_expired?
  end

  def test_state_machine_activate_should_open_just_like_that
    kase = create_problem({
      :person => people(:homer),
      :opened_at => Time.now.utc - 180.days,
    })
    assert_equal 0, kase.price_cents
    assert kase.activate!
    assert_equal :open, kase.current_state
  end

  def test_state_machine_activate_should_not_open
    kase = build_problem({
      :person => people(:homer)
    })
    kase.expires_at = Time.now.utc - 1.day
    kase.save(false)
    assert_not_nil kase.expires_at, "expires_at should not be nil"
    assert kase.has_expired?, "time should be expired"
    assert_equal :created, kase.current_state
    assert kase.activate!, "should activate"
    assert_equal :created, kase.current_state, 'should not activate due to kase expired'
  end
  
  def test_state_machine_activate_should_open_with_mailer
    kase = create_problem
    size = ActionMailer::Base.deliveries.size
    kase.activate!
    assert_equal :open, kase.current_state
    assert_equal 1, ActionMailer::Base.deliveries.size - size
    assert_equal "You posted a new Problem about \"A new problem\"", ActionMailer::Base.deliveries.last.subject
  end
  
  def test_state_machine_close_should_close
    kase = create_problem(:expires_at => Time.now.utc - 10.days)
    assert_equal :created, kase.current_state
    size = ActionMailer::Base.deliveries.size
    assert_equal true, kase.cancel!, 'should cancel case'
    assert_equal :closed, kase.current_state
    assert_not_nil kase.closed_at
    assert_equal 1, ActionMailer::Base.deliveries.size - size
    assert_equal "Problem changed from new to closed about \"A new problem\"",
      ActionMailer::Base.deliveries.last.subject
  end
  
  def test_state_machine_cycle_with_probono_and_without_expiry
    kase = Problem.create(valid_kase_attributes)
    assert_equal :created, kase.current_state
    assert_nil kase.expires_at
    assert kase.activate!, 'should activate'
    assert_equal :open, kase.current_state
    assert kase.solve!, 'should solve'
    assert_equal :resolved, kase.current_state
    assert kase.suspend!, 'should suspend'
    assert_equal :suspended, kase.current_state
    assert kase.unsuspend!, 'should unsuspend'
    assert_equal :resolved, kase.current_state
    assert kase.delete!, 'should delete'
    assert_equal :deleted, kase.current_state
  end

  def test_subclass_param_ids
    assert_equal [:question_id, :problem_id, :praise_id, :idea_id].to_set, Kase.subclass_param_ids.to_set
    assert_equal [].to_set, Problem.subclass_param_ids.to_set
  end

  def test_self_and_subclass_param_ids
    assert_equal [:kase_id, :question_id, :problem_id, :praise_id, :idea_id].to_set, Kase.self_and_subclass_param_ids.to_set
    assert_equal [:idea_id].to_set, Idea.self_and_subclass_param_ids.to_set
    assert_equal [:praise_id].to_set, Praise.self_and_subclass_param_ids.to_set
  end
  
  def test_should_build_response
    assert kase = create_problem
    assert kase.activate!, "kase should be activated"
    assert response = kase.build_response(people(:aaron), :description => "this is a great response")
    assert_equal kase, response.kase
    assert_equal people(:aaron), response.person
    assert_equal "this is a great response", response.description
  end

  def test_should_allow_response
    assert kase = create_problem
    assert kase.alive?, "kase should be alive"
    assert kase.activate!, "kase should be activated"
    assert kase.allows_response?, 'should allow response'
    assert kase.allows_response?(kase.person), 'should allow kase onwer to build response'
    assert kase.allows_response?(kase.person), 'should allow kase onwer to build response'
  end

  def test_should_find_all_featured
    assert kase = create_problem(:featured => true)
    assert kase.valid?, "kase should be valid"
    assert_equal [kase], Kase.find_all_featured
  end

  def test_should_happened_at_with_user_time_zone
    happened_at = Time.now.utc + 3.days
    kase = create_problem(:happened_at => happened_at)
    assert_equal kase.person.user.user2utc(happened_at).to_i, kase.happened_at.to_i
  end

  def test_should_comments_count
    kase = create_problem
    assert_equal 0, kase.comments_count
  end

  def test_acts_as_visitable
    assert visitable = create_problem
    assert visitable.visits_count_column?
    assert visitable.views_count_column?
    
    assert viewer = people(:barney)
    assert visitable.visit(viewer)
    assert_equal 1, visitable.visits_count
    assert_equal 1, visitable.views_count

    assert visitable.view(viewer)
    assert_equal 1, visitable.visits_count
    assert_equal 2, visitable.views_count
  end

  def test_acts_as_voteable
    assert voteable = create_problem
    assert voteable.votes_sum_column?
    assert voteable.votes_count_column?
    assert voteable.up_votes_count_column?
    assert voteable.down_votes_count_column?
    
    assert voter = people(:barney)
    
    assert voteable.vote_up(voter)
    assert_equal 1, voteable.votes_count
    assert_equal 1, voteable.up_votes_count
    assert_equal 0, voteable.down_votes_count
    assert_equal 1, voteable.votes_sum
  end

  def test_finder
    assert_equal :find_by_permalink, Kase.finder_name
    assert_equal kases(:powerplant_leak), Kase.finder('powerplant-leak')
  end

  def test_self_and_subclasses
    assert_equal ["Kase", "Question", "Problem", "Praise", "Idea"].to_set, Kase.self_and_subclasses.map(&:name).to_set
  end
  
  def test_should_find_matching_kases
    assert_difference Kase, :count, 3 do 
      problem = create_problem
      assert problem.activate!
      problem = tag_record_with(problem, ["one", "two", "three"])
      
      # yes, this on is in
      idea = create_idea
      assert idea.activate!
      idea = tag_record_with(idea, ["three", "four", "five"])

      # ...not match this one at is is not activated
      question = create_question
      question = tag_record_with(question, ["three", "four", "five"])
      
      matches = problem.find_matching_kases
      
      assert_equal [idea], matches
    end    
  end

  def test_should_not_find_matching_kases
    assert_difference Kase, :count, 3 do 
      problem = create_problem
      assert problem.activate!
      problem = tag_record_with(problem, ["one", "two", "three"])
      
      # no, this on doesnt have matching tags
      idea = create_idea
      assert idea.activate!
      idea = tag_record_with(idea, ["four", "five"])

      # ...not this one is not activated
      question = create_question
      question = tag_record_with(question, ["three", "four", "five"])
      
      assert_equal [], matches = problem.find_matching_kases
    end    
  end

  def test_find_matching_people
    assert_difference Kase, :count do 
      marge = people(:marge)  # partner
      marge = tag_record_with(marge, ["five", "six"])
      
      barney = people(:barney)  # member
      barney = tag_record_with(barney, ["three", "six"])
    
      problem = create_problem
      assert problem.activate!
      problem = tag_record_with(problem, ["one", "two", "three"])

      assert_equal [barney], problem.find_matching_people
    end
  end
  
  def test_find_matching_partners
    assert_difference Kase, :count do 
      marge = people(:marge)  # partner
      marge = tag_record_with(marge, ["three", "six"], 'have_expertises')
      
      barney = people(:barney)  # member
      barney = tag_record_with(barney, ["three", "six"])
    
      problem = create_problem
      assert problem.activate!
      problem = tag_record_with(problem, ["one", "two", "three"])

      assert_equal [marge], problem.find_matching_partners
    end
  end

  def test_should_have_or_can_edit_location?
    problem = create_problem
    assert problem.has_or_can_edit_location?(problem.person), "can edit location"
    
    problem.location = "geo:lat = 1.1 geo:lon = -1.1"
    assert problem.location, "should have a location now"
    assert problem.has_or_can_edit_location?(people(:barney)), "can edit location"
  end

  def test_should_not_have_or_can_edit_location?
    problem = create_problem
    assert !problem.has_or_can_edit_location?, "should return false as there is no location"
    assert !problem.has_or_can_edit_location?(people(:barney)), "barney should not be able to edit location"
  end
  
  def test_simple_find_by_query
    assert_equal kases(:powerplant_leak), Kase.find_by_query(:first, 'Powerplant leak')
  end
  
  def test_should_create_with_email_and_without_person
    assert_difference Kase, :count do 
      kase = Problem.create(valid_kase_attributes(:person => nil, :sender_email => "hansel@gretel.tst"))
      assert_equal :created, kase.current_state
      assert_equal "hansel@gretel.tst", kase.sender_email
      
      assert kase.activation_code, "should have an activation code"
      assert_nil kase.published_at, "should not be activated"
      
      assert_equal 1, ActionMailer::Base.deliveries.size
      assert ActionMailer::Base.deliveries.last.subject =~ /Publish your case/i, "should send an activation link"
    end
  end

  def test_should_not_create_without_person
    assert_no_difference Kase, :count do 
      kase = Problem.create(valid_kase_attributes(:person => nil))
    end
  end

  def test_should_not_activate_without_person_and_email
    assert_difference Kase, :count do 
      kase = Problem.create(valid_kase_attributes(:person => nil, :sender_email => "homer@simpson.tt"))
      kase.activate!
      assert_equal :created, kase.current_state
    end
  end

  def test_should_not_activate_without_matching_email
    assert_difference Kase, :count do 
      kase = Problem.create(valid_kase_attributes(:person => nil, :sender_email => "no@match.tt"))
      kase.person = people(:homer)
      
      kase.activate!
      assert_equal :created, kase.current_state

      assert !kase.valid?, "kase should not be valid"
      assert_equal "activation (no@match.tt) does not match your email (homer@simpson.tt)", kase.errors.on(:sender_email)
    end
  end
  
  def test_should_activate_with_person_and_email
    assert_difference Kase, :count do 
      kase = Problem.create(valid_kase_attributes(:person => nil, :sender_email => "homer@simpson.tt"))
      kase.person = people(:homer)

      kase.activate!
      assert_equal :open, kase.current_state

      assert kase.valid?, "should be valid"

      assert kase.published_at, "should set published_at time"
      assert_nil kase.sender_email, "should remove email"
    end
  end

  def test_should_update_associated_count
    assert_difference Tier, :count do 
      assert_difference Topic, :count do 
        assert_difference Kase, :count do 
          tier = create_tier
          topic = create_topic(:tier => tier)
          kase = create_problem({:tier => tier, :topics => [topic], :person => people(:quentin)})
          kase_person = kase.person
          assert kase_person, "kase should have a person associated"
          kase.activate!
          assert :open, kase.current_state
          tier.reload
          topic.reload
          kase_person.reload
          assert_equal 1, tier.kases_count
          assert_equal 1, topic.kases_count
          assert_equal 1, tier.people_count
          assert_equal 1, topic.people_count
          assert_equal 1, kase_person.kases_count
          kase.suspend!
          tier.reload
          topic.reload
          assert_equal 0, tier.kases_count
          assert_equal 0, topic.kases_count
          assert_equal 0, tier.people_count
          assert_equal 0, topic.people_count
          assert_equal 0, kase_person.kases_count
        end
      end
    end
  end

  def test_should_have_rewards_count
    kase = build_problem
    assert_equal true, kase.respond_to?(:rewards_count)
    assert_equal 0, kase.rewards_count
  end
  
  def test_should_have_price
    person = people(:homer)
    kase = create_problem(:person => person)
    assert_equal Money.new(0, person.default_currency), kase.price
  end

  def test_should_be_owner_only_offers_reward
    kase = create_problem(:person => people(:homer))
    assert_equal true, kase.activate!, "should activate kase"
    rw1 = create_reward(:kase => kase, :expires_at => Time.now.utc + 2.days,
      :sender => people(:homer).direct_deposit_and_return("1.00"))
    assert_equal true, rw1.activate!, "should activate reward 1"
    assert_equal true, kase.owner_only_offers_reward?, "should only be owner offering reward"
  end

  def test_should_not_be_owner_only_offers_reward
    kase = create_problem(:person => people(:homer))
    assert_equal true, kase.activate!, "should activate kase"
    rw1 = create_reward(:kase => kase, :expires_at => Time.now.utc + 2.days,
      :sender => people(:homer).direct_deposit_and_return("1.00"))
    assert_equal true, rw1.activate!, "should activate reward 1"
    assert_equal true, kase.owner_only_offers_reward?, "rw1 should be only reward offered by owner"
    rw2 = create_reward(:kase => kase, 
      :sender => people(:lisa).direct_deposit_and_return("2.00"))
    assert_equal true, kase.owner_only_offers_reward?, 
      "rw1 should be only reward offered by owner, since rw2 has not been activated"
    assert_equal true, rw2.activate!, "should activate reward 2"
    assert_equal false, kase.owner_only_offers_reward?, 
      "should not be only rewarded by owner"
  end

  def test_should_expire_and_solve
    kase = create_problem_with_3_rewards_and_2_responses
    rs1, rs2 = kase.responses
    rw1, rw2, rw3 = kase.rewards
    
    rs1.vote_down(people(:homer))
    rs1.vote_up(people(:lisa))
    rs2.vote_up(people(:homer))
    rs2.vote_up(people(:barney))
    assert_equal 1, rs1.up_votes_count
    assert_equal 0, rs1.votes_sum
    assert_equal 2, rs2.up_votes_count
    assert_equal 2, rs2.votes_sum
  
    pretend_now_is Time.now.utc + 2.days + 1.minute do
      assert_equal true, rw1.has_expired?
      assert_equal true, rw2.has_expired?
      assert_equal true, rw3.has_expired?
      kase.reload
      kase.expire!
      assert_equal :resolved, kase.current_state, "should be resolved"
      assert_equal true, kase.has_accepted_response?, "should have one accepted response"
    end
    # 6.34 USD - 20%
    assert_equal Money.new(507, "USD"), rs2.person.piggy_bank.balance
  end

  def test_should_expire_and_cancel
    kase = create_problem_with_3_rewards_and_2_responses
    rs1, rs2 = kase.responses
    rw1, rw2, rw3 = kase.rewards
    
    rs1.vote_down(people(:homer))
    rs1.vote_up(people(:lisa))
    rs2.vote_down(people(:homer))
    rs2.vote_up(people(:barney))
    assert_equal 1, rs1.up_votes_count
    assert_equal 0, rs1.votes_sum
    assert_equal 1, rs2.up_votes_count
    assert_equal 0, rs2.votes_sum
  
    pretend_now_is Time.now.utc + 2.days + 1.minute do
      assert_equal true, rw1.has_expired?
      assert_equal true, rw2.has_expired?
      assert_equal true, rw3.has_expired?
      kase.reload
      kase.expire!
      assert_equal :closed, kase.current_state, "should be closed"
      assert_equal false, kase.has_accepted_response?, "should have no accepted responses"
    end
  end
  
  def test_should_repute_vote_up
    kase = kases(:powerplant_leak)
    sender = people(:bart).repute_and_return(15)
    reputation = kase.repute_vote_up(sender)
    assert_equal true, reputation.success?
    kase.person.reload
    assert_equal 5, kase.person.reputation_points
  end

  def test_should_cancel_repute_vote_up
    kase = kases(:powerplant_leak)
    sender = people(:bart).repute_and_return(15)
    reputation = kase.repute_vote_up(sender)
    assert_equal true, reputation.success?
    reputation = kase.cancel_repute_vote_up(sender)
    assert_equal true, reputation.success?
    kase.person.reload
    assert_equal 0, kase.person.reputation_points
  end

  def test_should_repute_vote_down
    kase = kases(:powerplant_leak)
    receiver = kase.person.repute_and_return(5)
    sender = people(:bart).repute_and_return(100)
    reputation = kase.repute_vote_down(sender)
    assert_equal true, reputation.success?
    receiver.reload
    sender.reload
    assert_equal 3, receiver.reputation_points
    assert_equal 99, sender.reputation_points
  end

  def test_should_cancel_repute_vote_down
    kase = kases(:powerplant_leak)
    receiver = kase.person.repute_and_return(5)
    sender = people(:bart).repute_and_return(100)
    reputation = kase.repute_vote_down(sender)
    assert_equal true, reputation.success?
    reputation = kase.cancel_repute_vote_down(sender)
    assert_equal true, reputation.success?
    receiver.reload
    sender.reload
    assert_equal 5, receiver.reputation_points
    assert_equal 100, sender.reputation_points
  end

  def test_should_not_cancel_repute_vote_down
    kase = kases(:powerplant_leak)
    receiver = kase.person.repute_and_return(5)
    sender = people(:bart).repute_and_return(100)
    reputation = kase.cancel_repute_vote_down(sender)
    assert_equal nil, reputation
    receiver.reload
    sender.reload
    assert_equal 5, receiver.reputation_points
    assert_equal 100, sender.reputation_points
  end

  def test_should_max_reward_price
    kase = kases(:powerplant_leak)
    assert_nil kase.max_reward_price, "should not have a max reward price"
    rw1 = create_reward(:sender => people(:marge).direct_deposit_and_return("1.00"), :price => "1.00")
    assert_equal true, rw1.activate!
    assert_equal Money.new(100, "USD"), kase.max_reward_price
    rw2 = create_reward(:sender => people(:bart).direct_deposit_and_return("1.00"), :price => "1.00")
    assert_equal true, rw2.activate!
    assert_equal Money.new(134, "USD"), kase.max_reward_price
    rw3 = build_reward(:sender => people(:lisa).direct_deposit_and_return("1.00"), :price => "1.00")
    assert_equal Money.new(134, "USD"), kase.max_reward_price
  end

  def test_should_create_and_activate_with_guest_user
    create_kase_with_guest_user
    assert_nil @kase.person, "kase should not have person assigned"
    assert_equal true, @user.register!, "should register"
    @user.person.build_personal_address(valid_address_attributes)
    @user.not_guest!
    assert_equal true, @user.activate!, "should activate"
    @kase.reload
    @user.reload
    assert_equal true, @kase.active?, "should be activated through user activation"
    assert_equal @kase, @user.person.kases.first, "should have kase assigned"
    assert_equal @kase.person, @user.person, "should have person assigned"
    # 3 emails: (1) Account Confirmation, (2) Welcome Email!, (3) Posted new Kase Email!
    assert_equal 3, ActionMailer::Base.deliveries.size
  end

  def test_should_match_kases_with_person_and_have_expertise
    p1 = people(:homer)
    p2 = people(:marge)
    p1.have_expertise = "iphone, powerplant, family"
    assert_equal true, p1.save, "should save have expertise"

    k1 = create_problem(:title => "When will the iPhone 4 be availabe in Argentina?", 
      :tag_list => "apple, iphone", :person => p2, :language_code => "en")
    assert_equal [], Kase.find_matching_kases_for_person(p1), "should not match invisible kase"
    assert k1.activate!, "should activate"
    assert_equal [k1], Kase.find_matching_kases_for_person(p1), "should match kase"
  end

  def test_should_match_kases_with_person_and_have_expertise_and_spoken_language
    p1 = people(:homer)
    p2 = people(:marge)
    p1.have_expertise = "iphone, powerplant, family"
    assert_equal true, p1.save, "should save have expertise"

    k1 = create_problem(:title => "When will the iPhone 4 be availabe in Argentina?", 
      :tag_list => "apple, iphone", :person => p2, :language_code => "de")
    assert k1.activate!, "should activate"
    assert_equal [], Kase.find_matching_kases_for_person(p1), "should not match kase although have expertise matches"
    
    p3 = people(:aaron)
    p3.have_expertise = "german, dude, apple"
    assert_equal true, p3.save, "should save aaron's have expertise"
    assert_equal [k1], Kase.find_matching_kases_for_person(p3), "should match kase due to spoken language and have expertise"
  end

  def test_should_match_kases_with_person_and_similar_kase_responses_voted_up
    p1 = people(:homer)
    p2 = people(:marge)

    k1 = create_problem(:title => "This is a previous problem with iPhone to be answered by Homer", 
      :tag_list => "apple, iphone", :person => p2, :language_code => "en")
    assert k1.activate!, "should activate kase"

    r1 = create_response(:kase => k1, :person => p1)
    assert r1.activate!, "should activate Homer's response"

    assert_equal [], Kase.find_matching_kases_for_person(p1), "should not match kase without credible up votes"
    assert r1.vote_up(people(:lisa))
    assert r1.vote_up(people(:barney))
      
    assert_equal [k1], Kase.find_matching_kases_for_person(p1), "should match kase with credible up votes"
  end

  def test_should_normalize_permalink
    I18n.switch_locale :"en-US" do
      k1 = create_problem(:title => "Jürgen Feßlmeier the 1st", :language_code => "en")
      assert_equal "jurgen-fesslmeier-the-1st", k1.permalink
    end

    I18n.switch_locale :"de-DE" do
      k2 = create_problem(:title => "Jürgen Feßlmeier der Erste", :language_code => "de")
      assert_equal "juergen-fesslmeier-der-erste", k2.permalink
    end
  end

  protected
  
  def tag_record_with(record, tags, context=nil)
    if context
      record.tag_with(tags, :attribute => context)
    else
      record.tag_with(tags)
    end
    record.save!
    record.reload
    record
  end
  
  def build_clarification_request(sender, request_options={:message => "question about your problem"},
    kase_options={})
    
    assert kase = create_problem(kase_options)
    assert kase.activate!, 'kase should activate'
    assert kase.allows_clarification_request?(sender), "should allow clarification"
    assert request = kase.build_clarification_request(sender, request_options), "should create a clarification request"
    request
  end

  def create_clarification_request(sender, request_options={:message => "question about your problem"},
    kase_options = {})
    
    assert kase = create_problem(kase_options)
    assert kase.activate!, 'kase should activate'
    assert kase.allows_clarification_request?(sender), "should allow clarification"
    assert request = kase.create_clarification_request(sender, request_options), "should create a clarification request"
    request.clarifiable.reload
    request
  end
  
  def create_problem_with_3_rewards_and_2_responses(expires_at=Time.now.utc + 2.days)
    kase = nil
    assert_difference Kase, :count, 1 do
      assert_difference Reward, :count, 3 do
        assert_difference Response, :count, 2 do
          
          kase = create_problem(:person => people(:homer))
          assert_equal true, kase.activate!, "should activate kase"
          assert_nil kase.expires_at, "expires_at should be nil"
    
          # 1 EUR * 1.3448 = 1.34 USD
          rw1 = create_reward(:kase => kase, :expires_at => expires_at, :price => "1.00",
            :sender => people(:bart).direct_deposit_and_return("1.00"))
          assert_equal true, rw1.activate!, "should activate reward 1"
          # 2.00 USD
          rw2 = create_reward(:kase => kase, :price => "2.00",
            :sender => people(:lisa).direct_deposit_and_return("2.00"))
          assert_equal true, rw2.activate!, "should activate reward 2"
          # 3.00 USD
          rw3 = create_reward(:kase => kase, :price => "3.00",
            :sender => people(:marge).direct_deposit_and_return("3.00"))
          assert_equal true, rw3.activate!, "should activate reward 3"
          assert_equal rw1.expires_at.to_i, rw2.expires_at.to_i, "should expire at the same time rw1 and rw2"
          assert_equal rw2.expires_at.to_i, rw3.expires_at.to_i, "should expire at the same time rw2 and rw3"

          rs1 = create_response(:kase => kase, :person => people(:quentin))
          assert_equal true, rs1.activate!, "should activate response 1"
          rs2 = create_response(:kase => kase, :person => people(:aaron))
          assert_equal true, rs2.activate!, "should activate response 1"
        end
      end
    end
    kase
  end

  def create_kase_with_guest_user
    @user = User.new(:login => "guest", :email => "guest@user.tt", :email_confirmation => "guest@user.tt")
    @user.guest!
    @kase = Problem.new(:title => "Guest User?", :description => "Don't like guest users, but they are necessary!",
      :tag_list => "guest, user", :person => nil, :sender_email => @user.email)
    assert_equal true, @user.save, "user should be valid"
    assert_equal true, @kase.save, "kase should be valid"
    @user
  end

end
