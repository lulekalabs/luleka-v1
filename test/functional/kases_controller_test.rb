require File.dirname(__FILE__) + '/../test_helper'
require 'kases_controller'

# Re-raise errors caught by the controller.
class KasesController; def rescue_action(e) raise e end; end

class KasesControllerTest < Test::Unit::TestCase
  all_fixtures

  def setup
    @controller = KasesController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new

    @request.with_subdomain('us')

    Location.stubs(:geocode).returns(valid_geo_location)

    login_as :homer
    people(:homer).piggy_bank.direct_deposit(Money.new(2000, 'USD'))
  end

  def test_security
    logout
    assert_requires_login :index
    assert_requires_login :show
  end

  def test_should_get_index
    get :index
    assert_response :success
    assert assigns(:kases)
  end

  def test_should_get_active
    get :active
    assert_response :success
    assert assigns(:kases)
  end

  def test_should_get_open
    get :open
    assert_response :success
    assert assigns(:kases)
  end

  def test_should_get_popular
    get :popular
    assert_response :success
    assert assigns(:kases)
  end

  def test_should_get_index_with_category
    get :index, :category_id => categories(:business).permalink
    assert_response :success
    assert assigns(:category)
    assert assigns(:kases)
  end

  def test_should_get_index_with_tag
    get :index, :tag_id => tags(:beer).name
    assert_response :success
    assert assigns(:kases)
  end

  def test_should_get_index_with_category
    get :index, :category_id => categories(:business).permalink
    assert_response :success
    assert assigns(:category)
    assert assigns(:kases)
  end

  def test_should_get_list_item_expander
    logout
    kase = create_problem
    xhr :get, :list_item_expander, :id => kase.permalink
    assert_response :success
    assert assigns(:kase)
    assert_template 'kases/_list_item_content'
  end

  def test_should_get_new
    get :new
    assert :success
    assert assigns(:kase)
    assert assigns(:user)
    assert assigns(:person)
  end

  def test_should_create_simple_problem
    assert_difference Kase, :count do
      post :create, {"kase"=>{"kind"=>"problem", "title"=>"simple problem", "offer"=>"probono", "description"=>"simple problem description", "tag_list"=>"simple problem", "category_s"=>"business > accounting > deprecations", "severity_id"=>"1", "language_code"=>"en"}}
    end
    assert_response :redirect
    assert kase = assigns(:kase)
    assert_equal :problem, kase.kind
    assert_equal 'simple problem', kase.title
    assert_equal :probono, kase.offer
    assert_equal 'simple problem description', kase.description
    assert_equal ['simple problem'], kase.tag_list
    assert_equal 'en', kase.language_code
    assert_equal 'business > accounting > deprecations', kase.category.to_s
    assert_equal Severity.trivial, kase.severity
  end

  def test_should_not_create_simple_problem_missing_category
    assert_no_difference Kase, :count do
      post :create, {"kase"=>{"kind"=>"problem", "title"=>"simple problem", "offer"=>"probono", "description"=>"simple problem description", "tag_list"=>"simple problem", "category_s"=>"", "severity_id"=>"1", "language_code"=>"en"}}
    end
    assert_response :success
    assert kase = assigns(:kase)
    assert !kase.valid?
  end

  def test_should_not_create_simple_kase_due_missing_kind
    assert_no_difference Kase, :count do
      post :create, {"kase"=>{"title"=>"my beauty kase", "offer"=>"probono", "description"=>"kase description", "tag_list"=>"kase", "category_s"=>"business > accounting > deprecations", "severity_id"=>"1", "language_code"=>"en"}}
    end
    assert_response :success
    assert kase = assigns(:kase)
    assert !kase.valid?
    assert_equal "Select Problem, Question, Praise, and Idea.", kase.errors.full_messages.first
  end

  def test_should_create_question_about_an_organziation
    assert_difference Kontext, :count do
      assert_difference Kase, :count do
        post :create, {"kase"=>{"kind"=>"question", "organization_id"=>"1", "title"=>"organization question", "description"=>"organization question description", "tag_list"=>"organization question", "category_s"=>"business > accounting > deprecations", "severity_id"=>"1", "language_code"=>"de", "offer"=>"probono"}}
      end
    end
    assert_response :redirect
    assert kase = assigns(:kase)
    assert_equal 'de', kase.language_code
    assert_equal :question, kase.kind
    assert_equal tiers(:powerplant), kase.organization
  end

  def test_should_create_praise_about_an_organziation_and_products
    assert_difference Kontext, :count, 3 do
      assert_difference Kase, :count do
        post :create, {"kase"=>{"kind"=>"praise", "organization_id"=>"1", "product_ids" => ["32", "33"], "title"=>"organization praise about products", "description"=>"organization praise about products description", "tag_list"=>"organization praise products", "category_s"=>"business > accounting > deprecations", "severity_id"=>"1", "language_code"=>"de", "offer"=>"probono"}}
      end
    end
    assert_response :redirect
    assert kase = assigns(:kase)
    assert_equal 'de', kase.language_code
    assert_equal :praise, kase.kind
    assert_equal tiers(:powerplant), kase.organization
    assert_equal 2, kase.products.size
    assert kase.products.include?(topics(:bolt))
    assert kase.products.include?(topics(:electricity))
  end

  def test_should_create_idea_about_a_location
    assert_difference Kontext, :count, 1 do
      assert_difference Kase, :count do
        post :create, {"kase"=>{"kind"=>"idea", "location"=>"100 rousseau st, san francisco", "title"=>"location idea", "description"=>"location idea description", "tag_list"=>"location idea", "category_s"=>"business > accounting > deprecations", "severity_id"=>"2", "language_code"=>"en", "offer"=>"probono"}}
        assert_response :redirect
        assert kase = assigns(:kase)
        assert_equal :idea, kase.kind
        assert kase.location
        assert_equal 37.7206, kase.location.lat
        assert_equal -122.443, kase.location.lng
      end
    end
  end

  def test_should_create_problem_with_reward_with_piggy_bank_payment_method
    assert_difference Kase, :count do
      assert_difference Order, :count do
        assert_difference Invoice, :count do
          assert_difference LineItem, :count do
            post :create, {"payment_method"=>"piggy_bank", "kase"=>{"kind"=>"problem", "expiry_days"=>"3", "expiry_option"=>"in", "offer"=>"fixed", "description"=>"problem with reward", "fixed_price_s"=>"$5.00", "title"=>"problem with reward", "tag_list"=>"problem offer reward", "category_s"=>"business > accounting > deprecations", "severity_id"=>"1", "language_code"=>"en"}}
          end
        end
      end
    end
    assert_response :redirect
    assert kase = assigns(:kase)
