module ClaimingsHelper

  # fields for with update attributes
  def fields_for_object(object, &block)
    prefix = object.new_record? ? 'new' : 'existing'
    fields_for("claiming[#{ prefix }_#{ object.class.name.underscore }_attributes][]", object, &block)
  end
  
  def email_example(claiming)
    "#{h(claiming.person.first_name.downcase)}.#{h(claiming.person.last_name.downcase)}@#{claiming.organization.site_domain}"
  end
  
end
