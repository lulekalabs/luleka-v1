# = LocalizedCountrySelect
# 
# View helper for displaying select list with countries:
# 
#     localized_province_select(:user, :country, "DE")
# 
# Works just like the default Rails' +country_select+ plugin, but stores provinces as
# province *codes*, not *names*, in the database.
# 
# You can easily translate province codes in your application like this:
#     <%= I18n.t @address.province_code, :scope => 'provinces.DE' %>
# 
# Uses the Rails internationalization framework (I18n) for translating the names of provinces.
# 
# Use Rake task <tt>rake import:province_select 'de' 'es' 'de' </tt> for importing province names
# from Unicode.org's CLDR repository (http://www.unicode.org/cldr/data/charts/summary/root.html)
# 
# Code adapted from Rails' default +country_select+ plugin (previously in core)
# See http://github.com/rails/country_select/tree/master/lib/country_select.rb
#
module LocalizedProvinceSelect
  class << self
    # Returns array with codes and localized provinces names (according to <tt>I18n.locale</tt>)
    # for <tt><option></tt> tags
    def localized_provinces_array(country_code)
      I18n.translate("provinces.#{country_code}").map {|key, value| [value, key.to_s.upcase] if value}.compact.sort_by {|province| province.first}
    end
    
    # Return array with codes and localized country names for array of country codes passed as argument
    # == Example
    #   priority_countries_array(:DE, [:BY, :HS])
    #   # => [ ['Bavaria', 'BY'], ['Hesse', 'HS'] ]
    def priority_provinces_array(country_code, province_codes=[])
      provinces = I18n.translate("provinces.#{country_code.to_s.upcase}")
      province_codes.map {|code| [provinces[code.to_s.upcase.to_sym], code.to_s.upcase]}
    end
  end
end

module ActionView
  module Helpers

    module FormOptionsHelper

      # Return select and option tags for the given object and method, using +localized_province_options_for_select+ 
      # to generate the list of option tags. Uses <b>province code</b>, not name as option +value+.
      # Province codes listed as an array of symbols in +priority_provinces+ argument will be listed first
      def localized_province_select(object, method, country_code, priority_countries = nil, options = {}, html_options = {})
        InstanceTag.new(object, method, self, options.delete(:object)).
          to_localized_province_select_tag(country_code, priority_countries, options, html_options)
      end

      # Return "named" select and option tags according to given arguments.
      # Use +selected_value+ for setting initial value
      def localized_province_select_tag(name, country_code, selected_value = nil, priority_countries = nil, html_options = {})
        select_tag name.to_sym, localized_province_options_for_select(country_code, selected_value, priority_countries), html_options.stringify_keys
      end

      # Returns a string of option tags for provinces according to locale. Supply the country code in upper-case ('US', 'DE') 
      # as +selected+ to have it marked as the selected option tag.
      # Province codes listed as an array of symbols in +priority_provinces+ argument will be listed first
      def localized_province_options_for_select(country_code, selected = nil, priority_provinces = nil)
        province_options = ""
        if priority_provinces
          province_options += options_for_select(LocalizedProvinceSelect::priority_provinces_array(country_code, priority_provinces), selected)
          province_options += "<option value=\"\" disabled=\"disabled\">-------------</option>\n"
        end
        return province_options + options_for_select(LocalizedProvinceSelect::localized_provinces_array(country_code), selected)
      end
      
    end

    class InstanceTag
      def to_localized_province_select_tag(country_code, priority_countries, options, html_options)
        html_options = html_options.stringify_keys
        add_default_name_and_id(html_options)
        value = value(object)
        content_tag("select",
          add_options(
            localized_province_options_for_select(country_code, value, priority_countries),
              options, value
              ), html_options
        )
      end
    end
    
    class FormBuilder
      def localized_province_select(method, country_code, priority_countries = nil, options = {}, html_options = {})
        @template.localized_province_select(@object_name, method, country_code, priority_countries, options.merge(:object => @object), html_options)
      end
    end

  end
end