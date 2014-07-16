# = LocalizedCurrencySelect
# 
# View helper for displaying select list with countries:
# 
#     localized_currency_select(:user, :currency)
# 
# Works just like the default Rails' +country_select+ plugin, but stores currencies as
# currency *codes*, not *names*, in the database.
# 
# You can easily translate currency codes in your application like this:
#     <%= I18n.t "EUR", :scope => 'countries' %>
# 
# Uses the Rails internationalization framework (I18n) for translating the names of countries.
#
module LocalizedCurrencySelect
  class << self
    # Returns array with codes and localized currency names (according to <tt>I18n.locale</tt>)
    # for <tt><option></tt> tags
    def localized_currencies_array
      I18n.translate(:currencies).map {|key, value| [value[:name], key.to_s.upcase]}.sort_by {|country| country.first.parameterize}
    end

    def localized_currencies_array_with_unit_and_code
      I18n.translate(:currencies).map {|key, value| ["#{value[:name]} - #{key.to_s.upcase} - #{value[:format][:unit]}", key.to_s.upcase]}.sort_by {|country| country.first.parameterize}
    end

    # Return array with codes and localized currency names for array of currency codes passed as argument
    # == Example
    #   priority_currencies_array([:EUR, :USD])
    #   # => [ ['Euro', 'EUR'], ['US Dollar', 'USD'] ]
    def priority_currencies_array(currency_codes=[])
      currencies = I18n.translate(:currencies)
      currency_codes.map {|code| [currencies[code.to_s.upcase.to_sym][:name], code.to_s.upcase]}
    end
  end
end

module ActionView
  module Helpers

    module FormOptionsHelper

      def localized_currency_select(object, method, priority_currencies = nil, options = {}, html_options = {})
        InstanceTag.new(object, method, self, options.delete(:object)).
          to_localized_currency_select_tag(priority_currencies, options, html_options)
      end

      def localized_currency_select_tag(name, selected_value = nil, priority_currencies = nil, html_options = {})
        select_tag name.to_sym, localized_currency_options_for_select(selected_value, priority_currencies), html_options.stringify_keys
      end

      def localized_currency_options_for_select(selected = nil, priority_currencies = nil)
        currency_options = ""
        if priority_currencies
          currency_options += options_for_select(LocalizedCurrencySelect::priority_currencies_array(priority_currencies), selected)
          currency_options += "<option value=\"\" disabled=\"disabled\">-------------</option>\n"
        end
        return currency_options + options_for_select(LocalizedCurrencySelect::localized_currencies_array, selected)
      end
      
    end

    class InstanceTag
      def to_localized_currency_select_tag(priority_currencies, options, html_options)
        html_options = html_options.stringify_keys
        add_default_name_and_id(html_options)
        value = value(object)
        content_tag("select",
          add_options(
            localized_currency_options_for_select(value, priority_currencies),
            options, value
          ), html_options
        )
      end
    end
    
    class FormBuilder
      def localized_currency_select(method, priority_currencies = nil, options = {}, html_options = {})
        @template.localized_currency_select(@object_name, method, priority_currencies, options.merge(:object => @object), html_options)
      end
    end

  end
end