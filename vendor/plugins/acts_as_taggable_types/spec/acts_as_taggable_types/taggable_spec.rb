require File.dirname(__FILE__) + '/../spec_helper'

describe "Taggable" do
  before(:each) do
    [TaggableModel, Tag, Tagging, TaggableUser].each(&:delete_all)
    @taggable = TaggableModel.new(:name => "Bob Jones")
  end
  
  it "should be able to create tags" do
    @taggable.skill_list = "ruby, rails, css"
    @taggable.instance_variable_get("@acts_as_taggable_skill_tags").instance_of?(Array).should be_true
    @taggable.skill_list.should == ["ruby", "rails", "css"]
    @taggable.tag_list.should == ["ruby", "rails", "css"]
    @taggable.save
    Tag.find(:all).size.should == 3
  end

  it "should get taggings tagged with stuff and optional context" do
    @taggable = TaggableModel.create(:name => "Taggable")
    @taggable.tag_with ["one", "two", "three"]
    @taggable.skill_list = "ruby, rails, css"
    @taggable.save
    @taggable.should have(3).skills
    @taggable.should have(6).tags
    @taggable.taggings.include?(@taggable.taggings_tagged_with("rails").first).should be_true
    @taggable.taggings_tagged_with("rails", :skills).first.tag.name.should == "rails"
  end
  
  it "should be able to create tags through the tag list directly" do
#    @taggable.tag_list_on(:test).add("hello")
#    @taggable.save    
#    @taggable.reload
#    @taggable.tag_list_on(:test).should == ["hello"]
  end
  
  it "should differentiate between contexts" do
    @taggable.skill_list = "ruby, rails, css"
    @taggable.tag_list = "ruby, bob, charlie"
    @taggable.save
    @taggable.reload
    @taggable.skill_list.include?("ruby").should be_true
    @taggable.skill_list.include?("bob").should be_false
  end
  
  it "should be able to remove tags through list alone" do
    @taggable.skill_list = "ruby, rails, css"
    @taggable.save
    @taggable.reload
    @taggable.should have(3).skills
    @taggable.skill_list.should == ["ruby", "rails", "css"]
    @taggable.skill_list = ["ruby", "rails"]
    @taggable.save
    @taggable.reload
    @taggable.should have(2).skills
  end
  
  it "should be able to find by tag" do
    @taggable.skill_list = "ruby, rails, css"
    @taggable.save
    TaggableModel.find_tagged_with("ruby").first.should == @taggable
  end
  
  it "should be able to find by tag with context" do
    @taggable.skill_list = "ruby, rails, css"
    @taggable.tag_list = "bob, charlie"
    @taggable.save
    TaggableModel.find_tagged_with("ruby").first.should == @taggable
    TaggableModel.find_tagged_with("bob", :on => :skills).first.should_not == @taggable
    TaggableModel.find_tagged_with("bob").include?(@taggable).should be_true
  end
  
  it "should not care about case" do
    bob = TaggableModel.create(:name => "Bob", :tag_list => "ruby")
    frank = TaggableModel.create(:name => "Frank", :tag_list => "Ruby")
    
    Tag.find(:all).size.should == 1
    TaggableModel.find_tagged_with("ruby").should == TaggableModel.find_tagged_with("Ruby")
  end
  
  it "should be able to get tag counts on model as a whole" do
    bob = TaggableModel.create(:name => "Bob", :tag_list => "ruby, rails, css")
    frank = TaggableModel.create(:name => "Frank", :tag_list => "ruby, rails")
    charlie = TaggableModel.create(:name => "Charlie", :skill_list => "ruby")
    TaggableModel.tag_counts.should_not be_empty
    TaggableModel.skill_counts.should_not be_empty
  end
  
  it "should be able to get tag counts on an association" do
    bob = TaggableModel.create(:name => "Bob", :tag_list => "ruby, rails, css")
    frank = TaggableModel.create(:name => "Frank", :tag_list => "ruby, rails")
    charlie = TaggableModel.create(:name => "Charlie", :skill_list => "ruby")
    bob.tag_counts.first.count.should == "3"
    charlie.skill_counts.first.count.should == "1"
  end
  
  it "should be able to do correct taging bookkeeping" do
    lambda {
      lambda {
        bob = TaggableModel.create(:name => "Bob")
        bob.set_tag_list_on(:skills, "reading, diving")
        bob.tag_list_on(:skills).should == ["reading", "diving"]
        bob.save
        TaggableModel.find_tagged_with("reading", :on => :skills).should_not be_empty
      }.should change(Tagging, :count).by(2)
    }.should change(Tag, :count).by(2)
  end
  
  it "should not add duplicate taggings between context and common tags" do
      lambda {
        bob = TaggableModel.create(:name => "Bob", :skill_list => "ruby, rails, css")
        bob.tag_list = ["ruby", "rails"]
        
        bob.skill_list.should == ["ruby", "rails", "css"]
        bob.tag_list.should == ["ruby", "rails", "css"]
        
        bob.save
      }.should change(Tagging, :count).by(5)
  end

  it "should remove taggings on types before save" do
      lambda {
        bob = TaggableModel.create(:name => "Bob", :skill_list => "ruby, rails, css")
        bob.skill_list = "ruby, css"
        bob.skill_list.should == ["ruby", "css"]
        bob.save
      }.should change(Tagging, :count).by(2)
  end

  it "should keep case sensitive tags between instances" do
    bob = TaggableModel.create(:name => "Bob", :skill_list => "ruby, rails")
    dick = TaggableModel.create(:name => "Dick", :skill_list => "Ruby, Rails")
    bob.skill_list.should == ["ruby", "rails"]
    bob.skill.should == "ruby, rails"
    dick.skill_list.should == ["Ruby", "Rails"]
    dick.skill.should == "Ruby, Rails"
  end
  
  describe "Single Table Inheritance" do
    before do
      [TaggableModel, Tag, Tagging, TaggableUser].each(&:delete_all)
      @taggable = TaggableModel.new(:name => "taggable")
      @inherited_same = InheritingTaggableModel.new(:name => "inherited same")
      @inherited_different = AlteredInheritingTaggableModel.new(:name => "inherited different")
    end
    
    it "should be able to save tags for inherited models" do
      @inherited_same.tag_list = "bob, kelso"
      @inherited_same.save
      InheritingTaggableModel.find_tagged_with("bob").first.should == @inherited_same
    end
    
    it "should find STI tagged models on the superclass" do
      @inherited_same.tag_list = "bob, kelso"
      @inherited_same.save
      TaggableModel.find_tagged_with("bob").first.should == @inherited_same
    end
    
    it "should be able to add on contexts only to some subclasses" do
      @inherited_different.part_list = "fork, spoon"
      @inherited_different.save
      InheritingTaggableModel.find_tagged_with("fork", :on => :parts).should be_empty
      AlteredInheritingTaggableModel.find_tagged_with("fork", :on => :parts).first.should == @inherited_different
    end
  end
end