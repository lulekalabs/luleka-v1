# change the way the user's profile appears in the URL
class Account::VanitiesController < Account::AccountApplicationController

  #--- constants
  MESSAGE_SUCCESS = "Your changes were successful.".t
  
  #--- actions
  
  def show
  end
  
  def update
    @person.attributes = params[:person] if params[:person]
    if @person.valid?
      @person.save
      flash[:notice] = MESSAGE_SUCCESS
      redirect_to account_url
      return
    end
    render :action => 'show'
  end
  
end
