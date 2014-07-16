# Account application controller is the base controller for all account related
# actions. It requires to sign in a seperate realm and will sign out after a period
# of user inactivity to protect the users most personal information.
class Account::AccountApplicationController < FrontApplicationController
  
  #--- constants
  SESSION_EXPIRES_IN_MINUTES = 20
  USER_SESSION_PARAM = :user_account_id
  
  #--- filters
  skip_before_filter :destroy_account_session
  
  # used for changing password
  # TODO necessary here or move to User?
  User.class_eval do 
    attr_accessor :current_password
    attr_accessor :new_password
  end
  
  #--- actions
  
  protected 

  # preserves front app session parameter
  # one for the front end (..._without_account)
  # and one for account (..._with_account)
  def user_session_param_with_account
    USER_SESSION_PARAM
  end
  alias_method_chain :user_session_param, :account
  
  def return_to_param
    :account_return_to
  end
  
  def account_controller
    new_account_session_path
  end
 
  def account_login_path
    new_account_session_path
  end

  def ssl_required?
    ssl_supported?
  end
  
  # overrides from front application controller
  # we need to make sure that the current user of the 
  # front application controller is also removed properly
  def current_user=(new_user)
    super(new_user)
    session[user_session_param_without_account] = session[user_session_param_with_account] \
      if session[user_session_param_with_account]
    @current_user = new_user || false
  end

  # override from authenticate system
  # try to login from front end session if longer than XX minutes ago or take the account session
  def current_user
    @current_user ||= (login_from_session_without_account || login_from_session_with_account) unless @current_user == false
  end
  
  # override from authorized system
  # Called from #current_user.  First attempt to login by the user id stored in the session.
  #
  # first attempt to get the user from the front end session
  # check if he has logged in less than XX minutes ago
  def login_from_session_with_account
    self.current_user = user_class.find_by_id(session[user_session_param_with_account]) if session[user_session_param_with_account]
  end
  alias_method_chain :login_from_session, :account

  # override from authenticated system
  # added mechanism to check if we are in a "fresh" session
  def login_from_session_without_account
    if session[user_session_param_without_account]
      if front_user = user_class.find_by_id(session[user_session_param_without_account])
        if front_user.signed_in_at && front_user.signed_in_at > Time.now.utc - SESSION_EXPIRES_IN_MINUTES.minutes
          self.current_user = front_user
        end
      end
    end
  end
  
  # adds https to session url
  def ssl_account_session_url
    account_session_url(:only_path => false, :protocol => ssl_supported? ? 'https://' : 'http://')
  end
  helper_method :ssl_account_session_url

end
