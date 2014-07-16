# Sends email when kases are shared using email
class EmailMailer < Notifier

  #--- notifiers
  
  def message(email, sent_at=Time.now.utc)
    from       email.from
    recipients email.to
    sent_on    sent_at
    subject    email.subject
    body       :email => email
  end
  
  def share_kase(email, kase, sent_at=Time.now.utc)
    from       email.from
    recipients email.from
    bcc        email.to_a
    sent_on    sent_at
    subject    email.subject
    body       :email => email, :kase => kase
  end

end
