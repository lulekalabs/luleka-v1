require File.dirname(__FILE__) + '/../test_helper'

class InvitationTest < ActiveSupport::TestCase
  all_fixtures

  def setup
  end

  def test_simple_create
    invite = Invitation.new
    assert invite
    assert invite.is_a?(Invitation)
    assert invite.is_a?(Message)
  end
  
  def test_simple_validations
    invite = Invitation.new
    assert !invite.valid?
#    assert invite.errors.invalid?(:first_name)
#    assert invite.errors.invalid?(:last_name)
    assert invite.errors.invalid?(:email)
  end
  
  def test_create_with_invitee
    invite = Invitation.create(:invitor => people(:homer), :invitee => people(:barney))
    assert invite
    assert_equal people(:homer), invite.invitor
    assert_equal people(:barney), invite.invitee
  end
  
  def test_new_user_state_machine_with_signup
    invite = Invitation.create(
      :invitor => people(:homer),
      :first_name => "Hugo",
      :last_name => "Simpson",
      :email => "hugo@simpson.tt",
      :email_confirmation => "hugo@simpson.tt",
      :message => "hello hugo, this is your invitation!",
      :language => 'en'
    )
    assert invite.valid?, 'validation errors'
    assert_equal 'queued', invite.status, 'initial status'
    invite.send!
    assert_equal 'delivered', invite.status
    invite.signup!
    assert_equal 'registering', invite.status
    invite.accept!
    assert_equal 'accepted', invite.status
  end

  def test_new_user_state_machine_with_open
    invite = Invitation.create(
      :invitor => people(:homer),
      :first_name => "Hugo",
      :last_name => "Simpson",
      :email => "hugo@simpson.tt",
      :email_confirmation => "hugo@simpson.tt",
      :message => "hello hugo, this is your invitation!",
      :language => 'en'
    )
    assert invite.valid?, 'validation errors'
    assert_equal 'queued', invite.status, 'initial status'
    invite.send!
    assert_equal 'delivered', invite.status
    #--- happens in invitation/:uuid?confirm
    hugo = create_person(:first_name => "Hugo", :last_name => "Simpson", :email => "hugo@simpson.tt")
    assert hugo.activate!
    invite.invitee = hugo
    invite.open!
    invite = Invitation.find_by_id(invite.id)
    assert_equal hugo, invite.invitee
    #---
    assert_equal 'pending', invite.status
    invite.accept!
    assert_equal 'accepted', invite.status
  end

  def test_existing_user_state_machine_with_accept
    invite = Invitation.create(:invitor => people(:homer), :invitee => people(:barney))
    assert invite
    assert_equal 'queued', invite.status, 'initial status'
    invite.send!
    assert_equal 'pending', invite.status
    invite.accept!
    assert_equal 'accepted', invite.status
  end

  def test_existing_user_state_machine_with_decline
    invite = Invitation.create(:invitor => people(:homer), :invitee => people(:lisa))
    assert invite
    assert_equal 'queued', invite.status, 'initial status'
    invite.send!
    assert_equal 'pending', invite.status
    invite.decline!
    assert_equal 'declined', invite.status
  end

  def test_should_create_invitation_and_redeem_voucher
    invite = nil
    assert_equal 5, people(:homer).voucher_quota
    assert_difference Voucher, :count do
      invite = Invitation.create(:invitor => people(:homer), :invitee => people(:quentin), :with_voucher => true)
      assert invite.voucher.is_a?(PartnerMembershipVoucher)
    end
    assert_equal 4, people(:homer).voucher_quota
    assert invite
    assert_equal 'queued', invite.status, 'initial status'
    invite.send!
    assert_equal 'pending', invite.status
    assert_equal false, people(:quentin).partner?
    invite.accept!
    assert_equal 'accepted', invite.status
    assert_equal true, people(:quentin).partner?, 'should convert to partner'
  end

  def test_should_assign_voucher_quota
    invite = nil
    # sending voucher to someone who already is an expert
    assert_equal 5, people(:homer).voucher_quota
    assert_no_difference Voucher, :count do
      # homer is an expert but marge is not, so a voucher should not be attached
      invite = Invitation.create(:invitor => people(:homer), :invitee => people(:marge), :with_voucher => true)
    end
    assert_equal 5, people(:homer).voucher_quota
  end    

  def test_should_not_set_with_voucher_with_zero_string
    invite = Invitation.create(:invitor => people(:homer), :invitee => people(:marge), :with_voucher => "0")
    assert_equal false, invite.with_voucher?, '0 should be taken as false'
  end    

  def test_should_set_with_voucher_with_one_string
    invite = Invitation.create(:invitor => people(:homer), :invitee => people(:marge), :with_voucher => "1")
    assert_equal true, invite.with_voucher?, '1 should be taken as true'
  end    

  def test_should_not_validate_member_invitor_sending_voucher
    # a citizyen cannot send a voucher
    assert_no_difference Voucher, :count do
      # homer is a partner but marge is not, so a voucher should not be attached
      invite = Invitation.create(:invitor => people(:lisa), :invitee => people(:quentin), :with_voucher => true)
      assert !invite.valid?
      assert_equal "can only be sent by a Partner", invite.errors.on(:voucher)
    end
  end
  
  def test_remind_with_existing_user
    invite = nil
    assert_equal false, people(:barney).partner?
    assert_equal 5, people(:homer).voucher_quota
    assert_difference Voucher, :count do
      invite = Invitation.create(:invitor => people(:homer), :invitee => people(:barney), :with_voucher => true)
    end
    assert_equal 4, people(:homer).voucher_quota
    assert_equal false, invite.can_remind?, 'not yet sent'
    assert_equal false, invite.sent?
    invite.send!
    assert invite.pending?
    assert_equal true, invite.sent?
    assert_equal true, invite.sent_and_not_reminded?
    assert_equal true, invite.can_remind?, 'can be reminded once'
    assert_equal false, invite.reminded?
    invite.remind
    assert_equal true, invite.reminded?
    assert_equal false, invite.sent_and_not_reminded?
    assert invite.pending?
    assert_equal false, invite.can_remind?, 'cannot be reminded twice'
  end

  def test_remind_with_new_user
    invite = nil
    assert_equal 5, people(:homer).voucher_quota
    assert_difference Voucher, :count do
      invite = Invitation.create(valid_invitation_new_user_attributes(:with_voucher => true))
    end
    assert_equal 4, people(:homer).voucher_quota
    assert_equal false, invite.can_remind?, 'not yet sent'
    assert_equal false, invite.sent?
    invite.send!
    assert invite.delivered?
    assert_equal true, invite.sent?
    assert_equal true, invite.sent_and_not_reminded?
    assert_equal true, invite.can_remind?, 'can be reminded once'
    assert_equal false, invite.reminded?
    invite.remind
    assert_equal 4, people(:homer).voucher_quota
    assert_equal true, invite.reminded?
    assert_equal false, invite.sent_and_not_reminded?
    assert invite.delivered?
    assert_equal false, invite.can_remind?, 'cannot be reminded twice'
  end

  def test_has_finder_with_after
    i1 = Invitation.create(:invitor => people(:bart), :invitee => people(:lisa), :created_at => Time.now.utc - 1.minute)
    i2 = Invitation.create(:invitor => people(:lisa), :invitee => people(:bart), :created_at => Time.now.utc - 1.minute)
    
    assert_equal 2, Invitation.after(Time.now.utc - 2.minutes).size
  end

  def test_has_finder_with_after_and_accepted
    i1 = Invitation.create(:invitor => people(:bart), :invitee => people(:lisa), :created_at => Time.now.utc - 1.minute)
    i2 = Invitation.create(:invitor => people(:lisa), :invitee => people(:bart), :created_at => Time.now.utc - 1.minute)
    i1.send!
    i2.send!
    i1.accept!
    assert_equal 1, Invitation.after(Time.now.utc - 2.minutes).accepted.size
  end

  def test_should_generate_uuid
    invitation = Invitation.create(valid_invitation_new_user_attributes)
    assert invitation.valid?
    assert invitation.uuid
  end

  def test_should_find_registering_invitations
    invite = Invitation.create(
      :invitor => people(:homer),
      :first_name => "Hugo",
      :last_name => "Simpson",
      :email => "hugo@simpson.tt",
      :email_confirmation => "hugo@simpson.tt",
      :message => "hello hugo, this is your invitation!",
      :language => 'en'
    )
    assert invite.send!
    assert_equal :delivered, invite.current_state
    assert invite.signup!
    assert_equal :registering, invite.current_state
    assert_equal [invite], Invitation.registering(:conditions => {:sender_id => people(:homer).id})
  end

  def test_should_not_find_registering_invitations
    assert_equal [], Invitation.registering(:conditions => {:sender_id => people(:homer).id})
  end
  
  def test_should_get_invitee_attributes_with_new_user
    invite = Invitation.create(
      :invitor => people(:homer),
      :first_name => "Hugo",
      :last_name => "Simpson",
      :email => "hugo@simpson.tt",
      :email_confirmation => "hugo@simpson.tt",
      :message => "hello hugo, this is your invitation!",
      :language => 'en'
    )

    assert_equal({
      :first_name => "Hugo",
      :last_name => "Simpson",
      :email => "hugo@simpson.tt"
    }, invite.invitee_attributes(true))

    assert_equal({
      :first_name => "Hugo",
      :last_name => "Simpson"
    }, invite.invitee_attributes(false))

    assert_equal({
      :first_name => "Hugo",
      :last_name => "Simpson"
    }, invite.invitee_attributes)
  end
  
  def test_should_get_invitee_attributes_with_existing_user
    invite = Invitation.create(
      :invitor => people(:homer),
      :invitee => people(:quentin),
      :message => "hello quentin, this is your invitation!",
      :language => 'en'
    )

    assert_equal({
      :first_name => "Quentin",
      :last_name => "Terantino",
      :email => "quentin@terantino.tt"
    }, invite.invitee_attributes(true))

    assert_equal({
      :first_name => "Quentin",
      :last_name => "Terantino"
    }, invite.invitee_attributes(false))

    assert_equal({
      :first_name => "Quentin",
      :last_name => "Terantino"
    }, invite.invitee_attributes)
  end
  
  def test_invitee_name
    assert_equal "Hugo Simpson <hugo@simpson.tt>", Invitation.new(valid_invitation_new_user_attributes).invitee_name
    assert_equal "hugo@simpson.tt", Invitation.new(:email => "hugo@simpson.tt").invitee_name
  end

  def test_class_method_default_message
    #--- english
    assert_equal "Hello,\n\nI would like to invite you to join my network on #{SERVICE_NAME}.\n\n-Homer",
      Invitation.default_message(:invitor_name => "Homer", :language => 'en')
      
    assert_equal "Hello Barney,\n\nI would like to invite you to join my network on #{SERVICE_NAME}.\n\n-Homer",
      Invitation.default_message(:invitee_name => "Barney", :invitor_name => "Homer", :language => 'en')

    #--- german
    assert_equal "Hello,\n\nich würde Sie/Dich gerne in mein Netzwerk auf Luleka einladen.\n\n-Homer",
      Invitation.default_message(:invitor_name => "Homer", :language => 'de')

    assert_equal "Hello Brigitte,\n\nich würde Sie/Dich gerne in mein Netzwerk auf Luleka einladen.\n\n-Werner",
      Invitation.default_message(:invitee_name => "Brigitte", :invitor_name => "Werner", :language => 'de')
  end
  
  def test_default_message
    assert_equal "Hello Hugo,\n\nI would like to invite you to join my network on Luleka.\n\n-Homer Simpson",
      Invitation.new(valid_invitation_new_user_attributes).default_message
  end

  protected

  def valid_invitation_new_user_attributes(options={})
    {
      :invitor => people(:homer),
      :first_name => "Hugo",
      :last_name => "Simpson",
      :email => "hugo@simpson.tt",
      :email_confirmation => "hugo@simpson.tt",
      :message => "hello hugo, this is your invitation!",
      :language => 'en'
    }.merge(options)
  end
  
end
