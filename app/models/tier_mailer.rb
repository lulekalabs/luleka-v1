# Takes care of all tier related mails
class TierMailer < Notifier

  #--- notifiers
  
  def registration(tier, sent_at=Time.now.utc)
    from       Notifier.noreply_email
    recipients tier.created_by.email
    sent_on    sent_at
    subject    "Your community \"%{name}\" has been registered".t % {:name => tier.name}
    body       :tier => tier
  end
  
  def activation(tier, sent_at = Time.now.utc)
    from       Notifier.noreply_email
    recipients tier.created_by.email
    sent_on    sent_at
    subject    "The community \"%{name}\" has been activated".t % {:name => tier.name}
    body       :tier => tier
  end
  
end
