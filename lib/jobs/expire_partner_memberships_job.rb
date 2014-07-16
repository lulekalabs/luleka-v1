# Expires partners who's subscription ran out already
# Warns those partners who soon (7 days prior) will run out of their subscription
class ExpirePartnerMembershipsJob

  def perform
    
    # expire partner membership
    Person.find_all_expired_partners.each do |partner|
      partner.expire!
    end

    # send info to soon to expire partners
    Person.find_all_soon_to_expire_partners.each do |partner|
      partner.send_partner_membership_soon_to_expire
    end
    
  end

end  
