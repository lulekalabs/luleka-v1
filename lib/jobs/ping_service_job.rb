# Gets the site index page to keep the passenger server instance alive
require 'net/http'
require 'uri'

class PingServiceJob

  def perform
    url = URI.parse("http://us.luleka.com")
    res = Net::HTTP.start(url.host, url.port) {|http| http.get('/')}
    RAILS_DEFAULT_LOGGER.error "** ping_service_job: #{url}/ returned error code #{res.code}" unless res.code == "200"
  end

end  
