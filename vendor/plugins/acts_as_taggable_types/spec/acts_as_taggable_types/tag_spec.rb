require File.dirname(__FILE__) + '/../spec_helper'

describe Tag do
  before(:each) do
    @tag = Tag.new
    @user = TaggableModel.create(:name => "Pablo")  
  end
  
  it "should require a name" do
    @tag.should have(1).errors_on(:name)
    @tag.name = "something"
    @tag.should have(0).errors_on(:name)    
  end
  
  it "should equal a tag with the same name" do
    @tag.name = "awesome"
    new_tag = Tag.new(:name => "awesome")
    new_tag.should == @tag
  end
  
  it "should return its name when to_s is called" do
    @tag.name = "cool"
    @tag.to_s.should == "cool"
  end
  
  it "should parse string" do
    Tag.parse("dog, cat").should == ["dog", "cat"]
    Tag.parse("'coca cola', lime, juice").should == ["coca cola", "lime", "juice"]
    Tag.parse("'stop!', <javascript>, print;, C++, me@too, $10").should == ["stop!", "javascript", "print", "C++", "metoo", "10"]
  end

  it "should parse params string" do
    Tag.parse_param("dog+cat+frog").should == ["dog", "cat", "frog"]
    Tag.parse_param("%27Stop%21%27+said+Fred").should == ["Stop!", "said", "Fred"]
  end
  
  it "should tokenize" do
    Tag.tokenize(["cat", "dog"]).should == [Tag.new(:name => "cat"), Tag.new(:name => "dog")]
    Tag.tokenize("cat, dog").should == [Tag.new(:name => "cat"), Tag.new(:name => "dog")]
  end

  it "should compile" do
    Tag.compile(["cat", "dog"], :delimiter => " + ").should == "cat + dog"
    Tag.compile([Tag.new(:name => "cat"), Tag.new(:name => "dog")]).should == "cat, dog"
  end
  
end