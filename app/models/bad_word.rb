class BadWord < ActiveRecord::Base
  # Globalize
  self.keep_translations_in_model = true
  translates :good, :bad, :base_as_default => true

  cattr_reader :mapping_en
  cattr_reader :mapping_de
  
  #--- Class Methods
  
  # Load the bad words list into memory
  def self.memorize
    begin
      BadWord.content_columns.collect {|k, v| k.name if k.name.index(/bad/) }.compact.each do |column|
        if 1==column.split('_').size
          # Base Language - English
          eval "@@mapping_en = {}"
          eval "cattr_reader :mapping_en"
          BadWord.find(:all, :conditions => [ "#{column} IS NOT NULL" ]).each do |row|
            class_variable_get( "@@mapping_en".to_sym ).merge!( Regexp.new( row[:bad], Regexp::IGNORECASE ) => row[:good] )  
          end
        else
          # Country
          language=column.split('_')[1].downcase
          eval "@@mapping_#{language} = {}"
          eval "cattr_reader :mapping_#{language}"
          BadWord.find(:all, :conditions => [ "#{column} IS NOT NULL" ]).each do |row|
            class_variable_get( "@@mapping_#{language}".to_sym ).merge!( Regexp.new( row[ "bad_#{language}" ], Regexp::IGNORECASE ) => row[ "good_#{language}" ] )
          end
        end
      end
    rescue
      return false
    end
    true
  end

  # Returns the bad - good word mapping for the default language
  # or if defined in options by :language_code
  def self.mapping(options = {})
    defaults = {:language_code => Utility.language_code || 'en'}
    options = defaults.merge(options).symbolize_keys

    unless mapping = class_variable_get( "@@mapping_#{options[:language_code]}".to_sym )
      if memorize
        mapping = class_variable_get( "@@mapping_#{options[:language_code]}".to_sym )
      else
        mapping = {}
      end
    end
    mapping
  rescue
    return {}
  end
  
  # returns a collection of bad word regular expressions for the default language or the language
  # given as :language_code
  def self.collect(options={})
    result = []
    mapping.each {|k, v| result << k}
    result
  end

  def self.sanitize_tag(a_tag, options={})
    defaults = {:language_code => Utility.language_code || 'en'}
    options = defaults.merge(options).symbolize_keys
    
    a_tag = a_tag.dup
    mapping(options).select {|k,v| k =~ a_tag}.each do |item|
      pos = a_tag.index(item.first)
      a_tag.gsub!(item.first, String(item.last))
      a_tag[pos] = '' if pos > 0 && '  ' == a_tag[pos-1, 2]
    end
    a_tag.strip
  end

  def self.sanitize_text(a_text, options={})
    defaults = {:language_code => Utility.language_code || 'en'}
    options = defaults.merge(options).symbolize_keys
    
    a_text = a_text.dup
    mapping(options).select { |k,v| k=~a_text }.each do |item|
      pos=a_text.index(item.first)
      a_text.gsub!(item.first, String(item.last)) unless item.last.nil?
      a_text[pos]='' if pos>0 && '  '==a_text[pos-1, 2]
    end
    a_text
  end

    
end
