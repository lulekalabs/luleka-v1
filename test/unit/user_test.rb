require File.dirname(__FILE__) + '/../test_helper'

class UserTest < ActiveSupport::TestCase
  # Be sure to include AuthenticatedTestHelper in test/test_helper.rb instead.
  # Then, you can remove it from this and the functional test.
  include AuthenticatedTestHelper
  all_fixtures

  def setup
    User.password_deferred = false
    Utility.pre_launch = false
  end

  def test_should_create_user
    assert_difference User, :count do
      assert_difference Person, :count do
        user = create_user
        assert !user.new_record?, "#{user.errors.full_messages.to_sentence}"
      end
    end
  end

  def test_should_have_name
    u = users(:homer)
    assert u
    assert_equal 'Homer Simpson', u.name
  end
  
  def test_should_initialize_activation_code_upon_creation
    user = create_user
    user.reload
    assert_not_nil user.activation_code
  end

  def test_should_create_and_start_in_pending_state
    user = create_user
    user.reload
    assert user.pending?
  end


  def test_should_require_login
    assert_no_difference User, :count do
      u = create_user(:login => nil)
      assert u.errors.on(:login)
    end
  end

  def test_should_require_password
    assert_no_difference User, :count do
      u = create_user(:password => nil)
      assert u.errors.on(:password)
    end
  end

  def test_should_require_password_confirmation
    assert_no_difference User, :count do
      u = create_user(:password_confirmation => nil)
      assert u.errors.on(:password_confirmation)
    end
  end

  def test_should_require_email
    assert_no_difference User, :count do
      u = create_user(:email => nil)
      assert u.errors.on(:email)
    end
  end

  def test_should_reset_password
    users(:quentin).update_attributes(:password => 'new password', :password_confirmation => 'new password')
    assert_equal users(:quentin), User.authenticate('quentin', 'new password')
  end

  def test_should_not_rehash_password
    users(:quentin).update_attributes(:login => 'quentin2')
    assert_equal users(:quentin), User.authenticate('quentin2', 'test')
  end

  def test_should_authenticate_user
    assert_equal users(:quentin), User.authenticate_by_login('quentin', 'test')
  end

  def test_should_authenticate_user_with_email
    assert_equal users(:quentin), User.authenticate_by_login_or_email('quentin@terantino.tt', 'test')
  end

  def test_should_authenticate_by_login_or_email
    assert_equal users(:quentin), User.authenticate_by_login_or_email('quentin', 'test')
    assert_equal users(:quentin), User.authenticate_by_login_or_email('quentin@terantino.tt', 'test')
  end

  def test_should_not_authenticate_user_with_email
    assert_nil User.authenticate_by_login_or_email('aaron@weiz.tt', 'test')
  end

  def test_should_set_remember_token
    users(:quentin).remember_me
    assert_not_nil users(:quentin).remember_token
    assert_not_nil users(:quentin).remember_token_expires_at
  end

  def test_should_unset_remember_token
    users(:quentin).remember_me
    assert_not_nil users(:quentin).remember_token
    users(:quentin).forget_me
    assert_nil users(:quentin).remember_token
  end

  def test_should_remember_me_for_one_week
    before = 1.week.from_now.utc
    users(:quentin).remember_me_for 1.week
    after = 1.week.from_now.utc
    assert_not_nil users(:quentin).remember_token
    assert_not_nil users(:quentin).remember_token_expires_at
    assert users(:quentin).remember_token_expires_at.between?(before, after)
  end

  def test_should_remember_me_until_one_week
    time = 1.week.from_now.utc
    users(:quentin).remember_me_until time
    assert_not_nil users(:quentin).remember_token
    assert_not_nil users(:quentin).remember_token_expires_at
    assert_equal users(:quentin).remember_token_expires_at, time
  end

  def test_should_remember_me_default_two_weeks
    before = 2.weeks.from_now.utc
    users(:quentin).remember_me
    after = 2.weeks.from_now.utc
    assert_not_nil users(:quentin).remember_token
    assert_not_nil users(:quentin).remember_token_expires_at
    assert users(:quentin).remember_token_expires_at.between?(before, after)
  end

  def test_should_register_passive_user
    user = create_user(:password => nil, :password_confirmation => nil)
    assert user.passive?
    user.update_attributes(:password => 'new password', :password_confirmation => 'new password')
    user.register!
    assert user.pending?
    assert ActionMailer::Base.deliveries.last.body.include?(user.activation_code)
  end

  def test_should_suspend_user
    user = users(:quentin)
    user.suspend!
    user = User.find_by_id(user.id)
    assert user.suspended?
    assert user.suspended_at, 'should set suspended_at'
  end

  def test_suspended_user_should_not_authenticate
    user = users(:quentin)
    user.suspend!
    assert_not_equal user, User.authenticate('quentin', 'test')
  end

  def test_should_unsuspend_user_to_active_state
    user = users(:quentin)
    user.suspend!
    user = User.find_by_id(user.id)
    assert user.suspended_at, 'should set suspended_at'
    assert user.suspended?
    assert user.unsuspend!
    user = User.find_by_id(user.id)
    assert_nil user.suspended_at, 'should remove suspended_at'
    assert user.active?
  end

  def test_should_unsuspend_user_with_nil_activation_code_and_activated_at_to_passive_state
    users(:quentin).suspend!
    users(:quentin).update_attributes(:activation_code => nil, :activated_at => nil)
    assert users(:quentin).suspended?
    users(:quentin).reload.unsuspend!
    assert users(:quentin).passive?
  end

  def test_should_unsuspend_user_with_activation_code_and_nil_activated_at_to_pending_state
    u = users(:quentin)
    u.suspend!
    User.update(u.id, :activation_code => 'foo-bar', :activated_at => nil)
    u.reload
    assert_nil u.activated_at
    assert users(:quentin).suspended?
    u.reload.unsuspend!
    assert u.pending?
  end

  def test_should_delete_user
    assert_nil users(:quentin).deleted_at
    users(:quentin).delete!
    assert_not_nil users(:quentin).deleted_at
    assert users(:quentin).deleted?
  end

  def test_should_verify
    user = create_user(:password => 'verify', :password_confirmation => 'verify')
    assert_equal :pending, user.current_state
    assert_not_nil user.activation_code
    assert_nil user.activated_at
    assert_equal user, User.verify(user.login, 'verify', user.activation_code)
    assert_equal :active, user.reload.current_state
  end

  def test_should_not_verify
    user = create_user(:password => 'verify', :password_confirmation => 'verify')
    assert_equal :pending, user.current_state
    assert_not_nil user.activation_code
    assert_nil user.activated_at
    assert_nil User.verify('sepp', 'verify', user.activation_code)
    assert_nil User.verify(user.login, 'sepp', user.activation_code)
    assert_nil User.verify(user.login, 'verify', user.activation_code + 'bull')
    assert_equal :pending, user.reload.current_state
  end
  
  def test_should_change_password
    user = create_user(:password => 'verify', :password_confirmation => 'verify')
    user.activate!
    user = User.change_password(user.login, 'verify', 'change', 'change')
    assert_not_nil user
  end

  def test_should_not_change_password
    user = create_user(:password => 'verify', :password_confirmation => 'verify')
    user.activate!
    assert_nil User.change_password('sepp', 'verify', 'change', 'change')
    assert_nil User.change_password(user.login, 'derify', 'change', 'change')
    assert_nil User.change_password(user.login, 'verify', 'dhange', 'change')
    assert_nil User.change_password(user.login, 'verify', 'change', 'dhange')
  end

  def xtest_should_change_email
    user = create_user(:password => 'verify', :password_confirmation => 'verify', :email => "adam@smith.tt")
    assert user.valid?
    user.activate!
    user = User.change_email(user.login, 'verify', "adam@smith.tt", "eva@smith.tt")
    assert_not_nil user
  end

  def test_should_get_and_set_email
    u = users(:quentin)
    assert_equal 'quentin@terantino.tt', u.email
    u.email = "sepp@maier.tt"
    u.save
    u.reload
    assert_equal 'sepp@maier.tt', u.email
  end

  def test_should_get_and_set_gender
    u = users(:quentin)
    assert_equal 'm', u.gender
    u.gender = "f"
    u.save
    u = User.find_by_id u.id
    assert_equal 'f', u.gender
  end
    
  def test_create_user_should_create_persons_piggy_bank
    assert_difference PiggyBankAccount, :count, 1 do
      assert_difference Person, :count, 1 do
        assert_difference User, :count, 1 do
          u = create_user(:currency => 'EUR')
          assert_equal '0.00', u.person.piggy_bank.balance.to_s
          assert_equal '0.00', u.person.piggy_bank.available_balance.to_s
          u.person.save
          assert u.person.activate!, "should activate person"
          assert_equal '1.00', u.person.piggy_bank.balance.to_s
          assert_equal '1.00', u.person.piggy_bank.available_balance.to_s
          u.save
        end
      end
    end
  end

  def test_should_dependent_destroy
    user = nil
    assert_difference User, :count do
      assert_difference Person, :count do
        user = create_user
      end
    end
    assert user.id
    assert user.person.id
    
    assert_difference User, :count, -1 do
      assert_difference Person, :count, -1 do
        user.destroy
      end
    end
  end

  def xtest_should_resend_confirmation_request
    user = create_user
    assert user.register!
    activation_code = user.activation_code
    confirm_user = User.resend_confirmation_request(user.login, user.email)
    assert confirm_user
    assert ActionMailer::Base.deliveries.last.body.include?(confirm_user.activation_code)
    assert_equal user, confirm_user
    assert_not_equal activation_code, confirm_user.activation_code
  end

  def test_should_confirm_activation_code
    user = create_user
    assert user.register!
    assert_not_nil user.activation_code
    user.activation_code_confirmation = user.activation_code
    assert user.valid?, 'activation codes match'
  end

  def test_should_not_confirm_activation_code
    user = create_user
    assert user.register!
    assert_not_nil user.activation_code
    user.activation_code_confirmation = 'balony code'
    assert !user.valid?, 'activation codes do not match'
    assert user.errors.on(:activation_code)
    assert user.activation_code_confirmation?
  end

  def test_should_return_activation_code_confirmation?
    user = create_user
    user.activate!
    user.activation_code_confirmation = 'bla'
    assert user.activation_code_confirmation?, 'has assigned confirmation code'
  end
  
  def test_should_not_return_activation_code_confirmation?
    user = User.new
    assert !user.activation_code_confirmation?

    user = create_user
    user.activate!
    assert !user.activation_code_confirmation?
  end

  def xtest_should_not_create_person_if_user_verification_code_is_invalid
    user = User.new(valid_user_attributes({
      :verification_code => 'do_not',
      :verification_code_session => 'match'
    }))
    assert !user.valid?
    assert user.errors.on(:verification_code)
    assert_no_difference User, :count do 
      assert_no_difference Person, :count do 
        assert !user.save
      end
    end
  end
  
  def test_should_authenticate_and_trace
    user = create_user(
      :login => 'record',
      :password => 'record_sign_in',
      :password_confirmation => 'record_sign_in'
    )
    assert user.valid?
    assert user.activate!
    assert !user.signed_in_at, 'should not be set, yet'
    assert_equal user, authenticated_user = User.authenticate("record", "record_sign_in", :trace => true)
    assert authenticated_user.signed_in_at
  end

  def test_default_language
    user = users(:aaron)
    assert_equal 'en', user.default_language
    assert_equal 'en', user.language
  end

  def test_default_locale
    user = users(:aaron)
    assert_equal :"en-US", user.default_locale
  end

  def test_state_machine_for_pre_launch
    Utility.pre_launch = true
    assert user = create_user
    assert user.register!
    assert_equal :screening, user.current_state
    assert ActionMailer::Base.deliveries.last.body.include?("private beta phase")

    assert user.accept!
    assert_equal :pending, user.current_state

    assert user.activate!
    assert_equal :active, user.current_state
  end

  def test_state_machine_for_pre_launch_and_guest
    User.password_deferred = true
    Utility.pre_launch = true
    user = build_user
    user.guest!
    assert user.register!
    assert_equal :screening, user.current_state
  end

  def test_state_machine_next_state_for_event
    Utility.pre_launch = true
    assert user = create_user
    assert user.register!
    assert_equal :screening, user.current_state
    assert_equal :pending, user.next_state_for_event(:accept)
  end

  def test_tz_offset_from_javascript
    @user = build_user
    @user.tz_offset_from_javascript = 180
    assert_equal "Brasilia", @user.time_zone
    assert_equal 180, @user.tz_offset_from_javascript
  end
  
  def test_user_and_person_and_personal_address_with_deferred_password
    User.password_deferred = true
    assert_difference User, :count do 
      assert_difference Person, :count do 
        assert_difference Address, :count do 
          I18n.switch_locale :"de-DE" do 
            @user = User.new({
              "tz_offset_from_javascript"=>"180",
              "terms_of_service"=>"1",
              "login"=>"hh",
              "email"=>"h@h.com",
              "email_confirmation"=>"h@h.com"
            })
            @user.person.attributes = {"personal_address_attributes" => {
                "country_code"=>"US",
                "province_code"=>"DC"
              },
              "academic_title_id"=>"0",
              "have_expertise"=>["one", "two", "three"],
              "gender"=>"m",
              "notify_on_newsletter"=>"1",
              "first_name"=>"Hans",
              "last_name"=>"Hauer",
              "middle_name"=>""}
            
            assert @user.save, "should save user"
            assert @user.register!, "should register"
            assert_equal :pending, @user.current_state
            assert_equal "EUR", @user.currency
            assert_equal "de", @user.language
            assert_equal "Hans Hauer", @user.name
            assert_equal "DC, Vereinigte Staaten", @user.person.personal_address.to_s
            assert_equal "de", @user.language
            assert_equal "EUR", @user.currency
          end
        end
      end
    end
  end

  def test_should_register_guest_user
    assert_difference User, :count do
      @user = User.new(:login => "guest_user", :email => "guest@user.tt", :email_confirmation => "guest@user.tt")
      @user.guest!
      assert_equal true, @user.valid?, "should be valid"
      assert_equal true, @user.register!, "should register"
      assert_equal true, @user.pending?, "should be pending"
    end
  end
  
  def test_should_be_valid_person
    @user = users(:homer)
    assert_equal true, @user.valid_person?, "should be valid person"
    assert_equal true, @user.person.errors.empty?, "should not have errors"
  end

  def test_should_not_be_valid_person
    @user = users(:homer)
    @user.person.first_name = ""
    assert_equal false, @user.valid_person?, "should not be valid person"
    assert_equal true, @user.person.errors.empty?, "should not have errors"
  end
  
  def test_should_not_activate_as_guest
    assert_difference User, :count do
      @user = create_user
      @user.guest!
      assert_equal true, @user.save
      @user.activate!
      assert_equal false, @user.active? 
    end
  end
  
  def test_should_set_and_get_locale
    @user = User.new
    @user.locale = :"en-US"
    assert_equal :"en-US", @user.locale
    assert_equal "en", @user.language
    assert_equal "US", @user.country

    @user.locale = "de"
    assert_equal :"de-DE", @user.locale
    assert_equal "de", @user.language
    assert_equal "DE", @user.country
  end

  def test_should_not_set_unsupported_locale
    I18n.switch_locale :"de-DE" do 
      @user = User.new
      assert_equal :"de-DE", @user.locale
      @user.locale = :"en-XX"
      assert_equal :"de-DE", @user.locale
      assert_equal "de", @user.language
      assert_equal "DE", @user.country
    end
  end
  
  def test_should_be_valid_on_change_currency
    @user = create_user
    assert_equal "USD", @user.currency
    assert_equal "USD", @user.default_currency
    @user.currency = "EUR"
    assert_equal true, @user.valid?
  end

  def test_should_not_be_valid_on_change_currency
    @user = create_user
    @person = @user.person.direct_deposit_and_return("1.00")
    assert_equal "USD", @user.currency
    @user.currency = "EUR"
    assert_equal false, @user.valid?
    assert_equal "cannot be changed", @user.errors.on(:currency)
  end
  
  def test_should_change_currency
    @user = create_user
    assert_equal "USD", @user.currency
    assert_equal "USD", @user.person.piggy_bank.currency
    @user.currency = "EUR"
    assert_equal true, @user.valid?
    assert_equal "EUR", @user.currency
    assert_equal true, @user.activate!
     assert_equal true, @user.active?
    @user = User.find_by_id(@user.id)
    assert_equal "EUR", @user.person.piggy_bank.currency
    assert @user.activate!
    @user = User.find_by_id(@user.id)
    assert_equal "EUR", @user.person.piggy_bank.currency
    assert_equal Money.new(100, "EUR"), @user.person.piggy_bank.balance
  end

  def test_should_be_valid_on_supported_currency
    @user = build_user(:currency => "EUR")
    assert_equal true, @user.valid?
  end
  
  def test_should_not_be_valid_on_unsupported_currency
    @user = build_user(:currency => "UXX")
    assert_equal false, @user.valid?
  end

end
