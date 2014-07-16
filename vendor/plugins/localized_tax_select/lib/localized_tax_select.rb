module LocalizedTaxSelect
  class << self
    def localized_taxes_array(country_code)
      taxes = country_code ? I18n.translate("#{country_code}", :scope => 'taxes') : []
      if !taxes.blank? && taxes.is_a?(Hash)
        taxes.map {|key, value| ["#{value[:name]} (#{value[:short_name]})", key.to_s.upcase] if key}.sort_by {|country| country.first.parameterize}
      else
        []  
      end
    end
  end
end

module ActionView
  module Helpers
    module FormOptionsHelper
    end

    class InstanceTag
    end
    
    class FormBuilder
    end
  end
end