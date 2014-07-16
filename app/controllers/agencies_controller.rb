# This controller handles all agency related resources and is 
# derived from organizations_controller
class AgenciesController < OrganizationsController
  
  protected
  
  def tier_class
    Agency
  end
  
end
