# Subclass of translations controller to handle globalize model translations
class Admin::ModelTranslationsController < Admin::TranslationsController
  #--- filters
  protect_from_forgery :except => [:update]
  
  #--- actions
  
  def index
    if params[:class_name]
      @class_name = params[:class_name] unless @class_name
      class_names = [@class_name]
    else
      class_names = models_to_translate.map(&:name)
    end
    
    @translations = []
    @records = []

    class_names.each do |class_name|
      # find a better way to do the following:
      if models_to_translate.map(&:to_s).include?(class_name)
        klass = class_name.constantize
        index = 0
        klass.find(:all).each do |record|
          klass.translated_attribute_names.each do |facet|
            @translations.push(ModelTranslation.new(
              :locale => @locale,
              :table_name => record.class.table_name,
              :facet => facet,
              :record_id => record.id,
              :value => record.respond_to?("#{facet}_#{@locale.code}") ? record.send("#{facet}_#{@locale.code}") : nil
            ) {|r| r[:id] = index += 1})
          end
          @records.push(record)
        end
      end
    end
    @page_title = "Model Translations for #{Utility.locale_in_words(@locale.code)}"
  end
  
  def update
    class_name = params[:class_name]
    if models_to_translate.map(&:to_s).include?(class_name)
      klass = class_name.constantize
      if klass.respond_to?(:keep_translations_in_model) && klass.keep_translations_in_model
        if (record = klass.find(params[:record_id])) && params[:facet] && params[:value]
          record.update_attribute("#{params[:facet]}_#{@locale.code}", params[:value])
          render :text => params[:value]
          return
        end
      end
    end
    render :text => "error"
  end
  
  protected
  
end
