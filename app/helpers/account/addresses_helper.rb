module Account::AddressesHelper
  
  def kind_account_address_path(address)
    send("#{address.kind}_account_address_path")
  end
  
end
