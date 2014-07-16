# handles account notification settings
class Account::NotificationsController < Account::AccountApplicationController
  
  #--- constants
  MESSAGE_SUCCESS = "Your settings were saved".t
  
  #--- actions
  
  def show
  end
  
  def update
    @person.attributes = params[:person]
    if @person.save
      flash[:notice] = MESSAGE_SUCCESS
      redirect_to account_url
      return
    end
    render :action => 'show'
  end
  
end
