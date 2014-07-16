require File.dirname(__FILE__) + '/../test_helper'
require 'invitations_controller'

# Re-raise errors caught by the controller.
class InvitationsController; def rescue_action(e) raise e end; end

class InvitationsControllerTest < Test::Unit::TestCase
  all_fixtures
  
  def setup
    @controller = InvitationsController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new

    @request.with_subdomain('us')
    
    login_as :homer
  end

  def test_security
    logout
    assert_requires_login :index
    assert_requires_login :new
    assert_requires_login :create
    assert_requires_login :complete

    assert_requires_login :accept
    assert_requires_login :decline
  end

  def test_should_get_index
    get :index
    assert_response :success
    assert assigns(:person)
    assert assigns(:invitations)
    
    assert_select 'span', 'Unanswered Invitations'
    assert @response.body.include?('No invitations')
  end

  def test_should_get_index_with_pending_invitations
    invite(:barney, :homer)
    invite(:bart, :homer)
    invite(:marge, :homer)
    get :index
    assert_response :success
    assert assigns(:invitations)
    invitations = assigns(:invitations)
    assert_select 'ul.listBoxElements' do
      assert_select 'li.listBoxElement', 3
    end
  end

  def test_should_get_index_with_accepted_invitations
    a = invite(:barney, :homer)
    (b = invite(:bart, :homer)).accept!
    (c = invite(:marge, :homer)).decline!
    xhr :get, :index, :kind => 'accepted'
    assert_response :success
    invitations = assigns(:invitations)
    assert_select 'ul.listBoxElements' do
      assert_select 'li.listBoxElement', 1 do
        assert_select 'div>a', people(:bart).name
      end
    end
  end

  def test_should_get_index_with_declined_invitations
    invite(:barney, :homer)
    invite(:bart, :homer).decline!
    invite(:marge, :homer).decline!
    xhr :get, :index, :kind => 'declined'
    assert_response :success
    invitations = assigns(:invitations)
    assert_select 'ul.listBoxElements' do
      assert_select 'li.listBoxElement', 2 do
        assert_select 'div>a', people(:bart).name
        assert_select 'div>a', people(:marge).name
      end
    end
  end
  
  def test_should_get_new
    get :new
    assert_response :success
    assert_select 'form input[id=?]', 'invitation_first_name'
    assert_select 'form input[id=?]', 'invitation_last_name'
    assert_select 'form input[id=?]', 'invitation_email'
    assert_select 'form select[id=?]', 'language_invitation'
  end
  
  def test_should_not_create
    post :create
    invitation = assigns(:invitation)
    assert invitation
    assert invitation.errors.size > 0
  end
  
  def test_should_create_invitation_for_unregistered_users
    assert_difference Invitation, :count do
      post :create, { "invitation"=>{"message"=>"Hi Sepp, join me!", "language"=>"de", "last_name"=>"Sepp", "first_name"=>"Meier", "email"=>"sepp@meier.com", "with_voucher"=>"1"
      }}
    end
#    assert_redirected_to complete_invitations_path
    invitation = assigns(:invitation)
    assert invitation
    assert invitation.delivered?
    assert invitation.with_voucher?
  end
  
  def test_should_get_new_for_registered_users
    invitee = people(:barney)
    options = {:controller => 'invitations', :action => 'new', :person_id => "#{invitee.permalink}"}
    assert_routing("people/#{invitee.permalink}/invitations/new", options)
    get :new, {:person_id => "#{invitee.permalink}"}
    assert_response :success
  end

  def test_should_create_invitation_for_registered_users
    invitor = people(:homer)
    invitee = people(:barney)

    assert_equal 5, invitor.voucher_quota
    assert_difference Invitation, :count do
      post :create, {:person_id => "#{invitee.permalink}", :invitation => {:message => "Hi!", :with_voucher => "1"}}
    end
    invitor.reload
    assert_equal 4, invitor.voucher_quota
    
