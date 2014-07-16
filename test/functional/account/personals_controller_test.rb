require File.dirname(__FILE__) + '/../../test_helper'
require 'account/personals_controller'

# Re-raise errors caught by the controller.
class Account::PersonalsController; def rescue_action(e) raise e end; end

class Account::PersonalsControllerTest < Test::Unit::TestCase
  all_fixtures
  
  def setup
    @controller = Account::PersonalsController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
    
    @request.with_subdomain('us')
    
    @user = users(:homer)
    @person = people(:homer)
    login_as :homer
    account_login_as :homer
  end
  
  def test_should_route
    assert_routing '/account/personal', hash_for_path(:account_personal)
    assert_recognizes(hash_for_path(:account_personal, :action => 'update'), {:path => '/account/personal', :method => :put})
  end
  
  def test_should_show
    get :show
    assert_response :success
  end

  def test_should_update
    @person.birthdate = Date.parse("2/26/1972")
    @person.prefers_casual = true
    put :update, params_for(@person)
    assert_equal Account::PersonalsController::MESSAGE_SUCCESS, @response.flash[:notice]
    assert_response :redirect
  end

  protected
  
  def params_for(person, options={})
    {"person"=>{"birthdate(1i)"=>"#{person.birthdate.year}", "birthdate(2i)"=>"#{person.birthdate.month}", "gender"=>"m", "birthdate(3i)"=>"#{person.birthdate.day}", "prefers_casual"=>"#{person.prefers_casual}"}}
  end
  
end
