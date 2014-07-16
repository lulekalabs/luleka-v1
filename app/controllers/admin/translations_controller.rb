# handles the translations of globalize view and models
class Admin::TranslationsController < Admin::AdminApplicationController

  before_filter :load_locale
  before_filter :authorization_required

  #--- actions
  
  def show
    @models = []
    models_to_translate.each do |model|
      @models.push(model)
    end
    @page_title = "Translations"
  end
  
  protected 
  
  def find_model_class_from_modeltype(value)
    # returns the correct model from value string, ie returns Board class when given "Board"
    models_to_translate.detect(nil) {|model| model.to_s == value}
  end
  
  def find_english_for_translations translations
    english_texts = []
    # recieve model tranlations
    # *note* translations must be all of the same originating class
    # look up originating class
    model_class = find_model_class_from_modeltype(translations[0].table_name.classify)
    # grab all the facets
    facets = model_class.send(:globalize_facets)
    # grab ALL the models
    models = model_class.send(:find,:all)
    # find each english text
    models.each do |model|
      facets.each do |facet|
        english = model.send(facet)
        english_texts.push(english)
      end
    end
    english_texts
  end
  
  def find_english(mt)
    # recieve model translation
    # look up originating object
    model_class = find_model_class_from_modeltype(mt.table_name.singularize.capitalize)
    model = model_class.send( :find, mt.item_id )
    english = model.send(mt.facet)
    return english
  end

  # returns an array of models to translate
  def models_to_translate
    Utility.models_to_translate
  end

  # overrides default dom_id to work with new records in model translations
  def dom_id(object, prefix=nil)
    "#{prefix ? prefix.to_s + '_' : nil}#{object.class.name}_#{object.id}"
  end
  helper_method :dom_id

  # before filter
  def load_locale
    @locale = Locale.find_by_code(params[:code]) if params[:code]
    @locales = []
    @locales = Locale.find(:all, :conditions => ["locales.code LIKE ?", "#{params[:code]}%"]) if params[:code]
  end

  def list_authorized?
    current_user && current_user.has_role?(:translator)
  end

  def create_authorized?
    current_user && current_user.has_role?(:translator)
  end

  def update_authorized?
    current_user && current_user.has_role?(:translator)
  end

  def delete_authorized?
    current_user && current_user.has_role?(:translator)
  end

  # checks if user can do this
  def authorization_required
    case action_name.to_s
    when /index/, /show/ then list_authorized?
    when /create/ then create_authorized?
    when /update/ then update_authorized?
    when /destroy/ then delete_authorized?
    end
    false
  end
  
end
