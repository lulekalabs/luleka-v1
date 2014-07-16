module ContactsHelper

  # provides a display message
  # e.g.
  # 'You have 2 contacts in common.' or
  # 'You have no contacts in common.'
  def shared_contacts_display(person, contact, options={})
    defaults = {}
    options = defaults.merge(options).symbolize_keys

    count = person.shared_friends_count_with(contact)
    "You have %{no_of_contacts} in common.".t % {
      :no_of_contacts => if count > 0
        link_to("%d contact" / count, shared_contact_path(contact))
      else
        "no contact".t
      end
    }
  end

  # displays a message with a link to shared contacts between invitation invitor and invitee
  def shared_contacts_from_invitation_display(invitation, options={})
    return if invitation.has_no_registered_invitee?
    if current_user_me?(invitation.invitor)
      shared_contacts_display(invitation.invitor, invitation.invitee)
    else
      shared_contacts_display(invitation.invitee, invitation.invitor)
    end
  end

end
