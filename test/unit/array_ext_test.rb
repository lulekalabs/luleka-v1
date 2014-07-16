require File.dirname(__FILE__) + '/../test_helper'

class ArrayExtTest < ActiveSupport::TestCase

  def setup
    I18n.locale = :"en-US"
  end

  def test_to_sentence_with_exact_spelling
    assert_equal "The Fox and the Hunter.", ['The Fox', 'the Hunter'].to_sentence
    assert_equal "The Fox, the Chicken, and the Hunter.", ['The Fox', 'the Chicken', 'the Hunter'].to_sentence
  end

  def test_to_sentence_without_exact_spelling
    assert_equal "The Fox.", ['the Fox'].to_sentence
    assert_equal "The Fox and the Hunter.", ['the Fox', 'the Hunter.'].to_sentence
    assert_equal "The Fox and the Hunter.", ['the Fox', 'the Hunter'].to_sentence
    assert_equal "The Fox and the Hunter.", ['the Fox', 'the Hunter'].to_sentence
    assert_equal "The Fox, the Chicken, and the Hunter.", ['The Fox', 'the Chicken', 'the Hunter'].to_sentence
    assert_equal "The Fox, the Chicken, and the Hunter.", ['the Fox', 'the Chicken', 'the Hunter'].to_sentence
    assert_equal "The Fox, The Chicken, and The Hunter.", ['the Fox', 'The Chicken', 'The Hunter'].to_sentence
  end
  
  def test_to_sentences
    assert_equal "The Fox.", ['the Fox'].to_sentences
    assert_equal "The Fox. The Hunter.", ['the Fox', 'the Hunter.'].to_sentences
    assert_equal "The Fox. The Hunter.", ['the Fox.', 'The Hunter.'].to_sentences
    assert_equal "The Fox. The Chicken. The Hunter.", ['the Fox', 'the Chicken', 'the Hunter'].to_sentences
  end

  def test_to_sentence_with_or_with_exact_spelling
    assert_equal "The Fox or the Hunter.", ['The Fox', 'the Hunter.'].to_sentence_with_or
    assert_equal "The Fox, the Chicken, or the Hunter.", ['The Fox', 'the Chicken', 'the Hunter.'].to_sentence_with_or
  end

  def test_to_sentence_with_and_with_exact_spelling
    assert_equal "The Fox and the Hunter.", ['The Fox', 'the Hunter.'].to_sentence_with_and
    assert_equal "The Fox, the Chicken, and the Hunter.", ['The Fox', 'the Chicken', 'the Hunter.'].to_sentence_with_and
  end

  
end
