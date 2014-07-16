# Scaffold for all organization scaffolds
class Admin::OrganizationsController < Admin::TiersController

  #--- active scaffold
  active_scaffold :organization do |config|
    #--- columns
    standard_columns = @@standard_columns
    crud_columns = @@crud_columns
    config.columns = @@standard_columns
    config.create.columns = @@crud_columns
    config.update.columns = @@crud_columns
    config.show.columns = @@show_columns
    config.list.columns = @@list_columns

    config.create.multipart = true
    config.update.multipart = true

    #--- action links
    config.action_links.add @@activate_link
    config.action_links.add @@toggle_suspend_link
    config.action_links.add @@erase_link

    #--- labels
    columns[:image_url].label = "Image"
    columns[:country_code].label = "Country"
  end  

end
