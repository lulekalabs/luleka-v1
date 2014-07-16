require File.dirname(__FILE__) + '/../test_helper'

class PageTest < ActiveSupport::TestCase
  fixtures :pages
  
  def test_should_build
    assert page = build_page
    assert page.valid?, "should be valid"
  end

  def test_should_create
    assert_difference Page, :count do 
      assert page = create_page
    end
  end
  
  def test_should_validate
    assert page = build_page(:title => nil, :permalink => nil)
    assert !page.valid?, 'should not validate'
    assert page.errors.on(:title), 'title should be invalid'
    assert page.errors.on(:permalink), 'uri should be invalid'
  end
  
  def test_should_find_by_permalink
    assert_equal pages(:about), Page.find_by_permalink('about')
  end

  def test_should_find_by_permalink_with_german
    I18n.switch_locale :de do
      assert_equal pages(:about), Page.find_by_permalink('ueber')
    end
  end

  def test_should_get_html_with_markdown
    page = create_page(:markdown => true, :content => "*wow*")
    assert_equal "<p><em>wow</em></p>", page.html
  end

  def test_should_get_html_with_textilize
    page = create_page(:markdown => true, :content => "#header")
    assert_equal "<h1>header</h1>", page.html
  end

  def test_should_get_html_straight
    page = create_page(:content => "<html>html<html>")
    assert_equal "<html>html<html>", page.html
  end

  protected
  
  def valid_page_attributes(options={})
    {
      :title => 'About',
      :permalink => '/about',
      :content => "<div>We are the champions!</div>",
      :layout => "standard",
      :textile => false,
      :markdown => false
    }.merge(options)
  end

  def build_page(options={})
    Page.new(valid_page_attributes(options))
  end

  def create_page(options={})
    Page.create(valid_page_attributes(options))
  end

end
