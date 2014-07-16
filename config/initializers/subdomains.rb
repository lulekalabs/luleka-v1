#--- subdomain_routes plugin
case RAILS_ENV 
when /staging/ then SubdomainRoutes::Config.domain_length = 3 # e.g. staging.luleka.net
else SubdomainRoutes::Config.domain_length = 2 # e.g. luleka.com, luleka.local
end

#--- subdomain fu
=begin
SubdomainFu.tld_sizes = {
  :development => 1,  # luleka.local
  :test => 1,         # luleka.local
  :staging => 2,      # staging.luleka.net
  :production => 1    # luleka.com
}
SubdomainFu.mirrors = ["www"]  
SubdomainFu.preferred_mirror = "www"
=end