# provides controller helpers for voucher related methods in users, partners and voucher controller
module VouchersControllerBase
  def self.included(base)
    base.extend(ClassMethods)
  end
  
  module ClassMethods
    
  end
  
  protected

  # hash key for voucher session id
  def voucher_session_param
    :voucher_id
  end
  
  def voucher_cookie_auth_token
    "#{voucher_session_param}_auth_token".to_sym
  end
  
  # Accesses the current voucher from the session. 
  # Future calls avoid the database because nil is not equal to false.
  def current_voucher
    @current_voucher ||= load_voucher_from_session || load_voucher_from_cookie unless @current_voucher == false
  end

  # Store the given voucher in the session.
  def current_voucher=(new_voucher)
    session[voucher_session_param] = new_voucher ? new_voucher.id : nil
    @current_voucher = new_voucher || false
  end
  
  def load_voucher_from_session
    self.current_voucher = Voucher.find_by_id(session[voucher_session_param]) if session[voucher_session_param]
  end
  
  def load_voucher_from_cookie
    voucher = cookies[voucher_cookie_auth_token] && Voucher.find_by_uuid(cookies[voucher_cookie_auth_token])
    if voucher && !voucher.expired? && !voucher.redeemed?
      cookies[voucher_cookie_auth_token] = {:value => voucher.uuid, :expires => voucher.expires_at}
      self.current_voucher = voucher
    end
  end

  # returns current voucher only if it is a partner membership voucher
  # assigns consignee_confirmation to voucher as current user.person,
  # since we need to validate if this person, the potential consignee, 
  # is the consignee if one exists or the potential consignee must not
  # be a partner already.
  def current_partner_voucher
    if (partner_voucher = current_voucher) && current_voucher.is_a?(PartnerMembershipVoucher)
      partner_voucher.consignee_confirmation = @person if @person
      partner_voucher
    end
  end

end