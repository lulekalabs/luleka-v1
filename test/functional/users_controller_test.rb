require File.dirname(__FILE__) + '/../test_helper'
require 'users_controller'

# Re-raise errors caught by the controller.
class UsersController; def rescue_action(e) raise e end; end

class UsersControllerTest < Test::Unit::TestCase
  all_fixtures
  
  ROOT = File.join(File.dirname(__FILE__), '..')

  def setup
    @controller = UsersController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new

    @request.with_subdomain('us')

    logout
  end

  def test_security
    logout
    assert_requires_login :edit
    assert_requires_login :update
    assert_requires_login :complete
  end
  
  def test_should_route_new
    assert_routing '/user/new', hash_for_path(:new_user)
  end
  
  def test_should_get_new
    get :new
    assert_response :success
    assert_template 'new'
    assert assigns(:user)
  end

  def test_should_get_new_with_invitation
    @invitation = Invitation.create(
      :invitor => people(:homer),
      :first_name => 'Simon',
      :last_name => 'Garfunkel',
      :email => "simon@garfunkel.tst",
      :with_voucher => true
    )
    assert @invitation.send!
    self.current_invitation = @invitation
    get :new
    assert_response :success, 'should get new'
    assert @user = assigns(:user)
    assert @invitation = assigns(:invitation)
    assert "simon@garfunkel.tst", @user.email
  end

  def test_should_route_create_user
    assert_recognizes(hash_for_path(:user, :action => 'create'), {:path => '/user', :method => :post})
  end

  def test_should_route_confirm_user
    assert_routing 'user/confirm/:login/:activation_code',
      hash_for_path(:confirm_user, {:login => ':login', :activation_code => ':activation_code'})
  end
  
  def test_should_post_create
    post :create, {"user"=>{"language"=>"en", "password_confirmation"=>"adam", "gender"=>"m", "terms_of_service"=>"1", "verification_code"=>"want2test", "time_zone"=>"Pacific Time (US & Canada)", "login"=>"adam", "password"=>"adam", "email"=>"adam@smith.tst", "currency"=>"USD"}, "action"=>"create", "controller"=>"users"}
    assert_response :redirect
    assert_redirected_to confirm_user_path
    assert @user = assigns(:user)
    assert @response.has_flash?
    assert ActionMailer::Base.deliveries.last.body.include?(@user.activation_code)
  end

  def test_should_not_post_create
    post :create, {"user"=>{}}
    assert_template 'new'
    assert @user = assigns(:user)
    assert_not_equal 0, @user.errors.size
  end

  def test_should_not_post_create_with_invalid_verification_code
    post :create, {"user"=>{"language"=>"en", "password_confirmation"=>"adam", "gender"=>"m", "terms_of_service"=>"1", "verification_code"=>"XXXXXXX", "time_zone"=>"Pacific Time (US & Canada)", "login"=>"adam", "password"=>"adam", "email"=>"adam@smith.tst", "currency"=>"USD"}, "action"=>"create", "controller"=>"users"}
    assert_template 'new'
    assert @user = assigns(:user)
    assert @user.errors.on(:verification_code)
  end
  
  def test_should_get_confirm_with_registering_user
    @user = create_user
    assign_current_registering_user(@user)
    get :confirm
    assert_response :success
    assert_template 'confirm'
  end
  
  def test_should_route_resend_user
    assert_recognizes hash_for_path(:resend_user), {:path => '/user/resend', :method => :post}
  end
  
  def test_should_resend_confirmation_request
    @user = create_user(:login => "resendsmith", :email => "resendsmith@smith.tst")
    assert @user.register!
    activation_code = @user.activation_code
    assert activation_code
    post :resend, {"user" => {"login" => "resendsmith", "email" => "resendsmith@smith.tst"}}
    assert_response :redirect
    assert @response.has_flash?
    assert_redirected_to confirm_user_path
    assert @user = assigns(:user)
    assert_not_equal activation_code, @user.activation_code
    assert ActionMailer::Base.deliveries.last.body.include?(@user.activation_code)
  end

  def test_should_not_resend_confirmation_request
    @user = create_user(:login => "resendsmith", :email => "resendsmith@smith.tst")
    assert @user.register!
    post :resend, {"user" => {"login" => "spellingmistakeresendsmith", "email" => "resendsmith@smith.tst"}}
    assert_response :success
    assert @response.has_flash?
    assert_template 'resend'
  end
  
  def test_should_get_confirm_with_activation_code
    @user = create_user
    assert @user.register!
    get :confirm, {"login" => "#{@user.login}", "activation_code" => "#{@user.activation_code}"}
    assert_response :success
    assert_template 'confirm'
    assert !@response.body.include?('errors')
  end

  def test_should_get_confirm_with_wrong_activation_code
    @user = create_user
    assert @user.register!
    get :confirm, {"login" => "#{@user.login}", "activation_code" => "XXXXXXXXXXXXXX"}
    assert_response :redirect
    assert_redirected_to new_user_path
  end

  def test_should_route_activate_user
    assert_recognizes hash_for_path(:activate_user), {:path => '/user/activate', :method => :post}
  end

  def test_should_post_activate_with_valid_activation_code
    @user = create_user
    assert @user.register!
    post :activate, {"id" => "#{@user.login}", "user" => {"activation_code_confirmation" => "#{@user.activation_code}"}}
    assert_response :redirect
    assert @user = assigns(:user)
    assert_equal :active, @user.current_state
    assert_redirected_to edit_user_path
  end

  def test_should_not_post_activation_with_invalid_activation_code
    @user = create_user
    assert @user.register!
    post :activate, {"id" => "#{@user.login}", "user" => {"activation_code_confirmation" => "XXXXXXXXXXXXXXXXX"}}
    assert_response :success
    assert @user = assigns(:user)
    assert_equal "XXXXXXXXXXXXXXXXX", @user.activation_code_confirmation
    assert_template 'confirm'
  end

  def test_should_not_post_activate_with_no_parameters
    post :activate, {}
    assert_response :redirect
    assert_redirected_to new_user_path
  end

  def test_should_get_edit
    @user = create_user
    assert @user.register!
    assert @user.activate!
    login_as @user
    get :edit
    assert_response :success
  end

  def test_should_get_edit_in_de_DE
    @request.with_subdomain 'de'
    @user = create_user(:language => 'de')
    assert @user.register!
    assert @user.activate!
    login_as @user
    get :edit
    assert_response :success
  end

  def test_should_get_edit_and_redirect_to_profile
    @user = create_user
    assert @user.register!
    assert @user.activate!
    assert @user.person.activate!
    assert @user.person.member?
    login_as @user
    get :edit
    assert_response :redirect
    assert_redirected_to person_path(@user.person)
  end

  def test_should_not_get_edit_and_redirect_to_signin
    @user = create_user
    assert @user.register!
    assert @user.activate!
    get :edit
    assert_response :redirect
    assert_redirected_to new_session_path
  end
  
  def test_should_get_edit_with_invitation
    @user = create_user
    @invitation = Invitation.create(
      :invitor => people(:homer),
      :first_name => 'Simon',
      :last_name => 'Garfunkel',
      :email => @user.email,
      :with_voucher => true
    )
    assert @invitation.send!
    self.current_invitation = @invitation
    assert @user.register!
    assert @user.activate!
    login_as @user
    get :edit
    assert_response :success, 'should get edit'
    assert @person = assigns(:person)
    assert @invitation = assigns(:invitation)
    assert "Simon Garfunkel", @person.name
  end
  
  def test_should_update_and_save
    @user = create_user
    assert @user.register!
    assert @user.activate!
    login_as @user
    put :update, update_user_attributes("_property"=>"save")
    assert_response :success
    assert @person = assigns(:person)
    assert_equal "Simon A. Garfunkel", @person.name
    assert_equal "http://blog.test.tst", @person.blog_url
    assert_equal "http://test.tst", @person.home_page_url
    assert_equal "http://twitter.com/sgarfunk", @person.twitter_url

    assert_equal "musik, gitarre", @person.want_expertise
    assert_equal "hiking, mountain biking", @person.interest
    assert @person.academic_title, 'should have an academic title'
    assert_equal "Dr.", @person.academic_title.name
    assert @person.personal_address, 'should have personal address'
    assert_equal "Dreimühlenstr. 21, München, BY, 80469, Germany", @person.personal_address.to_s
    assert !@person.member?, 'should not be activated'
  end

  def test_should_update_and_finish
    @user = create_user
    assert @user.register!
    assert @user.activate!
    login_as @user
    
    user_attributes = update_user_attributes("_property"=>"finish")
    user_attributes["person"].merge!(
      "avatar" => File.new(File.join(ROOT, "fixtures", "files", "ginger.jpg"), 'rb')
    )
    put :update, user_attributes
    
    assert_response :redirect, 'should redirect to profile_path'
    assert @person = assigns(:person)
    assert_equal "Simon A. Garfunkel", @person.name
    assert @person.avatar.file?, "should have an avatar assigned"
    assert @person.personal_address
    assert_redirected_to person_path(@person)
    assert @person.member?, 'should be activated'
  end

  def test_should_not_update_and_finish_without_valid_personal_address
    @user = create_user
    assert @user.register!
    assert @user.activate!
    login_as @user
    user_attributes = update_user_attributes("_property"=>"finish")
    user_attributes['person'].delete('personal_address_attributes')
    put :update, user_attributes
    assert_response :success, 'should not redirect to person_path'
    assert @person = assigns(:person)
    assert_equal "Simon A. Garfunkel", @person.name
    assert @person.personal_address, "should be there"
    assert_equal "", @person.personal_address.to_s
  end

  def test_should_update_with_invitation
    @user = create_user
    @invitation = Invitation.new(
      :invitor => people(:homer),
      :first_name => 'Simon',
      :last_name => 'Garfunkel',
      :email => @user.email,
      :with_voucher => true
    )
    assert @invitation.save
    assert @invitation.send!
    self.current_invitation = @invitation
    assert @user.register!
    assert @user.activate!
    login_as @user
    put :update, update_user_attributes("_property"=>"finish")
    assert_response :redirect, 'should redirect to profile_path'
    assert @person = assigns(:person)
    assert @invitation = assigns(:invitation)
    @person.friends.include?(people(:homer))
  end

  def test_should_not_update_and_redirect_to_profile
    @user = create_user
    assert @user.register!
    assert @user.activate!
    assert @user.person.activate!
    login_as @user
    put :update, update_user_attributes("_property"=>"finish")
    assert_response :redirect, 'should redirect to profile_path'
    assert_redirected_to person_path(@user.person)
  end

  def test_should_route_complete_user
    assert_recognizes hash_for_path(:complete_user), {:path => '/user/complete', :method => :get}
  end

  def test_should_update_and_complete
    @user = create_user
    assert @user.register!
    assert @user.activate!
    login_as @user
    put :update, update_user_attributes("_property"=>"")
    assert_response :redirect, 'should redirect to complete_user_path'
    assert @person = assigns(:person)
    assert_equal "Simon A. Garfunkel", @person.name
    assert_redirected_to complete_user_path
    assert @person.member?, 'should be activated'
  end
  
  def test_should_get_complete
    @user = create_user
    assert @user.register!
    assert @user.activate!
    assert @user.person.created?
    login_as @user
    get :complete
    assert_response :success
    assert @selected = assigns(:selected)
    assert_equal "CartLineItem", @selected.class.name
    assert_equal "Three-Month Partner Membership", @selected.name
  end

  def test_should_get_complete_with_partner_voucher
    @user = create_user
    assert @user.register!
    assert @user.activate!
    assert @user.person.created?
    
    self.current_voucher = PartnerMembershipVoucher.create
    
    login_as @user
    get :complete
    assert_response :success
    assert @selected = assigns(:selected)
    assert_equal "PartnerMembershipVoucher", @selected.class.name
  end

  def test_should_get_complete_and_redirect_to_profile
    @user = create_user
    assert @user.register!
    assert @user.activate!
    assert @user.person.activate!
    assert @user.person.member?
    login_as @user
    get :complete
    assert_response :redirect
    assert_redirected_to person_path(@user.person)
  end
  
  def test_should_route_address_province_user
    assert_recognizes hash_for_path(:update_address_province_user), {:path => '/user/update_address_province', :method => :post}
  end
  
  def test_should_update_address_province_with_known_regions
    xhr :get, :update_address_province, {"value" => "US", "object_name" => "person", "method_name" => "personal_address_attributes", "html_id" => "province_id", "req" => "1", "lock" => "1"}
    assert @provinces = assigns(:provinces)
    assert @provinces.include?(['California', 'CA'])
    assert @response.body.include?('province_id')
    assert_response :success
  end

  def test_should_update_address_province_without_known_regions
    xhr :get, :update_address_province, {"value" => "XX", "object_name" => "person", "method_name" => "personal_address_attributes", "html_id" => "province_id", "req" => "1", "lock" => "1"}
    assert !assigns(:provinces)
    assert @response.body.include?('province_id')
    assert_response :success
  end

  def test_should_update_address_province_with_empty_country
    xhr :get, :update_address_province, {"value" => "", "object_name" => "person", "method_name" => "personal_address_attributes", "html_id" => "province_id", "req" => "1", "lock" => "1"}
    assert @provinces = assigns(:provinces)
    assert_equal [["Pick country first...", ""]], @provinces
    assert @response.body.include?('province_id')
    assert @response.body.include?('Pick country first...')
    assert_response :success
  end

  def test_route_new_password
    assert_routing '/user/new_password', hash_for_path(:new_password_user)
  end

  def test_route_reset_password
    assert_recognizes(hash_for_path(:reset_password_user), {:path => '/user/reset_password', :method => :post})
  end
  
  def test_should_new_password
    logout
    get :new_password
    assert_response :success
    assert_nil current_user
  end

  def test_should_new_password_with_user
    login_as :lisa
    get :new_password
    assert_response :redirect
    assert_redirected_to new_password_user_path
  end

  def test_should_reset_password
    logout
    @user = create_user
    @user.activate!
    post :reset_password, {"user"=>{"login"=>"#{@user.login}", "email"=>"#{@user.email}"}}
    assert_response :redirect
    assert_redirected_to new_session_path
  end

  def test_should_not_reset_password
    @user = create_user
    @user.activate!
    post :reset_password, {"user"=>{"login"=>"#{@user.login}", "email"=>"bogusemail"}}
    assert_response :success
    assert @response.has_flash?
  end

  protected
  
  def assign_current_registering_user(user)
    @request.session[:registering_user_id] = user ? user.id : nil
  end
  
  def current_registering_user
    User.find_by_id(@request.session[:registering_user_id]) if @request.session[:registering_user_id]
  end

  def update_user_attributes(options={})
    {"person"=>{
      "personal_address_attributes"=>{"city"=>"München",
        "country_code"=>"DE",
        "postal_code"=>"80469",
        "mobile"=>"",
        "province_code"=>"BY",
        "phone"=>"+49 89 123456789",
        "street"=>"Dreimühlenstr. 21",
        "fax"=>""
      },
      "want_expertise"=>"musik, gitarre",
      "interest"=>"hiking, mountain biking",
      "academic_title_id"=>"#{AcademicTitle.find(:first).id}",
      "avatar"=>"",
      "spoken_language_ids"=>SpokenLanguage.find(:all).map(&:id).map(&:to_s),
      "first_name"=>"Simon",
      "middle_name"=>"A.",
      "last_name"=>"Garfunkel",
      "home_page_url"=>"http://test.tst",
      "blog_url"=>"http://blog.test.tst",
      "twitter_name"=>"sgarfunk"
    }}.merge(options)
  end
  
end
