class ClaimingMailer < Notifier

  def confirmation_request(claiming, sent_at = Time.now.utc)
    subject("Confirm your employment with %{org}".t % {:org => claiming.organization.name})
    recipients     claiming.email
    from           Notifier.noreply_email
    sent_on        sent_at
    body :claiming => claiming, :organization => claiming.organization,
      :person => claiming.person, :activation_code => claiming.activation_code
  end

  def confirmation(claiming, sent_at = Time.now.utc)
    subject("Your employment at %{org} is confirmed".t % {:org => claiming.organization.name})
    recipients     claiming.email
    from           Notifier.noreply_email
    sent_on        sent_at
    body :claiming => claiming, :organization => claiming.organization,
      :person => claiming.person
  end

end