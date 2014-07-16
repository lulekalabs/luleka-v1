# Creates and refreshes the sitemap by pinging all major search engines
require 'rake'
class RefreshSitemapJob

  def perform
    system("rake sitemap:refresh") if RAILS_ENV == "production"
  end

end  
