class UserMailer < Notifier

  # sends out an activation link
  def confirm_account(user, sent_at = Time.now.utc)
    setup_email(user, sent_at)
    subject        "Confirm your account".t
  end

  # sent when the email address was changed to a new email address
  def change_email(user, sent_at = Time.now.utc)
    setup_email(user, sent_at)
    subject        "Your email address has changed".t
  end

  # sends reset code to assign new password to your account
  def reset_password(user, sent_at = Time.now.utc)
    setup_email(user, sent_at)
    subject        "Link to reset your password".t
  end
  
  # sends password after reset
  def change_password(user, sent_at = Time.now.utc)
    setup_email(user, sent_at)
    subject        "Your new password is active".t
  end
  
  protected
  
  def setup_email(user, sent_at = nil)
    super(user, sent_at)
    from         Notifier.noreply_email
    recipients   user.email
    body         :user => user, :person => user.person
  end

end