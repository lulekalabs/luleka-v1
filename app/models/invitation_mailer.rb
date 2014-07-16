# Handles all invitation related mails.
class InvitationMailer < Notifier

  def request_to_existing_user(invitation, sent_at = Time.now.utc)
    subject        "%{name} wants to be your contact".t % {:name => invitation.invitor.name}
    recipients     invitation.invitee.email
    from           Notifier.noreply_email
    sent_on        sent_at
    body :invitation => invitation, :invitor => invitation.invitor, :invitee => invitation.invitee
  end

  def request_to_new_user(invitation, sent_at = Time.now.utc)
    subject        "%{name} invites you to join #{SERVICE_NAME}".t % {:name => invitation.invitor.name}
    recipients     invitation.to_invitee.email
    from           Notifier.noreply_email
    sent_on        sent_at
    body :invitation => invitation, :invitor => invitation.invitor, :invitee => invitation.invitee
  end

  def request_confirmation(invitation, sent_at = Time.now.utc)
    subject        "Your invitation to %{name}".t % {:name => invitation.invitee_name}
    recipients     invitation.invitor.email
    from           Notifier.noreply_email
    sent_on        sent_at
    body :invitation => invitation, :invitor => invitation.invitor, :invitee => invitation.invitee
  end

  def accepted_confirmation(invitation, sent_at = Time.now.utc)
    subject        "%{name} accepted your invitation".t % {:name => invitation.invitee_name}
    recipients     invitation.invitor.email
    from           Notifier.noreply_email
    sent_on        sent_at
    body :invitation => invitation, :invitor => invitation.invitor, :invitee => invitation.to_invitee
  end
  
end