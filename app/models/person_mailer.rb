class PersonMailer < Notifier

  # Welcomes Citizens and Experts to the system
  def welcome(person, new_status, sent_at = Time.now.utc)
    subject        person.partner? ? "Your #{SERVICE_NAME} Partnership is confirmed!".t : "Welcome to #{SERVICE_NAME}!".t
    recipients     person.email
    from           Notifier.noreply_email
    sent_on        sent_at
    
    body( :person => person, :status => new_status )
  end

  # Send a note when the membership expired
  def partner_membership_expired(person, sent_at = Time.now.utc)
    subject        "Your membership has expired".t
    recipients     person.email
    from           Notifier.noreply_email
    sent_on        sent_at
    body( :person => person )
  end

  def partner_membership_soon_to_expire(person, sent_at = Time.now.utc)
    subject        "Your membership will expire soon".t
    recipients     person.email
    from           Notifier.noreply_email
    sent_on        sent_at
    body( :person => person )
  end


end
