require File.dirname(__FILE__) + '/../../test_helper'
require 'account/vanities_controller'

# Re-raise errors caught by the controller.
class Account::VanitiesController; def rescue_action(e) raise e end; end

class Account::VanitiesControllerTest < Test::Unit::TestCase
  all_fixtures
  
  def setup
    @controller = Account::VanitiesController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
    
    @request.with_subdomain('us')
    
    login_person(:homer)
  end
  
  def test_should_route
    assert_routing '/account/vanity', hash_for_path(:account_vanity)
  end
  
  def test_should_index_with_partner
    get :show
    assert_response :success
  end
  
  def test_should_update
    login_person(:aaron)
    put :update, {"person"=>{"permalink"=>"hogusbogus", "permalink_confirmation"=>"hogusbogus"}}
    assert_response :redirect
    assert_redirected_to account_path
    assert @person = assigns(:person)
    assert_equal "hogusbogus", @person.permalink
  end
  
  def test_should_not_update_homer
    put :update, {"person"=>{"permalink"=>"hogusbogus", "permalink_confirmation"=>"hogusbogus"}}
    assert_response :success
    assert @person = assigns(:person)
    assert !@person.valid?, "should not have changed permalink"
  end

  protected
  
  def login_person(person)
    if person.is_a?(Person)
      @user = person.user
      @person = person
    elsif person.is_a?(User)
      @user = person
      @person = person.person
    else
      @user = users(person)
      @person = people(person)
    end
    login_as @user
    account_login_as @user
  end
  
end
