# change and reset password
class Account::PasswordsController < Account::AccountApplicationController

  #--- constants
  MESSAGE_SUCCESS = "Your password was changed successfully.".t
  MESSAGE_ERROR = "There were problems changing your password.".t
  
  #--- actions
  
  def show
  end
  
  def update
    @user = User.change_password(@user.login, params[:user][:password],
      params[:user][:new_password], params[:user][:new_password_confirmation])
    if @user && @user.valid?
      flash[:notice] = MESSAGE_SUCCESS
      redirect_to account_url
      return
    end
    flash[:error] = MESSAGE_ERROR
    @user = current_user
    render :action => 'show'
  end
  
  
end
