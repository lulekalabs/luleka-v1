# change account international settings
class Account::InternationalsController < Account::AccountApplicationController
  
  #--- constants
  MESSAGE_SUCCESS = "Your settings were saved".t

  #--- actions
  
  def show
  end
  
  def update
    @user.attributes = params[:user]
    if @user.save
      flash[:notice] = MESSAGE_SUCCESS
      redirect_to account_url
      return
    end
    render :action => 'show'
  end
  
end
