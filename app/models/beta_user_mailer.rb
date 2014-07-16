# Sends out welcome messages and link on how to register to beta users
class BetaUserMailer < Notifier
  
  def registered(user, sent_at = Time.now.utc)
    setup_email(user)
    bcc Notifier.admin_email
    subject "Thank you for your interest in Luleka".t
  end
  
  def activated(user, sent_at = Time.now.utc)
    setup_email(user)
    bcc Notifier.admin_email
    subject "Congratulations, you are accepted into the beta program".t
  end

  protected
  
  def setup_email(user, sent_at = nil)
    super(user, sent_at)
    from         Notifier.noreply_email
    recipients   user.email
    body         :user => user, :person => user.person
  end
    
end
