# handles the closing of the account
class Account::ClosesController < Account::AccountApplicationController
  include SessionsControllerBase
  
  #--- constants
  MESSAGE_SUCCESS = "Your account was closed.".t
  MESSAGE_ERROR = "You must enter your password and confirm to close your account.".t
  
  #--- actions
  
  def show
  end
  
  def update
    @user = User.authenticate(@user.login, params[:user][:password])
    if @user && params[:user][:destroy_confirmation].to_s.match(/1/)
      @user.suspend!
      destroy_session('/')
      flash[:notice] = MESSAGE_SUCCESS
      return
    end
    @user = current_user
    flash[:error] = MESSAGE_ERROR
    render :action => 'show'
  end
  
end
