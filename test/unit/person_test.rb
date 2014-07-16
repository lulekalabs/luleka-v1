require File.dirname(__FILE__) + '/../test_helper'

class PersonTest < ActiveSupport::TestCase
  ROOT = File.join(File.dirname(__FILE__), '..')
  all_fixtures

  def setup
    I18n.locale = :"en-US"
    GeoKit::Geocoders::MultiGeocoder.stubs(:geocode).returns(valid_geo_location)
  end

  def test_simple_create
    person = build_person
    person.save!
    assert person
    assert_equal 'created', person.status
  end
  
  def test_has_user
    p = people(:homer)
    assert_equal p.user.person_id, p.id
  end
  
  def test_has_many_kases_association
    person = people(:marge)
    assert_nothing_raised do
      person.kases
    end
  end

  def test_has_many_solved_issues
    person = people(:homer)
    assert person.solved_issues.empty?
  end

  def test_has_many_clarifications_received
    person = people(:homer)
    assert person.clarifications_received.empty?
  end

  def test_has_many_clarifications_sent
    person = people(:homer)
    assert person.clarifications_sent.empty?
  end

  def test_has_many_clarifiable_kases
    person = people(:homer)
    assert person.clarifiable_kases.empty?
  end

  def test_has_many_clarifiable_responses
    person = people(:homer)
    assert person.clarifiable_responses.empty?
  end

  def test_gender
    homer = people(:homer)
    assert_equal 'm', homer.gender
    assert homer.is_male?

    barney = people(:barney)
    assert_equal 'f', barney.gender
    assert barney.is_female?
  end

  def test_current_state_t
    person = build_person
    assert_equal nil, person.current_state_t
    
    assert_equal 'partner', people(:homer).current_state_t
    assert_equal 'member', people(:barney).current_state_t
    
    assert_equal nil, person.current_state_t('sepp')
    assert_equal 'member', person.current_state_t('member')
    assert_equal 'member', person.current_state_t(:member)
  end
  
  def test_name
    person = build_person(:first_name => 'Sepp', :middle_name => 'T.', :last_name => 'Meier')
    assert_equal "Sepp T. Meier", person.name
  end
  
  def test_name_and_email
    person = build_person
    assert_equal "#{person.first_name} #{person.last_name} <#{person.email}>", person.name_and_email
    assert_equal "dan@nye.tst", Person.new(:email => "dan@nye.tst").name_and_email
  end

  def test_default_country
    person = build_person
    assert_equal 'US', person.default_country
  end
  
  def test_default_language
    person = build_person
    assert_equal 'en', person.default_language
  end
  
  def test_default_currency
    person = build_person
    assert_equal 'USD', person.default_currency
  end

  def test_salutation_and_name
    assert_equal 'Mr Homer Simpson', people(:homer).salutation_and_name
  end

  def test_salutation
    assert_equal 'Mr', people(:homer).salutation
    assert_equal 'Ms', build_person(
      :first_name => 'Lin', :last_name => 'Ye', :gender => 'f'
    ).salutation
    assert_equal 'Prof. Dr.', build_person(
      :first_name => 'Lin', :last_name => 'Ye', :gender => 'f', :academic_title => academic_titles(:prof_dr)
    ).salutation
  end

  def test_salutation_t
    I18n.switch_locale :"en-US" do
      assert_equal 'Mr', people(:homer).salutation_t
      assert_equal 'Ms', build_person(
        :first_name => 'Lin', :last_name => 'Ye', :gender => 'f'
      ).salutation_t
      assert_equal 'Prof. Dr.', build_person(
        :first_name => 'Lin', :last_name => 'Ye', :gender => 'f', :academic_title => academic_titles(:prof_dr)
      ).salutation_t
    end
    I18n.switch_locale :"de-DE" do
      assert_equal 'Herr', people(:homer).salutation_t
      assert_equal 'Frau', build_person(
        :first_name => 'Lin', :last_name => 'Ye', :gender => 'f'
      ).salutation_t
      assert_equal 'Prof. Dr.', build_person(
        :first_name => 'Lin', :last_name => 'Ye', :gender => 'f', :academic_title => academic_titles(:prof_dr)
      ).salutation_t
    end
  end

  def test_salutation_and_name_t_en_US
    I18n.switch_locale :"en-US" do
      assert_equal 'Mr Homer Simpson', people(:homer).salutation_and_name_t
      assert_equal 'Ms Lin Ye', build_person(
        :first_name => 'Lin', :last_name => 'Ye', :gender => 'f'
      ).salutation_and_name_t
      assert_equal 'Ms Lin Ye', build_person(
        :first_name => 'Lin', :last_name => 'Ye', :gender => 'f', :prefers_casual => true
      ).salutation_and_name_t
      assert_equal 'Prof. Dr. Lin Ye', build_person(
        :first_name => 'Lin', :last_name => 'Ye', :gender => 'f', :academic_title => academic_titles(:prof_dr)
      ).salutation_and_name_t
    end
    assert_equal 'Ms Holly Thomson', build_person(
      :first_name => 'Holly', :last_name => 'Thomson'
    ).salutation_and_name_t
  end

  def test_salutation_and_name_t_de_DE
    I18n.switch_locale :"de-DE" do
      assert_equal 'Herr Homer Simpson', people(:homer).salutation_and_name_t
      assert_equal 'Frau Lin Ye', build_person(
        :first_name => 'Lin', :last_name => 'Ye', :gender => 'f'
      ).salutation_and_name_t
      assert_equal 'Frau Lin Ye', build_person(
        :first_name => 'Lin', :last_name => 'Ye', :gender => 'f', :prefers_casual => true
      ).salutation_and_name_t
      assert_equal 'Prof. Dr. Lin Ye', build_person(
        :first_name => 'Lin', :last_name => 'Ye', :gender => 'f', :academic_title => academic_titles(:prof_dr)
      ).salutation_and_name_t
    end
  end

  def test_casualize_salutation_and_name
    assert_equal 'Mr Homer Simpson', people(:homer).casualize_salutation_and_name
    assert_equal 'Lin', build_person(
      :first_name => 'Lin', :last_name => 'Ye', :gender => 'f', :prefers_casual => true
    ).casualize_salutation_and_name
    assert_equal 'Prof. Dr. Lin Ye', build_person(
      :first_name => 'Lin', :last_name => 'Ye', :gender => 'f', :academic_title => academic_titles(:prof_dr)
    ).casualize_salutation_and_name
    assert_equal 'Lin', build_person(
      :first_name => 'Lin', :last_name => 'Ye', :gender => 'f', :academic_title => academic_titles(:prof_dr), :prefers_casual => true
    ).casualize_salutation_and_name
  end
  
  def test_casualize_salutation_and_name_t
    I18n.switch_locale :"en-US" do
      assert_equal 'Mr Homer Simpson', people(:homer).casualize_salutation_and_name_t

      assert_equal 'Ms Lin Ye', build_person(
        :first_name => 'Lin', :last_name => 'Ye', :gender => 'f'
      ).casualize_salutation_and_name_t

      assert_equal 'Lin', build_person(
        :first_name => 'Lin', :last_name => 'Ye', :gender => 'f', :prefers_casual => true
      ).casualize_salutation_and_name_t

      assert_equal 'Prof. Dr. Lin Ye', build_person(
        :first_name => 'Lin', :last_name => 'Ye', :gender => 'f', :academic_title => academic_titles(:prof_dr)
      ).casualize_salutation_and_name_t

      assert_equal 'Lin', build_person(
        :first_name => 'Lin', :last_name => 'Ye', :gender => 'f', :academic_title => academic_titles(:prof_dr), :prefers_casual => true
      ).casualize_salutation_and_name_t

      assert_equal 'Prof. Dr. Lin Ye', build_person(
        :first_name => 'Lin', :last_name => 'Ye', :gender => 'f', :academic_title => academic_titles(:prof_dr),
        :prefers_casual => true
      ).casualize_salutation_and_name_t(false)
      
      assert_equal 'Lin', build_person(
        :first_name => 'Lin', :last_name => 'Ye', :gender => 'f', :academic_title => academic_titles(:prof_dr), 
        :prefers_casual => false
      ).casualize_salutation_and_name_t(true)
    end
    I18n.switch_locale :"de-DE" do
      assert_equal 'Herr Homer Simpson', people(:homer).casualize_salutation_and_name_t

      assert_equal 'Frau Lin Ye', build_person(
        :first_name => 'Lin', :last_name => 'Ye', :gender => 'f'
      ).casualize_salutation_and_name_t

      assert_equal 'Lin', build_person(
        :first_name => 'Lin', :last_name => 'Ye', :gender => 'f', :prefers_casual => true
      ).casualize_salutation_and_name_t

      assert_equal 'Prof. Dr. Lin Ye', build_person(
        :first_name => 'Lin', :last_name => 'Ye', :gender => 'f', :academic_title => academic_titles(:prof_dr)
      ).casualize_salutation_and_name_t

      assert_equal 'Lin', build_person(
        :first_name => 'Lin', :last_name => 'Ye', :gender => 'f', :academic_title => academic_titles(:prof_dr), 
        :prefers_casual => true
      ).casualize_salutation_and_name_t

      assert_equal 'Prof. Dr. Lin Ye', build_person(
        :first_name => 'Lin', :last_name => 'Ye', :gender => 'f', :academic_title => academic_titles(:prof_dr), 
        :prefers_casual => true
      ).casualize_salutation_and_name_t(false)

      assert_equal 'Lin', build_person(
        :first_name => 'Lin', :last_name => 'Ye', :gender => 'f', :academic_title => academic_titles(:prof_dr), 
        :prefers_casual => false
      ).casualize_salutation_and_name_t(true)
    end
    assert_equal 'Ms Holly Thomson', build_person(
      :first_name => 'Holly', :last_name => 'Thomson'
    ).casualize_salutation_and_name_t
  end

  def test_title_and_name
    assert_equal 'Lin Ye', build_person(
      :first_name => 'Lin', :last_name => 'Ye', :gender => 'f'
    ).title_and_name
    
    assert_equal 'Prof. Dr. Lin Ye', build_person(
      :first_name => 'Lin', :middle_name => "He", :last_name => 'Ye', :gender => 'f', :academic_title => academic_titles(:prof_dr)
    ).title_and_name
  end

  def test_title_and_full_name
    assert_equal 'Lin Ye', build_person(
      :first_name => 'Lin', :last_name => 'Ye', :gender => 'f'
    ).title_and_full_name
    
    assert_equal 'Prof. Dr. Lin He Ye', build_person(
      :first_name => 'Lin', :middle_name => "He", :last_name => 'Ye', :gender => 'f', :academic_title => academic_titles(:prof_dr)
    ).title_and_full_name
  end

  def test_name_or_email
    assert_equal 'Lin Ye', Person.new(
      :first_name => 'Lin', :last_name => 'Ye', :email => "lin@ye.tst"
    ).name_or_email
    
    assert_equal 'lin@ye.tst', Person.new(
      :email => "lin@ye.tst"
    ).name_or_email
  end
  
  def test_validation_with_homer_as_partner
    homer = people(:homer)
    assert homer.partner?
    assert homer.valid?
    assert !homer.errors.invalid?(:tax_code)
    assert !homer.errors.invalid?(:have_expertise)
  end

  def test_should_not_validate_invalid_tax_code
    homer = people(:homer)
    assert homer.partner?
    homer.tax_code = 'abc-de43-23243'
    assert !homer.valid?
    assert homer.errors.on(:tax_code)
  end
  
  def test_voucher_quota
    homer = people(:homer)
    homer.set_voucher_quota(Person::DEFAULT_VOUCHER_QUOTA)
    assert_equal Person::DEFAULT_VOUCHER_QUOTA, homer.voucher_quota

    homer.set_voucher_quota(500)
    assert_equal 500, homer.voucher_quota
    assert homer.has_voucher_quota?
    
    homer.decrement_voucher_quota
    assert_equal 499, homer.voucher_quota
    
    homer.set_voucher_quota(homer.voucher_quota)
    assert_equal 499, homer.voucher_quota
    
    homer.set_voucher_quota(0)
    assert_equal 0, homer.voucher_quota
    homer.decrement_voucher_quota
    assert_equal 0, homer.voucher_quota
    assert !homer.has_voucher_quota?
  end

  def test_create_simple_invitation
    homer = people(:homer)
    # invite using instance
    invitation = homer.create_invitation(
      :invitee => people(:aaron),
      :message => "hi you get a voucher now!",
      :language => 'en'
    )
    assert invitation.valid?, 'invitation should be valid'
    assert "hi you get a voucher now!", invitation.message
    assert_equal people(:aaron), homer.invitees.first
    assert_equal people(:homer), people(:aaron).invitors.first
  end
  
  def test_should_not_allow_invitation_to_yourself
    homer = people(:homer)

    # invite yourself new user
    invitation = homer.create_invitation(
      :first_name => homer.firstname,
      :last_name => homer.lastname,
      :email => homer.email,
      :email_confirmation => homer.email,
      :message => "homer, i am inviting myself!"
    )
    assert !invitation.valid?
    assert_equal "Cannot invite yourself", invitation.errors.on_base
    
    # invite yourself existing user
    invitation = homer.create_invitation(
      :invitee => homer,
      :message => "homer, i am inviting myself!"
    )
    assert !invitation.valid?
    assert_equal "Cannot invite yourself", invitation.errors.on_base
  end
  
  def test_create_invitation_new_user_validate_invite_repeat
    homer = people(:homer)
    # invite using email
    invitation = homer.create_invitation(
      :first_name => "Agatha",
      :last_name => "Christy",
      :email => "agatha@christy.tt",
      :email_confirmation => "agatha@christy.tt",
      :message => "hi agatha!",
      :language => 'de'
    )
    assert invitation.valid?
    # invite the same person again
    invitation = homer.create_invitation(
      :first_name => "Agatha",
      :last_name => "Christy",
      :email => "agatha@christy.tt",
      :email_confirmation => "agatha@christy.tt",
      :message => "hi agatha!"
    )
    assert invitation.errors.invalid?(:email)
    assert_equal "has already been invited", invitation.errors.on(:email)
  end

  def test_create_invitation_existing_user_validate_invite_repeat
    homer = people(:homer)
    # invite using instance
    invitation = homer.create_invitation(
      :invitee => people(:aaron),
      :message => "hi agatha!"
    )
    assert invitation.valid?
    # invite the same person again
    invitation = homer.create_invitation(
      :invitee => people(:aaron),
      :message => "hi agatha!"
    )
    assert_equal "Aaron Weiz has already been invited", invitation.errors.on_base
  end

  def test_should_not_validate_invitation_voucher_with_invitee_as_previous_partner
    homer = people(:homer)
    # invite using instance
    invitation = homer.create_invitation(
      :invitee => people(:bart),
      :message => "hi you get a voucher now!",
      :language => 'en',
      :with_voucher => true
    )
    assert !invitation.valid?
    assert_equal "cannot be redeemed by existing or previous Partner", invitation.errors.on(:voucher)
  end
  
  def test_should_not_create_invitation_voucher_with_member_as_invitor
    bart = people(:bart)
    # temporarily give bart a voucher quota
    bart.set_voucher_quota(1)
    # invite using instance
    invitation = bart.create_invitation(
      :invitee => people(:barney),
      :message => "hi barney, you get a voucher now!",
      :with_voucher => true
    )
    assert !invitation.valid?
    assert_equal "can only be sent by a Partner", invitation.errors.on(:voucher)
    assert !invitation.voucher
  end

  def test_create_invitation_with_voucher_for_new_user
    homer = people(:homer)
    # invite using instance
    invitation = homer.create_invitation(
      :first_name => "Gail",
      :last_name => "Hammond",
      :email => "gail@hammond.com",
      :email_confirmation => "gail@hammond.com",
      :message => "hi gail! you get a voucher now!",
      :with_voucher => true,
      :language => 'de'
    )
    assert invitation.valid?
    assert invitation.voucher
    assert_equal invitation.invitor, invitation.voucher.consignor
    assert_equal "gail@hammond.com", invitation.voucher.email
    assert_equal PartnerMembershipVoucher::PROMOTABLE_SKU, invitation.voucher.promotable_sku
  end

  def test_should_create_invitation_with_email_to_registered_user
    gail = create_person(:first_name => 'Gail', :last_name => 'Hammond', :email => 'gail@hammond.com')
    assert gail.valid?
    assert gail.activate!
    homer = people(:homer)
    # invite using instance
    assert_difference Voucher, :count do 
      save_voucher_quota = homer.voucher_quota
      invitation = homer.create_invitation(
        :first_name => "Gail",
        :last_name => "Hammond",
        :email => "gail@hammond.com",
        :email_confirmation => "gail@hammond.com",
        :message => "hi gail! you get a voucher now!",
        :with_voucher => true,
        :language => 'de'
      )
      assert invitation.valid?
      
      assert_equal gail, invitation.invitee
      
      assert invitation.voucher
      assert_equal save_voucher_quota - 1, homer.voucher_quota
      assert_equal invitation.invitor, invitation.voucher.consignor
      assert_equal "gail@hammond.com", invitation.voucher.email
      assert_equal PartnerMembershipVoucher::PROMOTABLE_SKU, invitation.voucher.promotable_sku
    end
  end

  def test_should_not_validate_invitation_with_email_and_voucher_of_existing_partner
    homer = people(:homer)
    # invite using instance
    assert_no_difference Voucher, :count do 
      save_voucher_quota = homer.voucher_quota
      invitation = homer.create_invitation(
        :first_name => "Marge",
        :last_name => "Simpson",
        :email => "marge@simpson.tt",
        :email_confirmation => "marge@simpson.tt",
        :message => "hi marge! i am adding a voucher that you cannot redeem :-/",
        :with_voucher => true,
        :language => 'de'
      )
      assert !invitation.valid?
      assert_equal "cannot be redeemed by existing or previous Partner", invitation.errors.on(:voucher)
    end
  end

  def test_partner_membership_expires_on
    homer = people(:homer)
    assert_equal (15.days.ago + 12.months).to_date.to_s , homer.partner_membership_expires_on.to_s
  end

  def test_add_as_subscribable
    barney = people(:barney)
    assert barney.member?
    assert_difference Subscription, :count do 
      subscription = barney.add_as_subscribable(Product.find_by_sku('SU00103EN-US'))
      assert subscription.valid?
    end
    assert barney.partner?
    assert_equal 1, barney.partner_subscriptions.count
    assert_equal :active, barney.partner_subscriptions.first.current_state

    assert_equal (Time.now.utc + 12.months).to_date.to_s , barney.partner_membership_expires_on.to_s
    assert_equal false, barney.is_partner_membership_expired?, 'membership active'
    assert_equal true, barney.is_partner_membership_active?, 'membership active'
  end

  def test_is_partner_membership_active?
    assert_equal true, people(:homer).is_partner_membership_active?
    assert_equal false, people(:barney).is_partner_membership_active?
  end

  def test_ever_subscribed_as_partner?
    assert_equal true, people(:homer).ever_subscribed_as_partner?
    assert_equal false, people(:barney).ever_subscribed_as_partner?
  end
  
  def test_ever_subscribed_as_partner?
    assert_equal true, people(:homer).ever_subscribed_as_partner?
    assert_equal false, people(:barney).ever_subscribed_as_partner?
    assert_equal true, people(:bart).ever_subscribed_as_partner?
  end
  
  def test_is_partner_membership_active?
    assert_equal true, people(:homer).is_partner_membership_active?
    assert_equal false, people(:barney).is_partner_membership_active?
    assert_equal false, people(:bart).is_partner_membership_active?
  end
  
  def test_is_partner_membership_expired?
    assert_equal false, people(:homer).is_partner_membership_expired?
    assert_equal true, people(:barney).is_partner_membership_expired?
    assert_equal true, people(:bart).is_partner_membership_expired?
  end
  
  def test_shared_friends_with
    homer = people(:homer)
    barney = people(:barney)
    homer.is_friends_with(people(:bart))
    homer.is_friends_with(people(:marge))
    homer.is_friends_with(people(:lisa))
    assert 3, homer.friendships.count
    
    barney.is_friends_with(people(:marge))
    barney.is_friends_with(people(:lisa))
    assert 2, barney.friendships.count
    
    # shared_friends_with
    shared = homer.shared_friends_with(barney)

    assert_equal 2, shared.size, "should have 2 common friends, marge and lisa"
    assert_equal true, shared.map(&:id).include?(people(:marge).id)
    assert_equal true, shared.map(&:id).include?(people(:lisa).id)
    assert_equal false, shared.map(&:id).include?(people(:bart).id)
    
    # shared_with association extension
    shared = homer.friends.shared_with(barney)

    assert_equal 2, shared.size, "should have 2 common friends, marge and lisa"
    assert_equal true, shared.map(&:id).include?(people(:marge).id)
    assert_equal true, shared.map(&:id).include?(people(:lisa).id)
    assert_equal false, shared.map(&:id).include?(people(:bart).id)
  end

  def test_shared_friends_count_with
    homer = people(:homer)
    barney = people(:barney)
    homer.is_friends_with(people(:bart))
    homer.is_friends_with(people(:marge))
    homer.is_friends_with(people(:lisa))
    assert 3, homer.friendships.count
    
    barney.is_friends_with(people(:marge))
    barney.is_friends_with(people(:lisa))
    assert 2, barney.friendships.count
    
    assert_equal 2, homer.shared_friends_count_with(barney), "should have 2 common friends, marge and lisa"
    assert_equal 2, homer.friends.count_shared_with(barney), "should have 2 common friends, marge and lisa"
  end

  def test_has_many_created_organizations
    homer = people(:homer)
    org = create_organization(:created_by => homer)
    homer.reload
