require File.dirname(__FILE__) + '/../test_helper'

class AdminUserTest < ActiveSupport::TestCase
  all_fixtures

  def test_should_create_admin_user
    assert_difference AdminUser, :count do
      admin_user = create_admin_user
      assert !admin_user.new_record?, "#{admin_user.errors.full_messages.to_sentence}"
    end
  end

  def test_should_initialize_activation_code_upon_creation
    admin_user = AdminUser.create({
      :login => 'quire',
      :email => 'quire@example.com',
      :password => 'quire',
      :password_confirmation => 'quire'
    })
    assert_not_nil admin_user.activation_code
    admin_user.save
    admin_user = AdminUser.find_by_id(admin_user.id)
#    assert_not_nil admin_user.activation_code
  end

  def test_should_create_and_start_in_pending_state
    admin_user = create_admin_user
    admin_user.reload
    assert admin_user.pending?
  end


  def test_should_require_login
    assert_no_difference AdminUser, :count do
      u = create_admin_user(:login => nil)
      assert u.errors.on(:login)
    end
  end

  def test_should_require_password
    assert_no_difference AdminUser, :count do
      u = create_admin_user(:password => nil)
      assert u.errors.on(:password)
    end
  end

  def test_should_require_password_confirmation
    assert_no_difference AdminUser, :count do
      u = create_admin_user(:password_confirmation => nil)
      assert u.errors.on(:password_confirmation)
    end
  end

  def test_should_require_email
    assert_no_difference AdminUser, :count do
      u = create_admin_user(:email => nil)
      assert u.errors.on(:email)
    end
  end

  def test_should_reset_password
    admin_users(:quentin).update_attributes(:password => 'new password', :password_confirmation => 'new password')
    assert_equal admin_users(:quentin), AdminUser.authenticate('quentin', 'new password')
  end

  def test_should_not_rehash_password
    admin_users(:quentin).update_attributes(:login => 'quentin2')
    assert_equal admin_users(:quentin), AdminUser.authenticate('quentin2', 'test')
  end

  def test_should_authenticate_admin_user
    assert_equal admin_users(:quentin), AdminUser.authenticate('quentin', 'test')
  end

  def test_should_set_remember_token
    admin_users(:quentin).remember_me
    assert_not_nil admin_users(:quentin).remember_token
    assert_not_nil admin_users(:quentin).remember_token_expires_at
  end

  def test_should_unset_remember_token
    admin_users(:quentin).remember_me
    assert_not_nil admin_users(:quentin).remember_token
    admin_users(:quentin).forget_me
    assert_nil admin_users(:quentin).remember_token
  end

  def test_should_remember_me_for_one_week
    before = 1.week.from_now.utc
    admin_users(:quentin).remember_me_for 1.week
    after = 1.week.from_now.utc
    assert_not_nil admin_users(:quentin).remember_token
    assert_not_nil admin_users(:quentin).remember_token_expires_at
    assert admin_users(:quentin).remember_token_expires_at.between?(before, after)
  end

  def test_should_remember_me_until_one_week
    time = 1.week.from_now.utc
    admin_users(:quentin).remember_me_until time
    assert_not_nil admin_users(:quentin).remember_token
    assert_not_nil admin_users(:quentin).remember_token_expires_at
    assert_equal admin_users(:quentin).remember_token_expires_at, time
  end

  def test_should_remember_me_default_two_weeks
    before = 2.weeks.from_now.utc
    admin_users(:quentin).remember_me
    after = 2.weeks.from_now.utc
    assert_not_nil admin_users(:quentin).remember_token
    assert_not_nil admin_users(:quentin).remember_token_expires_at
    assert admin_users(:quentin).remember_token_expires_at.between?(before, after)
  end

  def test_should_register_passive_admin_user
    admin_user = create_admin_user(:password => nil, :password_confirmation => nil)
    assert admin_user.passive?
    admin_user.update_attributes(:password => 'new password', :password_confirmation => 'new password')
    admin_user.register!
    assert admin_user.pending?
  end

  def test_should_suspend_admin_user
    admin_users(:quentin).suspend!
    assert admin_users(:quentin).suspended?
  end

  def test_suspended_admin_user_should_not_authenticate
    admin_users(:quentin).suspend!
    assert_not_equal admin_users(:quentin), AdminUser.authenticate('quentin', 'test')
  end

  def test_should_unsuspend_admin_user_to_active_state
    admin_users(:quentin).suspend!
    assert admin_users(:quentin).suspended?
    admin_users(:quentin).unsuspend!
    assert admin_users(:quentin).active?
  end

  def test_should_unsuspend_admin_user_with_nil_activation_code_and_activated_at_to_passive_state
    admin_users(:quentin).suspend!
    admin_users(:quentin).update_attributes(:activation_code => nil, :activated_at => nil)
    assert admin_users(:quentin).suspended?
    admin_users(:quentin).reload.unsuspend!
    assert admin_users(:quentin).passive?
  end

  def test_should_unsuspend_admin_user_with_activation_code_and_nil_activated_at_to_pending_state
    admin_users(:quentin).suspend!
    admin_users(:quentin).update_attributes(:activation_code => 'foo-bar', :activated_at => nil)
    assert admin_users(:quentin).suspended?
    admin_users(:quentin).reload.unsuspend!
    assert admin_users(:quentin).pending?
  end

  def test_should_delete_admin_user
    assert_nil admin_users(:quentin).deleted_at
    admin_users(:quentin).delete!
    assert_not_nil admin_users(:quentin).deleted_at
    assert admin_users(:quentin).deleted?
  end

  def test_create_roles
    aaron = admin_users(:aaron)
    aaron.roles << admin_roles(:translator)
    assert_equal true, aaron.has_role?(:translator), "should have role translator"
    assert_equal true, aaron.save, "should save"
    aaron = AdminUser.find_by_id(aaron.id)
    assert_equal true, aaron.has_role?(:translator), "should still have role translator"
    assert_equal false, aaron.has_role?(:admin), "should not have role admin"
    assert_equal 1, aaron.roles.size, "should have 1 role"
  end

  def test_add_admin_roles
    quentin = admin_users(:quentin)
    quentin.roles << admin_roles(:translator)
    assert_equal true, quentin.save, "should save"
    quentin = AdminUser.find_by_id(quentin.id)
    assert_equal true, quentin.has_role?(:admin), "should have admin right from fixture"
    quentin.roles << admin_roles(:moderator)
    assert_equal true, quentin.save, "should save"
    assert_equal 3, quentin.roles.size, "should have 3 roles"
  end

  protected
  
  def create_admin_user(options = {})
    record = AdminUser.create({ :login => 'quire', :email => 'quire@example.com', :password => 'quire', :password_confirmation => 'quire' }.merge(options))
    record.register! if record.valid?
    record
  end
end
