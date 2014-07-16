require File.dirname(__FILE__) + '/../test_helper'
require 'people_controller'

# Re-raise errors caught by the controller.
class PeopleController; def rescue_action(e) raise e end; end

class PeopleControllerTest < Test::Unit::TestCase
  all_fixtures

  def setup
    @controller = PeopleController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new

    @request.with_subdomain('us')

    login_as :homer
  end

  def test_should_route
    @person = people(:homer)
    
    assert_routing "/people", hash_for_path(:people)
    
    assert_routing "/people/#{@person.to_param}", hash_for_path(:person, {:id => @person.to_param})

    assert_routing "/people/#{@person.to_param}/kases",
      hash_for_path(:people, {:id => @person.to_param, :action => 'kases'})

    assert_routing "/people/#{@person.to_param}/contacts",
      hash_for_path(:people, {:id => @person.to_param, :action => 'contacts'})

    assert_routing "/people/#{@person.to_param}/shared_contacts",
      hash_for_path(:people, {:id => @person.to_param, :action => 'shared_contacts'})
    
    assert_routing "/people/#{@person.to_param}/visitors",
      hash_for_path(:people, {:id => @person.to_param, :action => 'visitors'})

    assert_recognizes(hash_for_path(:list_item_expander_person, :id => @person.to_param),
      {:path => "/people/#{@person.to_param}/list_item_expander", :method => :post})
      
    assert_recognizes(hash_for_path(:invite_person, :id => @person.to_param),
      {:path => "/people/#{@person.to_param}/invite", :method => :post})

    assert_routing "/people/#{@person.to_param}/invitations", 
      hash_for_path(:person_invitations, {:person_id => @person.to_param})
      
    assert_routing "/tags/#{tags(:beer).to_param}/people", 
      hash_for_path(:tag_people, {:tag_id => tags(:beer).to_param})

    assert_recognizes(hash_for_path(:follow_person, :id => @person.to_param),
      {:path => "/people/#{@person.to_param}/follow", :method => :put})

    assert_recognizes(hash_for_path(:stop_following_person, :id => @person.to_param),
      {:path => "/people/#{@person.to_param}/stop_following", :method => :put})

    assert_recognizes(hash_for_path(:destroy_contact_person, :id => @person.to_param),
      {:path => "/people/#{@person.to_param}/destroy_contact", :method => :delete})
      
  end

  def test_security
    logout
    assert_requires_login :index
    assert_requires_login :show
    assert_requires_login :list_item_expander
  end

  def test_should_get_index
    get :index
    assert_response :success
  end

  def test_should_get_index_and_switch_to_user_locale
    login_as :homer
    self.current_locale = 'de-DE'
    get :index
    assert_response :success
    assert_equal users(:homer).default_locale, @current_locale = assigns(:current_locale)
  end
  
  def test_should_get_show
    get :show, :id => people(:homer).permalink
    assert_response :success
  end
  
  def test_should_get_kases
    get :kases, :id => people(:homer).permalink
    assert_response :success
    assert @kases = assigns(:kases)
    assert !@kases.empty?, "should have kases already"
  end
  
  def test_should_delete_destroy_contact
    people(:homer).is_friends_with(people(:marge))
    people(:homer).reload
    assert people(:homer).is_friends_with?(people(:marge)), "should be friends"
    xhr :delete, :destroy_contact, :id => people(:marge).permalink
    assert_response :success
    assert marge = assigns(:person)
    people(:homer).reload
    assert !people(:homer).is_friends_with?(people(:marge)), "should not be friends"
  end
  
end
