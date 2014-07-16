module UsersHelper

  # Collects all languages for a selection that a person speaks and adds
  # current locase and user preferred languages
  # Usage: collect_languages_of_user( user_object)
  # Requires a person object to be assigned to the user 
  def collect_spoken_languages_of_person(person)
    languages = []
    languages = person.spoken_languages.collect { |l| l.english_name }      # stored languages
    languages.push SpokenLanguage.find_english_name_by_code(language_code)  # add site language as default
    languages.push SpokenLanguage.find_english_name_by_code(person.user.language)  # add user language as default
    return languages.uniq
  end

  # Assigns spoken languages from personal_profile and business_profile forms
  def assign_spoken_languages_to_person(person, spoken_languages)
    unless spoken_languages.nil?
      spoken_languages.each do |lang_id, spoken|
        if "true" == spoken
          unless person.spoken_languages.find_by_id(lang_id)
            person.spoken_languages << SpokenLanguage.find_by_id( lang_id )
          end
        else
            person.spoken_languages.delete(SpokenLanguage.find_by_id( lang_id ))
        end
      end
    end
    person
  end

  # e.g. Change English, Germany and Time Zone "Hawaii"
  def switcher_i18n_label_title(user=@user)
    result = []
    result << (!user.language.blank? ? I18n.t(user.language, :scope => "languages") : User.human_attribute_name(:language))
    result << (!user.country.blank? ? I18n.t(user.country, :scope => "countries") : User.human_attribute_name(:country))
    result << (!user.default_currency.blank? ? "#{User.human_attribute_name(:currency)}: #{user.default_currency}" : User.human_attribute_name(:currency))
    result << (!user.time_zone.blank? ? "#{User.human_attribute_name(:time_zone)}: #{user.tz.to_s}" : User.human_attribute_name(:time_zone))
    result.to_sentence.strip_period
  end
  
end
