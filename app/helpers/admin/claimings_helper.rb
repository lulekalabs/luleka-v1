module Admin::ClaimingsHelper
  
  #--- active scaffold helpers
  def name_column(record)
    link_to record.person.name, admin_person_path(record.person) if record.person
  end

  def organization_column(record)
    link_to record.organization.name, admin_organization_path(record.organization.id) if record.organization
  end

end
