module Globalize
  module ActiveRecord
    module CoreExtensions
      module ClassMethods

        # returns all localiced columns of a given base column name
        #
        # e.g.
        #
        #   # with en-US locale active
        #   Person.localized_facets(:name)  ->  ['name', 'name_de', 'name_es']
        #
        #   # with German language priority
        #   Person.localized_facets(:name, "de")  ->  ['name_de', 'name_es', 'name']
        #
        def localized_facets(column, language_code=I18n.locale_language)
          columns = []
          if base = column_names.find {|col| "#{column}" == col}
            Utility.active_language_codes.sort {|a, b| a == "#{language_code}" ? -1 : 1}.each do |language_code|
              columns << base if language_code.to_sym == I18n.locale_language(I18n.default_locale).to_sym
              column_names.each {|col| columns << "#{column}_#{language_code}" if "#{column}_#{language_code}" == col}
            end
          end
          columns
        end

        # dito but without base name, returns only e.g. ['name_de', 'name_es']
        def localized_facets_without_base(column, language_code=I18n.locale_language)
          columns = []
          if base = column_names.find {|col| "#{column}" == col}
            Utility.active_language_codes.sort {|a, b| a == "#{language_code}" ? -1 : 1}.each do |language_code|
              column_names.each {|col| columns << "#{column}_#{language_code}" if "#{column}_#{language_code}" == col}
            end
          end
          columns
        end
        
      end
    end
  end
end
ActiveRecord::Base.send(:extend, Globalize::ActiveRecord::CoreExtensions::ClassMethods)