#    assert_equal org.id, homer.created_organizations.first.id
    assert_equal homer, org.created_by
  end

  def test_has_many_created_products
    homer = people(:homer)
    product = create_product(:created_by => homer)
    homer.reload
    assert homer.created_products.include?(product)
    assert_equal homer, product.created_by
  end

  def test_should_get_and_set_email
    p = people(:quentin)
    assert_equal 'quentin@terantino.tt', p.email
    p.email = "sepp@maier.tt"
    p.save
    p.reload
    assert_equal 'sepp@maier.tt', p.email
  end

  def test_should_get_and_set_gender
    p = people(:quentin)
    assert_equal 'm', p.gender
    p.gender = "f"
    p.save
    p.reload
    assert_equal 'f', p.gender
  end
    
  def test_create_person_should_create_piggy_bank
    assert_difference PiggyBankAccount, :count, 1 do
      p = create_person
      assert_equal '0.00', p.piggy_bank.balance.to_s
      assert_equal '0.00', p.piggy_bank.available_balance.to_s
      p.save
    end
  end

  def test_should_find_or_build_deposit_account
    assert_difference DepositAccount, :count do
      person = people(:homer)
      assert_equal 0, person.deposit_accounts.size
      da = person.find_or_build_deposit_account(:paypal, :paypal_account => "adam@smith.tst")
      assert da.valid?
      assert_equal da, person.deposit_accounts.first
      assert_equal "PaypalDepositAccount", person.deposit_accounts.first.class.name
      assert_equal "adam@smith.tst", person.deposit_accounts.first.paypal_account
      person.save
    end
  end

  def test_should_not_duplicate_deposit_account
    assert_difference DepositAccount, :count do
      person = people(:homer)
      da = person.find_or_build_deposit_account(:paypal, :paypal_account => "adam@smith.tst")
      assert da.valid?
      person.save
    end
    assert_no_difference DepositAccount, :count do
      person = people(:homer)
      da = person.find_or_build_deposit_account(:paypal, :paypal_account => "schmarrn@eimer.tst")
      assert da.valid?
      da.save
      person = Person.find_by_id(person.id)
      assert_equal da, person.find_deposit_account(:paypal)
      assert_equal "schmarrn@eimer.tst", person.find_deposit_account(:paypal).paypal_account
    end
  end
  
  def test_should_find_deposit_account
    person = people(:homer)
    da = person.find_or_build_deposit_account(:paypal, :paypal_account => "adam@smith.tst")
    assert da.valid?
    assert_equal da, person.find_deposit_account(:paypal)
    person.save
    person = Person.find_by_id(person.id)
    assert_equal da, person.find_deposit_account(:paypal)
  end

  def test_should_dependent_destroy
    person = nil
    user = nil
    assert_difference User, :count do
      assert_difference Person, :count do
        user = create_user
      end
    end
    assert user.id
    assert user.person.id
    person = user.person
    
    assert_difference User, :count, -1 do
      assert_difference Person, :count, -1 do
        person.destroy
      end
    end
  end

  def test_should_have_pesonal_business_and_billing_address
    assert_difference Address, :count, 3 do
      person = build_person(:email => "test_it@test.tt")
      assert person.valid?
      assert person.activate!
      person.build_personal_address(valid_personal_address_attributes)
      assert_equal "CA, 94112, United States", person.personal_address.to_s
      assert person.personal_address.valid?, 'invalid personal address'
      person.build_business_address(valid_business_address_attributes)
      assert_equal "101 Rousseau St., San Francisco, CA, 94112, United States", person.business_address.to_s
      assert person.business_address.valid?, 'invalid business address'
      person.build_billing_address(valid_billing_address_attributes)
      assert_equal "Bob Smith, 102 Rousseau St., San Francisco, CA, 94112, United States", person.billing_address.to_s
      assert person.billing_address.valid?, 'invalid billing address'
      assert person.save
      assert person = Person.find_by_id(person.id)
      # address got geocoded
      assert_equal -122.443, person.personal_address.lng
      assert_equal 37.7206, person.personal_address.lat
      # person got geocoded
      assert_equal -122.443, person.lng
      assert_equal 37.7206, person.lat
    end
  end

  def test_should_geocode_with_personal_address
    assert_difference Address, :count do
      person = create_person
      assert person.activate!

      person.build_personal_address(valid_personal_address_attributes)
      assert_equal "CA, 94112, United States", person.personal_address.to_s
      assert person.personal_address.valid?, 'invalid personal address'

      assert person.personal_address.save
      assert person = Person.find_by_id(person.id)
      # address got geocoded
      assert_equal -122.443, person.personal_address.lng
      assert_equal 37.7206, person.personal_address.lat
      # person got geocoded
      assert_equal -122.443, person.lng
      assert_equal 37.7206, person.lat
    end
  end
  
  def test_should_save_and_update_personal_address
    person = nil
    assert_difference Address, :count do
      person = build_person
      person.build_personal_address(valid_personal_address_attributes)
      assert_equal "CA, 94112, United States", person.personal_address.to_s
      assert person.save
    end
    assert_no_difference Address, :count do
      person = Person.find_by_id(person.id)
      person.find_or_build_personal_address
      assert_equal "CA, 94112, United States", person.personal_address.to_s
      person.attributes = {:personal_address_attributes => {:postal_code => '66666'}}
      person.personal_address.save
      person = Person.find_by_id(person.id)
      assert_equal "CA, 66666, United States", person.personal_address.to_s
    end
  end

  def test_should_save_and_update_business_address
    person = nil
    assert_difference Address, :count do
      person = build_person
      person.build_business_address(valid_business_address_attributes)
      assert_equal "101 Rousseau St., San Francisco, CA, 94112, United States", person.business_address.to_s
      assert person.save
    end
    assert_no_difference Address, :count do
      person = Person.find_by_id(person.id)
      person.find_or_build_business_address
      assert_equal "101 Rousseau St., San Francisco, CA, 94112, United States", person.business_address.to_s
      person.attributes = {:business_address_attributes => {:postal_code => '66666'}}
      person.business_address.save
      person = Person.find_by_id(person.id)
      assert_equal "101 Rousseau St., San Francisco, CA, 66666, United States", person.business_address.to_s
    end
  end

  def test_should_save_and_update_billing_address
    person = nil
    assert_difference Address, :count do
      person = build_person
      person.build_billing_address(valid_billing_address_attributes)
      assert_equal "Bob Smith, 102 Rousseau St., San Francisco, CA, 94112, United States", person.billing_address.to_s
      assert person.save
    end
    assert_no_difference Address, :count do
      person = Person.find_by_id(person.id)
      person.find_or_build_billing_address
      assert_equal "Bob Smith, 102 Rousseau St., San Francisco, CA, 94112, United States", person.billing_address.to_s
      person.attributes = {:billing_address_attributes => {:postal_code => '66666'}}
      person.billing_address.save
      person = Person.find_by_id(person.id)
      assert_equal "Bob Smith, 102 Rousseau St., San Francisco, CA, 66666, United States", person.billing_address.to_s
    end
  end
  
  def xtest_should_purchase_and_authorize
    person = people(:homer)
    person.piggy_bank.direct_deposit(Money.new(2985, 'USD'))
    assert_difference Order, :count do
      assert_difference Invoice, :count do
        assert_difference CartLineItem, :count do
          order, payment = person.purchase_and_authorize(Product.three_month_partner_membership, person.piggy_bank)
          assert order, 'no order created'
          assert payment.success?, 'payment invalid'
        end
      end
    end
    assert_equal "0.00", person.piggy_bank.available_balance.to_s
  end
  
  def test_three_month_partner_membership
    person = people(:barney)
    membership = person.three_month_partner_membership
    assert_equal topics(:three_month_partner_membership_en), membership
  end
  
  def test_should_purchase_and_pay_partner_membership_and_upgrade_barney
    person = people(:barney)
    assert !person.partner?
    person.piggy_bank.direct_deposit(Money.new(2485, 'EUR'))
    assert_difference Order, :count do
      assert_difference Invoice, :count do
        assert_difference CartLineItem, :count do
          order, payment = person.purchase_and_pay(person.three_month_partner_membership, person.piggy_bank)
          assert order, 'no order created'
          assert_equal :approved, order.current_state
          assert_equal :paid, order.invoice.current_state
          assert Money.new(2485, 'EUR'), order.line_items.first.total
          assert payment.success?, 'payment invalid'
          assert person.partner?, 'not upgraded to partner account'
        end
      end
    end
    assert_equal Money.new(0, 'EUR'), person.piggy_bank.available_balance
  end

  def test_should_purchase_and_pay_purchasing_credit_and_add_to_piggy_bank
    person = people(:barney)
    credit_card = build_credit_card
    assert_equal Money.new(0, 'EUR'), person.piggy_bank.available_balance
    assert_difference Order, :count do
      assert_difference Invoice, :count do
        order, payment = person.purchase_and_pay(topics(:five_purchasing_credit_en), credit_card)
        assert order, 'no order created'
        assert Money.new(500, 'EUR'), order.line_items.first.total
        assert payment.success?, 'payment invalid'
        assert !person.partner?, 'should still be member account'
      end
    end
    assert_equal Money.new(500, 'EUR'), person.piggy_bank.available_balance
  end

  def test_should_purchase_and_pay_purchasing_credit_and_add_to_piggy_bank_with_cart
    person = people(:barney)
    cart = person.cart
    credit_card = build_credit_card
    assert_equal Money.new(0, 'EUR'), person.piggy_bank.available_balance
    assert_difference Order, :count do
      assert_difference Invoice, :count do
        assert_difference CartLineItem, :count do
          cart.add(topics(:five_purchasing_credit_en))
          order, payment = person.purchase_and_pay(cart, credit_card)
          assert order, 'order created'
          assert Money.new(500, 'EUR'), order.line_items.first.total
          assert payment.success?, 'payment successful'
          assert !person.partner?, 'should still be member account'
        end
      end
    end
    assert_equal Money.new(500, 'EUR'), person.piggy_bank.available_balance
  end
  
  def test_should_have_employments
    homer = people(:homer)
    powerplant = tiers(:powerplant)
    employment = Employment.create(:employee => homer, :employer => powerplant)
    assert employment, 'employment is not valid'
    assert employment.activate!
    assert_equal :active, employment.current_state
    homer = Person.find_by_id(homer.id)
    assert_equal employment, homer.employments.first
    assert_equal powerplant, homer.employers.first
    assert_equal powerplant, homer.organizations.first
  end
  
  def test_should_assign_personal_address_attributes
    assert_difference Address, :count do
      person = build_person
      assert_nil person.personal_address
      person.personal_address_attributes = valid_address_attributes
      assert_equal valid_address_attributes[:city], person.personal_address.city
      person.save
      person.personal_address_attributes = {
        :first_name => 'Sepp',
        :last_name => 'Meier',
        :middle_name => 'B',
        :street_address => '101 B St',
        :city => 'Quebec',
        :province_code => 'QB',
        :province => nil,
        :country_code => 'CA',
        :country => nil
      }
      assert_equal "101 B St, Quebec, QB, 95065, Canada", person.personal_address.to_s
      person.save
    end
  end
  
  def test_should_assign_spoken_language_ids
    person = nil
    person = build_person
    person.spoken_language_ids = SpokenLanguage.find(:all).map(&:id).map(&:to_s)
    assert_equal 3, person.spoken_languages.size
    person.save
    person = Person.find_by_id(person.id)
    assert_equal 3, person.spoken_languages.size
  end
  
  def test_should_activate_and_upgrade
    person = create_person
    assert_equal :created, person.current_state
    assert person.activate!
    assert_equal :member, person.current_state
    assert person.member?
    assert person.upgrade!
    assert_equal :partner, person.current_state
    assert person.partner?
    assert person.downgrade!
    assert_equal :member, person.current_state
    assert person.member?
  end
  
  def test_should_get_total_spending
    homer = people(:homer)
    homer.piggy_bank.direct_deposit(Money.new(10000, 'USD'))
    order, payment = homer.purchase_and_pay(topics(:three_month_partner_membership_en), homer.piggy_bank)
    assert payment.success?
    assert_equal order.total, homer.total_spending
  end

  def xtest_should_get_total_earning
    homer = people(:homer)
    # enhance test
    assert Money.new(0, 'USD'), homer.total_earning
  end
  
  def test_should_be_new_partner
    barney = people(:barney)
    assert !barney.partner?
    assert !barney.is_new_partner?
    barney.piggy_bank.direct_deposit(Money.new(10000, 'EUR'))
    order, payment = barney.purchase_and_pay(topics(:three_month_partner_membership_en), barney.piggy_bank)
    assert payment.success?
    assert barney.partner?
    assert barney.is_new_partner?
    order, payment = barney.purchase_and_pay(topics(:three_month_partner_membership_en), barney.piggy_bank)
    assert payment.success?
    assert !barney.is_new_partner?
  end

  def test_should_redeem_partner_voucher
    user = create_user
    user.person.create_billing_address(valid_address_attributes)
    assert user.person.activate!
    assert user.person.member?
    voucher = PartnerMembershipVoucher.create(:consignee => user.person)
    assert !user.person.ever_subscribed_as_partner?
    
    user.person.cart.add voucher.promotable_product
    user.person.cart.add voucher
    
    assert_equal '0.00', user.person.cart.total.to_s
    order, payment = user.person.purchase_and_pay(user.person.cart, user.person.piggy_bank)
    assert payment.success?
    assert_equal '0.00', order.total.to_s
    assert user.person.ever_subscribed_as_partner?
    assert user.person.is_new_partner?
    assert user.person.partner?
    assert_equal (Time.now.utc + 3.months).to_date, user.person.partner_membership_expires_on
  end

  def test_should_casualize_name
    assert !people(:homer).prefers_casual?
    assert_equal 'Homer Simpson', people(:homer).casualize_name
    assert_equal 'Homer', people(:homer).casualize_name(true)
    assert_equal 'Homer Simpson', people(:homer).casualize_name(false)

    assert people(:bart).prefers_casual?
    assert_equal 'Bart', people(:bart).casualize_name
    assert_equal 'Bart', people(:bart).casualize_name(true)
    assert_equal 'Bart Simpson', people(:bart).casualize_name(false)
  end
  
  def test_active?
    person = create_person
    assert !person.active?, "should not be active"
    person.activate!
    assert person.active?
    assert person.member?
    assert person.upgrade!
    assert person.partner?, "should be partner"
    assert person.active?, "should be active"
  end
  
  def test_should_generate_default_permalink
    person = create_person
    assert person.friendly_id, "should have default permalink"
    assert person.permalink, "should have default permalink"
  end
  
  def test_should_change_custom_id
    person = create_person
    person.custom_id = "hogusbogus"
    person.custom_id_confirmation = "hogusbogus"
    assert person.valid?, 'permalink should be valid'
    assert person.save, 'permalink should save'
    person = Person.find_by_id(person.id)
    assert_equal "hogusbogus", person.custom_id
  end

  def test_should_change_permalink_multiple_times
    person = create_person
    person.custom_id = person.custom_id_confirmation = "first-change"
    assert person.save, 'first custom_id should save'
    person.custom_id = person.custom_id_confirmation = "second-change"
    assert person.valid?, 'second permalink change should also be valid'
    assert person.save, 'second custom_id should save'
    person = Person.find_by_id(person.id)
    assert_equal "second-change", person.custom_id
  end
  
  def test_should_not_validate_custom_id
    user = create_user
    assert user.register!, "should register"
    assert user.activate!, "should activate"
    person = user.person
    assert_equal :member, person.current_state, "should be member"
    # too short
    person.custom_id = person.custom_id_confirmation = "a" * (User::LOGIN_MIN_CHARACTERS - 1)
    assert !person.valid?, 'should not accept too short custom id'
    assert_equal "is too short (minimum is #{User::LOGIN_MIN_CHARACTERS} characters)", person.errors.on(:custom_id)
    # long
    person.custom_id = person.custom_id_confirmation = "a" * (User::LOGIN_MAX_CHARACTERS + 1)
    assert !person.valid?, 'should not accept too long permalink'
    assert_equal "is too long (maximum is #{User::LOGIN_MAX_CHARACTERS} characters)", person.errors.on(:custom_id)
    # funny chars
    person.custom_id = person.custom_id_confirmation = "what_123"
    assert !person.valid?, 'should not accept weird chars as permalink'
    assert_equal "is invalid", person.errors.on(:custom_id)
  end

  def test_should_not_allow_duplicate_custom_id
    other = create_person(:email => "other@person.tt")
    person = create_person(:email => "person@person.tt")
    # short
    person.custom_id = person.custom_id_confirmation = other.custom_id
    assert !person.valid?, 'should not accept duplicate custom id'
    assert_equal "has already been taken", person.errors.on(:permalink)
  end

  def test_should_find_all_active
    assert_equal 7, Person.find_all_active.size
  end

  def test_should_have_interests_tag_type
    person = people(:homer)

    assert_difference Tag, :count, 3 do
      assert_difference Tagging, :count, 3 do
        person.interest = "swimming, BMW, Bathing"
        assert person.save
      end
    end
    person = Person.find_by_id(person.id)
    assert_equal "swimming, BMW, Bathing", person.interest
  end
  
  def test_should_have_interest_with_case_sensitive_tag_types
    homer = people(:homer)
    marge = people(:marge)
    
    assert_difference Tag, :count, 3 do
      assert_difference Tagging, :count, 6 do
        homer.interest = "swimming, BMW, Bathing"
        marge.interest = "Swimming, Bmw, BATHING"
        assert homer.save
        assert marge.save
      end
    end
    homer = Person.find_by_id(homer.id)
    marge = Person.find_by_id(marge.id)
    assert_equal "swimming, BMW, Bathing", homer.interest
    assert_equal "Swimming, Bmw, BATHING", marge.interest
  end

  def test_should_find_by_permalink
    assert_nothing_raised do  # e.g. ActiveRecord::RecordNotFound
      Person.find_by_permalink(people(:homer).permalink)
    end
  end
  
  def test_should_not_find_by_permalink
    person = create_person
    assert_equal "created", person.status
    assert_raise ActiveRecord::RecordNotFound do 
      not_found = Person.find_by_permalink(person.permalink)
    end
  end

  def test_should_geo_location_change
    person = people(:homer)

    assert_equal false, person.geo_location_changed?, "geo location should not be changed" 

    person.lng = 11.2323
    assert_equal true, person.geo_location_changed?, "geo location should be changed" 
    assert person.save

    assert_equal false, person.geo_location_changed?, "geo location should not be changed after save" 

    person.lat = -48.2274
    assert_equal true, person.geo_location_changed?, "geo location should be changed" 
    assert person.save

    assert_equal false, person.geo_location_changed?, "geo location should not be changed after save" 
  end
  
  def test_should_get_geo_location_from_personal_address
    person = create_person
    assert person.activate!
    person.create_personal_address(valid_personal_address_attributes)
    geo = person.geo_location
    assert_equal true, geo.success, "should get geo location"
    assert_equal "CA", geo.state
    assert_equal "94112", geo.zip
  end

  def test_should_get_geo_location_from_business_address
    person = create_person
    person.create_personal_address(valid_personal_address_attributes)
    person.create_business_address(valid_business_address_attributes)
    assert person.activate!
    assert person.upgrade!
    assert_equal :partner, person.current_state
    geo = person.geo_location
    assert_equal true, geo.success, "should get geo location"
    assert_equal "San Francisco", geo.city
    assert_equal "CA", geo.state
    assert_equal "94112", geo.zip
  end

  def test_should_be_geo_coded
    assert people(:homer).geo_coded?, "homer should be geocoded"
  end
  
  def test_should_home_page_url
    person = build_person(:home_page_url => "homepage.com/me")
    assert_equal "http://homepage.com/me", person.home_page_url

    person = build_person(:home_page_url => "http://homepage.com/me")
    assert_equal "http://homepage.com/me", person.home_page_url

    person = build_person(:home_page_url => "https://securehome.com/me")
    assert_equal "https://securehome.com/me", person.home_page_url

    person = build_person(:home_page_url => nil)
    assert_equal nil, person.home_page_url

    person = build_person(:home_page_url => "")
    assert_equal nil, person.home_page_url
  end

  def test_should_blog_url
    person = build_person(:blog_url => "blogger.com/me")
    assert_equal "http://blogger.com/me", person.blog_url

    person = build_person(:blog_url => "http://me.blogspot.com")
    assert_equal "http://me.blogspot.com", person.blog_url

    person = build_person(:blog_url => "me.blogspot.com")
    assert_equal "http://me.blogspot.com", person.blog_url

    person = build_person(:blog_url => "https://secureblog.com/me")
    assert_equal "https://secureblog.com/me", person.blog_url

    person = build_person(:blog_url => nil)
    assert_equal nil, person.blog_url

    person = build_person(:blog_url => "")
    assert_equal nil, person.blog_url
  end
  
  def test_should_assign_twitter_name
    person = build_person(:twitter_name => "ginger72")
    assert_equal "ginger72", person.twitter_name
    assert_equal "http://twitter.com/ginger72", person.twitter_url

    person = build_person(:twitter_name => nil)
    assert_equal nil, person.twitter_name
    assert_equal nil, person.twitter_url
  end

  def test_should_validate_twitter_name
    person = build_person(:twitter_name => "ginger72")
    assert person.valid?, "person should be valid"
    assert_equal nil, person.errors.on(:twitter_name)

    person = build_person(:twitter_name => nil)
    assert person.valid?, "person should be valid"
    assert_equal nil, person.errors.on(:twitter_name)

    person = build_person(:twitter_name => "")
    assert person.valid?, "person should be valid"
    assert_equal nil, person.errors.on(:twitter_name)
  end

  def test_should_not_validate_twitter_name
    person = build_person(:twitter_name => "!@)()")
    assert !person.valid?, "person should not be valid"
    assert person.errors.on(:twitter_name)

    person = build_person(:twitter_name => "1234567890123456")
    assert !person.valid?, "person should not be valid"
    assert person.errors.on(:twitter_name)
  end

  def test_should_attach_avatar
    person = build_person
    person.avatar = File.new(File.join(ROOT, "fixtures", "files", "beetle_48kb.jpg"), 'rb')
    assert person.save, "should save"
    assert person.avatar.file?,"should have file attached"
    assert person.avatar(:thumb).match("thumb_beetle_48kb.jpg"), "should attach thumb"
    assert person.avatar(:profile).match("profile_beetle_48kb.jpg"), "should attach profile"
    assert person.avatar(:portrait).match("portrait_beetle_48kb.jpg"), "should attach portrait"
  end

  def xtest_should_not_validate_avatar_size
    person = build_person
    person.avatar = File.new(File.join(ROOT, "fixtures", "files", "beetle_296kb.jpg"), 'rb')
    assert !person.valid?, "should not validate file size"
    assert_equal "exceeds 256KB image size", person.errors.on(:avatar)
  end

  def test_should_not_validate_avatar_file_type
    person = build_person
    person.avatar = File.new(File.join(ROOT, "fixtures", "files", "beetle_228kb.bmp"), 'rb')
    assert !person.valid?, "should not validate file size"
    assert_equal "GIF, PNG, JPG, and JPEG files only", person.errors.on(:avatar)
  end

  def test_user_id
    person = people(:homer)
    assert_equal person.user.id, person.user_id
  end

  def test_flag_with_user_flags
    person = people(:aaron)
    user = users(:lisa)
    
    flag = user.flags.create :flaggable => person, :reason => "spam", :description => "not acceptable spam"
    assert_equal flag, user.flags.first
    assert_equal "not acceptable spam", flag.description
    assert_equal "spam", flag.reason
    assert_equal user.id, flag.user_id
    assert_equal person.user_id, flag.flaggable_user_id
  end
  
  def test_flag_with_flaggable_add_flag
    person = people(:aaron)
    user = users(:lisa)
    
    person.add_flag(:user => user, :reason => "spam", :description => "not acceptable spam")
    flag = person.flags.first
    assert_equal flag, user.flags.first
    assert_equal "not acceptable spam", flag.description
    assert_equal "spam", flag.reason
    assert_equal user.id, flag.user_id
    assert_equal person.user_id, flag.flaggable_user_id
  end

  def test_find_employees_of
    powerplant = tiers(:powerplant)
    employees = Person.find_employees_of(powerplant)
    assert [people(:homer)], employees
  end

  def test_find_members_of
    powerplant = tiers(:powerplant)
    members = Person.find_members_of(powerplant)
    assert [people(:homer)], members
  end

  def test_should_has_many_sent_invitations_with_dependent_destroy
    assert_difference Invitation, :count, 0 do
      invitor = create_person
      invitee = people(:quentin)
      assert [], invitor.sent_invitations
      
      invite = Invitation.create(valid_invitation_attributes(:invitor => invitor, :invitee => invitee))
      invite.send!
      assert_equal [invite], invitor.sent_invitations
      
      invitor.destroy
    end
  end
  
  def test_should_find_all_featured
    assert person = people(:bart)
    person.update_attributes(:featured => true)
    person.reload
    assert_equal [person], Person.find_all_featured
  end

  def test_acts_as_visitable
    assert visitable = people(:bart)
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

  def test_should_follow
    person = people(:homer)
    follower = people(:marge)
    
    person.follow(follower)
    assert follower.followers.include?(person)
    assert person.following?(follower)
    
    assert_equal 1, follower.followers_count
    person.follow(follower)
    assert_equal 1, follower.followers_count

    person.stop_following(follower)
    follower = Person.find_by_id(follower.id)
    assert_equal 0, follower.followers_count
  end
  
  def test_should_localize_summary
    assert_equal ["summary", "summary_de", "summary_es"].to_set, Person.localized_facets(:summary).to_set
  end

  def test_simple_find_by_query
    assert_equal people(:homer), Person.find_by_query(:first, 'Esta es el perfil de homer')
  end
  
  def test_username_or_name
    person = people(:homer)
    assert_equal true, person.show_name?, "should be true by default"
    assert_equal "Homer Simpson", person.username_or_name
    person.show_name = false
    assert_equal false, person.show_name?
    assert_equal "homer", person.username_or_name
  end
  
  def test_should_have_reputation_points
    homer = people(:homer)
    marge = people(:marge)
    powerplant = tiers(:powerplant)
    assert_equal 0, homer.reputation_points
    
    homer.repute_and_return(50)
    assert_equal 50, homer.reputation_points

    homer.repute_and_return(25, powerplant)
    assert_equal 25, homer.reputation_points(powerplant)
    assert_equal 75, homer.reputation_points
    
    homer.reputations.first.cancel!
    homer = Person.find_by_id(homer.id)
    assert_equal 25, homer.reputation_points(powerplant)
    assert_equal 25, homer.reputation_points
  end
  
  protected

  def valid_personal_address_attributes(options={})
    {
      :postal_code => '94112',
      :province_code => 'CA',
      :country_code => 'US'
    }.merge(options)
  end

  def valid_business_address_attributes(options={})
    {
      :street => '101 Rousseau St.',
      :city => 'San Francisco',
      :postal_code => '94112',
      :province_code => 'CA',
      :country_code => 'US',
      :phone => '+1 (415) 308-5782',
      :mobile => '+1 (415) 308-5783',
      :fax => '+1 (415) 308-5784'
    }.merge(options)
  end

  def valid_billing_address_attributes(options={})
    {
      :first_name => 'Bob',
      :last_name => 'Smith',
      :street => '102 Rousseau St.',
      :city => 'San Francisco',
      :postal_code => '94112',
      :province_code => 'CA',
      :country_code => 'US',
      :phone => '+1 (415) 108-5782',
      :mobile => '+1 (415) 108-5783',
      :fax => '+1 (415) 108-5784'
    }.merge(options)
  end

  def valid_invitation_attributes(options={})
    {
      :invitor => people(:homer),
      :invitor => people(:lisa),
      :message => "hello lisa, this is your invitation!",
      :language => 'en'
    }.merge(options)
  end
  
end
