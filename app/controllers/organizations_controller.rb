# This controller handles all organizations, including companies, agencies and
# supclasses of the Organization model
class OrganizationsController < TiersController
  helper :products

  #--- actions

  protected
  
  def tier_class
    Organization
  end

end
