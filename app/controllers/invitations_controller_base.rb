# provides controller helpers for invitations common methods across controllers,
# mostly methods to store and retrieve invitations from session and cookie
module InvitationsControllerBase
  def self.included(base)
    base.extend(ClassMethods)
  end
  
  module ClassMethods
    
  end
  
  protected

  # hash key for invitation session id
  def invitation_session_param
    :invitation_id
  end
  
  def invitation_cookie_auth_token
    "#{invitation_session_param}_auth_token".to_sym
  end
  
  # Accesses the current invitation from the session. 
  # Future calls avoid the database because nil is not equal to false.
  def current_invitation
    @current_invitation ||= load_invitation_from_session unless @current_invitation == false
  end

  # Store the given invitation in the session.
  def current_invitation=(new_invitation)
    session[invitation_session_param] = new_invitation ? new_invitation.id : nil
    @current_invitation = new_invitation || false
  end
  
  def load_invitation_from_session
    self.current_invitation = Invitation.find_by_id(session[invitation_session_param]) if session[invitation_session_param]
  end

  def load_invitation_from_cookie
    invitation = cookies[invitation_cookie_auth_token] && Invitation.find_by_uuid(cookies[invitation_cookie_auth_token])
    if invitation && !invitation.accepted? && !invitation.declined?
      cookies[invitation_cookie_auth_token] = {:value => invitation.uuid, :expires => invitation.created_at + 3.months}
      self.current_invitation = invitation
    end
  end

  # used in before filter
  def clear_current_invitation
    self.current_invitation = nil
  end
  
end