module PartnersHelper
  
  def new_steplet_description_t(person)
    if person && person.partner?
      "In order to renew or extend your #{SERVICE_PARTNER_NAME} Membership, select from one of the following options.".t
    else
      "In order to become a #{SERVICE_PARTNER_NAME}, select from one of the following options.".t
    end
  end
  
  def complete_steplet_description_t(person=@person)
    result = []
    if person && person.is_new_partner?
      result << "You have been signed up as new Partner.".t
      result << "Your Partner Membership will expire on %{date}.".t % {
        :date => "*#{person.partner_membership_expires_on.to_s(:long)}*"
      }
    else
      result << "You have extended your Partner Membership until %{date}.".t % {
        :date => "*#{person.partner_membership_expires_on.to_s(:long)}*"
      }
    end
    result << "Please review your order below.".t
    result.join(' ')
  end
  
  # returns all possible tax names allowed for the tax_id
  def tax_names_for(person)
    result = LocalizedTaxSelect::localized_taxes_array(person.default_country || Utility.country_code).map {|a| a.first}
    result.to_sentence_with_or
  end

end
