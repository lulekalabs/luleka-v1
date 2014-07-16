require File.dirname(__FILE__) + '/../test_helper'

class BadWordTest < ActiveSupport::TestCase
  fixtures :bad_words

  def test_nothing_to_sanitize
    assert_equal "wonderful", BadWord.sanitize_tag("wonderful")
    assert_equal "wonderful people", BadWord.sanitize_text("wonderful people")
  end

  def test_nothing_to_sanitize_in_german
    I18n.switch_locale :"de-DE" do
      assert_equal "schön", BadWord.sanitize_tag("schön")
      assert_equal "schöne Menschen", BadWord.sanitize_text("schöne Menschen")
    end
  end

  def test_sanitize_bad_words
    assert_equal "", BadWord.sanitize_tag("what")
    assert_equal "", BadWord.sanitize_tag("the")
    assert_equal "paint", BadWord.sanitize_tag("fuck")

    assert_equal "what the paint", BadWord.sanitize_text("what the fuck")
    assert_equal "what the paint", BadWord.sanitize_text("what the FucK")
    assert_equal "what the paint", BadWord.sanitize_text("what the FuuuuuuuuuuuuuuuuucK")
  end

  def test_sanitize_bad_words_in_german
    I18n.switch_locale :"de-DE" do
      assert_equal "", BadWord.sanitize_tag("das")
      assert_equal "", BadWord.sanitize_tag("ist")
      assert_equal "schokolade", BadWord.sanitize_tag("scheisse")
      assert_equal "schokolade", BadWord.sanitize_tag("Scheisse")
      assert_equal "schokolade", BadWord.sanitize_tag("Scheiße")
      assert_equal "schokolade", BadWord.sanitize_tag("Scheissssssse")

      assert_equal "das ist schokolade", BadWord.sanitize_text("das ist Scheiße")
    end
  end

  
end
