# Provides controller helpers for cart and order session managers
module MerchantsControllerBase
  def self.included(base)
    base.extend(ClassMethods)
    base.send :helper_method, :form_error_messages_for_payment_object
  end
  
  module ClassMethods
  end
  
  protected

  #--- cart 
  
  # cart session parameter symbol, e.g. :cart
  def cart_session_param
    :cart
  end
  
  # assign cart object or delete if nil is assigned
  def current_cart=(new_cart)
    session[cart_session_param] = new_cart ? new_cart.to_yaml : nil
    @current_cart = new_cart || false
  end
  
  # returns a current cart instance if stored in the session
  def current_cart
    @current_cart ||= load_cart_from_session unless @current_cart == false
  end
  
  # handles the cart loading from session 
  def load_cart_from_session
    #--- leave due to YAML bug
    CartLineItem
    Product
    #--- end leave due to YAML bug
    persisted_cart = YAML.load(session[cart_session_param].to_s)
    # rebuild cart as persisted cart line items cannot be saved
    persisted_cart.line_items.each_with_index do |line_item, index|
      persisted_cart.line_items[index] = line_item.clone
    end if persisted_cart
    self.current_cart = persisted_cart
  end

  #--- order
  
  # hash key for order session id
  def order_session_param
    :order_id
  end
  
  # Accesses the current order from the session. 
  # Future calls avoid the database because nil is not equal to false.
  def current_order
    @current_order ||= load_order_from_session unless @current_order == false
  end

  # Store the given order in the session.
  def current_order=(new_order)
    session[order_session_param] = new_order ? new_order.id : nil
    @current_order = new_order || false
  end
  
  def load_order_from_session
    self.current_order = Order.find_by_id(session[order_session_param]) if session[order_session_param]
  end

  # builds default billing address or fills default parameters,
  # unless there is a billing address
  def build_billing_address(person=@person)
    if person.billing_address
      person.billing_address.attributes = {
        :country_code => (person.business_address || person.personal_address).country_code,
        :country => (person.business_address || person.personal_address).country,
      }
    else
      person.build_billing_address({
        :academic_title_id => person.academic_title ? person.academic_title_id : nil,
        :gender => person.gender,
        :first_name => person.first_name,
        :last_name => person.last_name,
        :country_code => (person.business_address || person.personal_address).country_code,
        :country => (person.business_address || person.personal_address).country,
        :province_code => (person.business_address || person.personal_address).province_code,
        :province => (person.business_address || person.personal_address).province,
      }.merge((person.business_address || person.personal_address).content_attributes))
    end
  end
  
end