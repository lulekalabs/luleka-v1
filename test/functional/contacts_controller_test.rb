require File.dirname(__FILE__) + '/../test_helper'
require 'contacts_controller'

# Re-raise errors caught by the controller.
class ContactsController; def rescue_action(e) raise e end; end

class ContactsControllerTest < Test::Unit::TestCase
  all_fixtures

  def setup
    @controller = ContactsController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
    
    @request.with_subdomain('us')

    login_as :homer
  end

  def test_security
    logout
    assert_requires_login :index

    assert_requires_login :pending
    assert_requires_login :shared
  end

  def test_should_get_index
    get :index
    assert_response :success
    assert assigns(:person)
    assert assigns(:user)
    assert assigns(:people)
    friends = assigns(:people)
    assert_equal 2, friends.size
    assert @response.body.include?(people(:bart).name)
    assert @response.body.include?(people(:lisa).name)
    
    # sidebar
    assert @response.body.include?('Invite a Friend')
  end

  def test_should_get_pending_contacts
    invite(:homer, :marge) # marge invites homer
    invite(:homer, :barney) # barney invites homer
    
    get :pending
    assert_response :success
    assert assigns(:user)
    assert assigns(:person)
    assert assigns(:invitations)
    pending_invitations = assigns(:invitations)
    assert_equal 2, pending_invitations.size
    assert @response.body.include?(people(:marge).name)
    assert @response.body.include?(people(:barney).name)
  end

  def test_should_get_shared_contacts
    befriend(:barney, :lisa)
    befriend(:barney, :bart)
    
    get :shared, :id => people(:barney)
    assert_response :success
    assert assigns(:user)
    assert assigns(:person)
    assert assigns(:people)

    assert @response.body.include?("Shared Contacts with #{people(:barney).name}")
    
    shared_contacts = assigns(:people)
    assert_equal 2, shared_contacts.size
    assert @response.body.include?(people(:lisa).name)
    assert @response.body.include?(people(:bart).name)
  end



  protected
  
  def invite(invitee_name, invitor_name=:homer, invitation_options={:message => "Hi!", :with_voucher => false})
    invitation = Invitation.create(invitation_options.merge(:invitor => people(invitor_name), :invitee => people(invitee_name)))
    invitation.send!
    invitation
  end
  
  def befriend(invitee_name, invitor_name=:homer, options={})
    Friendship.create({
      :person_id => people(invitor_name).id,
      :friend_id => people(invitee_name).id,
      :accepted_at => Time.now.utc,
      :created_at => Time.now.utc
    }.merge(options))
    Friendship.create({
      :person_id => people(invitee_name).id,
      :friend_id => people(invitor_name).id,
      :accepted_at => Time.now.utc,
      :created_at => Time.now.utc
    }.merge(options))
  end
  
end