#    assert order = assigns(:order)
#    assert payment = assigns(:payment)
    assert_equal Money.new(500, 'USD'), kase.fixed_price
#    assert_equal Money.new(500, 'USD'), order.gross_total
    assert_equal Money.new(1500, 'USD'), people(:homer).piggy_bank.available_balance
#    assert payment.is_a?(PiggyBankPayment)
#    assert_equal true, payment.success?
    assert_equal :fixed, kase.offer
#    assert_not_nil kase.payment_object
  end

  def xtest_should_create_question_with_reward_with_credit_card_payment_method
    assert_difference Kase, :count do
      assert_difference Order, :count do
        assert_difference Invoice, :count do
          assert_difference LineItem, :count do
            post :create, {"payment_method"=>"bogus", "bogus"=>{"month"=>"2", "number"=>"1", "verification_value"=>"000", "year"=>"#{Date.today.year + 1}", "first_name"=>"Homer", "last_name"=>"Simpson"}, "kase"=>{"kind"=>"question", "expiry_days"=>"7", "expiry_option"=>"in", "offer"=>"fixed", "description"=>"question with reward", "fixed_price_s"=>"$5.00", "title"=>"question with reward", "tag_list"=>"question offer reward", "category_s"=>"business > accounting > deprecations", "severity_id"=>"1", "language_code"=>"en"}}
          end
        end
      end
    end
    assert_response :redirect
    assert kase = assigns(:kase)
    assert order = assigns(:order)
    assert payment = assigns(:payment)
    assert_equal Money.new(500, 'USD'), kase.fixed_price
    assert_equal true, payment.success?, 'payment success'
    assert_equal Money.new(500, 'USD'), order.gross_total
    assert payment.is_a?(CreditCardPayment)
    assert_equal :fixed, kase.offer
    assert_not_nil kase.payment_object
  end

  def test_should_not_create_idea_with_reward
    assert_no_difference Kase, :count do
      assert_no_difference Order, :count do
        assert_no_difference Invoice, :count do
          assert_no_difference LineItem, :count do
            post :create, {"payment_method"=>"piggy_bank", "kase"=>{"kind"=>"idea", "expiry_days"=>"3", "expiry_option"=>"in", "offer"=>"fixed", "description"=>"problem with reward", "fixed_price_s"=>"$5.00", "title"=>"problem with reward", "tag_list"=>"problem offer reward", "category_s"=>"business > accounting > deprecations", "severity_id"=>"1", "language_code"=>"en"}}
          end
        end
      end
    end
    assert_response :success
    assert kase = assigns(:kase)
    assert !kase.errors.empty?, "idea can not have a reward"
  end

  def test_should_get_show
    get :show, :id => kases(:probono_problem).permalink
    assert_response :success
  end

  def test_should_get_show_with_tier
    get :show, :id => kases(:powerplant_leak).permalink
    assert_response :redirect
    assert_equal kases(:powerplant_leak), @kase = assigns(:kase)
    assert_redirected_to organization_question_path(@kase.tier, @kase)
  end

  def test_should_post_and_remember_tier_and_topic
    post :create, {"company_id"=>"luleka", "product_id"=>"three-month-partner-membership",
      "kase"=>{"kind"=>"idea", "title"=>"location idea", "severity_id"=>"2", "language_code"=>"en", "offer"=>"probono"}}
    assert_response :success, "should not validate but assign topic and tiers"
    assert kase = assigns(:kase)
    assert_equal :idea, kase.kind
    assert_equal tiers(:luleka), tier = assigns(:tier)
    assert_equal topics(:three_month_partner_membership_en), topic = assigns(:topic)
  end
  
end
