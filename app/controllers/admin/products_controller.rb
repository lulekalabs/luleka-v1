class Admin::ProductsController < Admin::TopicsController

  #--- active scaffold
  active_scaffold :product do |config|
    #--- columns
    config.columns = @@standard_columns
    config.create.columns = @@crud_columns
    config.update.columns = @@crud_columns
    config.show.columns = @@show_columns
    config.list.columns = @@list_columns
    
    config.create.multipart = true
    config.update.multipart = true

    #--- action links

    config.action_links.add @@activate_link
    config.action_links.add @@erase_link
    config.action_links.add @@toggle_suspend_link

    #--- labels
    columns[:image_url].label = "Image"
    columns[:country_code].label = "Country"
    columns[:language_code].label = "Language"
  end  

end
