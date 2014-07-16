# Used to send emails to people from profile
class EmailPeopleController < FrontApplicationController
  
  #--- filters
  before_filter :load_profile_or_redirect
  
  #--- layout
  layout :choose_layout
  
  #--- actions

  def new
    @email = @person.build_email(:receiver => @profile)
  end
  
  def create
    @email = @person.build_email(params[:email].merge(:receiver => @profile))
    
    respond_to do |format|
      format.js {
        if @email.valid?
          @email.deliver
          render :update do |page|
            page << close_modal_javascript
          end
          return
        else
          render :update do |page|
            page.replace dom_class(Email), render_file('email_people/new.html.erb')
          end
          return
        end
      }
      format.html {
        if @email.valid?
          @email.deliver
          flash[:notice] = "Message has been sent!".t
          redirect_to person_path(@profile)
          return
        end
        render :template => 'email_people/new'
        return
      }
    end
  end
  
  protected
  
  def load_profile_or_redirect
    @profile = Person.finder(params[:person_id]) if params[:person_id]
    unless @profile
      redirect_to people_path
      return false
    end
  end

  private
  
  # Helper to choose a layout based on criteria
  def choose_layout
    request.xhr? ? 'modal' : 'front'
  end
  
end
