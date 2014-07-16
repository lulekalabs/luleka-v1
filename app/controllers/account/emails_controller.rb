# change email address
class Account::EmailsController < Account::AccountApplicationController

  #--- actions
  
  def show
  end
  
  def update
    @user = User.change_email(@user.login, params[:user][:password], @user.email, params[:user][:email])
    if @user && @user.valid?
      flash[:notice] = "Your email address was changed successfully.".t
      redirect_to account_url
      return
    end
    flash[:error] = "There were problems changing your email address.".t
    @user = current_user
    render :action => 'show'
  end
  
end
