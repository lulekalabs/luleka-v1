module OrganizationsHelper
  
  # alias for tier_image_path
  def organization_image_path(org, options={})
    tier_image_path(org, options)
  end
  
  # alias for tier_image_tag
  def organization_image_tag(org, options={})
    tier_image_tag(org, options)
  end

end
