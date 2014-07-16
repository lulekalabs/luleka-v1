# all methods that are shared between user and partner controllers
module UsersControllerBase
  def self.included(base)
    base.extend(ClassMethods)
  end
  
  module ClassMethods
    
  end
  
  protected

  # loads allo available partner membership product lines for the current user
  # used in users and partners controller
  def build_partner_memberships(user=current_user)
    cart = user ? user.person.cart : Cart.new(Utility.currency_code)
    @partner_memberships = cart.cart_line_items(Product.find_available_partner_memberships(
      :country_code => Utility.country_code, # user.person.default_country,
      :language_code => false
    ))
  end

  # assigns the selected instance variable 
  def select_current_partner_membership
    if current_partner_voucher
      @selected = @voucher = current_partner_voucher
      @voucher.code_confirmation = @voucher.code
    else
      @selected = @cart ? @cart.line_items.first : @partner_memberships.first
    end
  end


end
