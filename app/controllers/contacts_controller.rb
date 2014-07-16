# Manages the users contacts. A user's contacts are all befriended people
# Contacts can be managed by accepting or declining contact requests
class ContactsController < FrontApplicationController
  #--- filters

  #--- theme
  set_theme :profile

  #--- actions
  
  # renders a list of all the user's accepted contacts (friends)
  def index
    @people = do_search_people(@person, :friends, :with_tags => !request.xhr?,
      :url => hash_for_contacts_path)
  end

  # renders a list of pending invitations requests
  def pending
    @title = "Pending Contact Requests".t
    @invitations = do_search_people(@person.received_invitations.pending)
    respond_to do |format|
      format.html { render :template => 'contacts/pending' }
      format.js { return }
    end
  end
  
  # shows a list of contacts in common between current_user
  # and person :id
  def shared
    @contact = Person.find(params[:id])
    redirect_to contacts_path and return if @person == @contact
    @title = "Shared Contacts with %{name}".t % { :name => @contact.name }
    @people = do_search_people(@person.friends.shared_with(@contact), nil, :with_tags => true)
    render :template => 'contacts/index'
  end
  
end