#    assert_redirected_to complete_invitations_path
    invitation = assigns(:invitation)
    assert invitation.pending?
    assert invitation.with_voucher?

    assert invitor.sent_invitations.include?(invitation)
    assert invitee.received_invitations.include?(invitation)
  end
  
  def test_list_item_expander
    xhr :post, :list_item_expander, :id => invite(:barney, :homer).id
    assert_response :success
    assert_template 'invitations/_list_item_content'
  end

  def test_should_accept_invitation
    xhr :post, :accept, :id => invite(:barney, :homer).id
    assert_response :success
    assert assigns(:invitation)
    invitation = assigns(:invitation)
    assert invitation.accepted?
    assert_template 'invitations/_list_item_accepted'
    homer = people(:homer)
    homer.reload
    assert homer.friends.include?(people(:barney))
  end

  def test_should_not_accept_invitation
    invitation = Invitation.create(:invitee => people(:homer), :invitor => people(:barney))
    xhr :post, :accept, :id => invitation.id
    assert_response 444
  end

  def test_should_decline_invitation
    xhr :post, :decline, :id => invite(:barney, :homer).id
    assert_response :success
    assert assigns(:invitation)
    invitation = assigns(:invitation)
    assert invitation.declined?
    assert_template 'invitations/_list_item_declined'
  end

  def test_should_not_decline_invitation
    invitation = Invitation.create(:invitee => people(:homer), :invitor => people(:barney))
    xhr :post, :decline, :id => invitation.id
    assert_response 444
  end

  def test_should_remind_invitation
    invite = invite(:barney, :homer)
    invite.send!
    xhr :post, :remind, :id => invite.id
    assert_response :success
    assert assigns(:invitation)
    invitation = assigns(:invitation)
    assert_equal true, invitation.pending?
    assert_equal true, invitation.reminded?
    assert_template 'invitations/_list_item_reminded'
    assert @response.body.include?(invite.invitee.name)
  end

  def test_should_confirm_new_user
    invitation = Invitation.create(:invitor => people(:homer), :email => "tester1@test.tst")
    invitation.send!
    assert_equal :delivered, invitation.current_state
    get :confirm, :id => invitation.uuid
    assert_response :redirect
    assert_redirected_to new_user_path
    assert @response.has_flash?
  end

  def test_should_confirm_existing_user_and_redirect_to_person_profile
    invitation = invite(:aaron, :quentin)
    assert_equal 0, people(:aaron).friends.count
    assert_equal :pending, invitation.current_state
    login_as :aaron
    get :confirm, :id => invitation.uuid
    assert_response :redirect
#    assert_redirected_to person_path(people(:aaron))
    assert_equal 1, people(:aaron).friends.count
  end

  def test_should_not_confirm_existing_user_and_redirect_to_new_invitation
    invitation = invite(:aaron, :quentin)
    assert_equal :pending, invitation.current_state
    login_as :lisa
    get :confirm, :id => invitation.uuid
    assert_response :redirect
    assert_redirected_to new_invitation_path
  end
  
=begin  
  Taken from previous beta users controller
  Interesting for testing content type
  
  def xtest_should_post_create
    # :content_type => 'text/javascript'
    @request.env['HTTP_ACCEPT'] = "text/html"
    self.current_locale = 'de-DE'
    post :create, {"beta_user" => {"email"=>"test@test.tst"}}
    assert @beta_user = assigns(:beta_user)
    assert !@beta_user.new_record?
    assert_response :redirect
    assert_redirected_to complete_beta_path
  end

  def xtest_should_post_create_with_ajax
    @request.env['HTTP_ACCEPT'] = 'text/javascript'
    post :create, {"beta_user" => {"email"=>"test@test.tst"}}
    assert @beta_user = assigns(:beta_user)
    assert !@beta_user.new_record?
    assert_response :success
  end
=end  

  protected
  
  def invite(invitee_name, invitor_name=:homer, invitation_options={:message => "Hi!", :with_voucher => false})
    invitation = Invitation.create(invitation_options.merge(:invitor => people(invitor_name), :invitee => people(invitee_name)))
    invitation.send!
    invitation
  end
  
  def profile_invitation_params(invitee, options={})
    defaults = {} #{:invitation => {:message => "Hi!", :with_voucher => '1'}}
    defaults.merge({:profile_id => invitee.id}).merge(options)
  end
  
end
