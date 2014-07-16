module ActiveSupport #:nodoc:
  module CoreExtensions #:nodoc:
    module Array #:nodoc:
      module TranslatedConversions

        # override built in to_sentence with first casing first character and adding a period
        # if a sentence termination is not present
        def to_sentence(options={})
          super(options).to_sentence
        end

        def to_sentence_with_or(options={})
          self.to_sentence({
            :two_words_connector => I18n.translate('support.array.two_words_connector_with_or', :locale => options[:locale]),
            :last_word_connector => I18n.translate('support.array.last_word_connector_with_or', :locale => options[:locale])
          })
        end

        def to_sentence_with_and(options={})
          self.to_sentence({
            :words_connector => I18n.translate('support.array.words_connector', :locale => options[:locale]),
            :two_words_connector => I18n.translate('support.array.two_words_connector', :locale => options[:locale]),
            :last_word_connector => I18n.translate('support.array.last_word_connector', :locale => options[:locale])
          })
        end

        def to_sentence_with_comma(options={})
          self.to_sentence({
            :two_words_connector => I18n.translate('support.array.words_connector'),
            :last_word_connector => I18n.translate('support.array.words_connector')
          })
        end

        # returns a string where each array element is converted to a full sentence,
        # with a full stop at end.
        #
        # e.g.
        #
        #   ['veni', 'vidi', 'vici.']  ->  Veni. Vidi. Vici.
        #
        def to_sentences(options={})
          self.reject {|a| a.blank?}.map(&:strip).map(&:strip_period).map(&:firstcase).to_sentence({
            :words_connector => ". ",
            :two_words_connector => ". ",
            :last_word_connector => ". "
          })
        end

      end
      
    end
  end
end

class Array
  include ActiveSupport::CoreExtensions::Array::TranslatedConversions
end

