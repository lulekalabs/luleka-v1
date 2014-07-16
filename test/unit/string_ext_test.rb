require File.dirname(__FILE__) + '/../test_helper'

class StringExtTest < ActiveSupport::TestCase

  def test_should_shortcase
    assert_equal "hello_people", "Hello People!!!".shortcase 
  end
  
  def test_should_firstcase
    assert_equal 'A fox', 'a fox'.firstcase
    assert_equal 'A Fox', 'a Fox'.firstcase
    assert_equal 'A', 'a'.firstcase
    assert_equal '', ''.firstcase
    assert_equal ' ', ' '.firstcase
  end

  def test_should_strip_period
    assert_equal "what the hell", "what the hell.".strip_period
    assert_equal "what the hell", "what the hell".strip_period
    assert_equal "", "".strip_period
    assert_equal "", ".".strip_period
    assert_equal "a", "a".strip_period
  end
  
  def test_to_sentence
    assert_equal "The fox jumps over the Computer.", 'the fox jumps over the Computer'.to_sentence
    assert_equal "The fox jumps over the Computer.", 'the fox jumps over the Computer.'.to_sentence
    assert_equal "The fox jumps over the Computer?", 'the fox jumps over the Computer?'.to_sentence
    assert_equal "The fox jumps over the Computer!", 'the fox jumps over the Computer!'.to_sentence
  end
  
end
