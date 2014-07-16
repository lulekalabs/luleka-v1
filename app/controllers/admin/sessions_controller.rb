# Admin session handler
class Admin::SessionsController < Admin::AdminApplicationController
  include FrontApplicationBase
  include SessionsControllerBase
  helper :front_application

  #--- layout (override)
  layout 'front'

  #--- filters
  skip_before_filter :login_required, :only => [:new, :create]

  #--- actions
  
  # render new.rhtml
  def new
  end
  
  def create
    create_session
  end

  def destroy
    destroy_session
  end

  protected 
  
  # override from SessionsControllerBase
  def remember_me?
    true
  end

  private
  
  def authenticate_user(login, password, options={})
    user_class.authenticate(login, password)
  end

end
