# Implements the Paypal Payflow Pro specific gateway
class PayflowProGateway < Gateway
  #--- accessors
  cattr_accessor :payflow_pro_login
  cattr_accessor :payflow_pro_password
  cattr_accessor :payflow_pro_partner
  cattr_accessor :payflow_pro_certification_id

  #--- class methods
  class << self 
    
    def config_file_name
      "payflow_pro.yml"
    end

    # returns a configuration context read from a yml file in /config
    def config(file_name=nil)
      # Authorize.net configuration
      result = YAML.load_file(RAILS_ROOT + "/config/#{file_name || config_file_name}")[RAILS_ENV].symbolize_keys
      @@payflow_pro_login = result[:login]
      @@payflow_pro_password = result[:password]
      @@payflow_pro_partner = result[:partner]
      @@payflow_pro_certification_id = result[:certification_id]
      if result[:mode] == 'test'
        # Tell ActiveMerchant to use the Payflow Pro sandbox
        ActiveMerchant::Billing::Base.mode = :test
      end
      result
    end
  
    # returns a gateway instance unless there is one assigned globally from the
    # environment files
    def gateway(a_config_file_name=nil)
      unless @@gateway
        payflow_pro_config = config(a_config_file_name)
        gw = ActiveMerchant::Billing::PayflowGateway.new({
          :login  => @@payflow_pro_login,
          :password => @@payflow_pro_password,
          :partner => @@payflow_pro_partner,
          :certification_id => @@payflow_pro_certification_id
        }.merge(payflow_pro_config[:mode] == 'test' ? { :test => true } : {}))
      else
        gw = @@gateway
      end
      gw
    end
  
  end

end