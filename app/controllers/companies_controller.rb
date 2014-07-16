# This controller is a decendant of organizations controller. 
# It manages all company related resources
class CompaniesController < OrganizationsController
  
  protected

  def tier_class
    Company
  end

end
