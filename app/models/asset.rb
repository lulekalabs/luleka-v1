# Hiding files from public access:
#
#  # inside ontroller
#  def get_file
#     # user has permission?
#     
#     @asset = Asset.find(params[:id]) 
#     send_file( @asset.file, { :disposition => :inline, :type => 'image/jpeg' } ) 
#  end
#
#  # inside views use
#  <img class="photo" src="/..controller../get_file/<%= @user.id %>" alt="<%= @user.name %>
#  
#  
#  asset Types as in self.kind:
#  
#  :file   ->   is a file
#  :url    ->   is a URL
#  
#  
class Asset < ActiveRecord::Base
  #--- associations
  belongs_to :person
  belongs_to :assetable, :polymorphic => true

  #--- mixins
  acts_as_taggable :filter_class => 'BadWord'
  acts_as_tree :order => 'name', :counter_cache => true
  acts_as_authorizable

  #--- validations
  validates_presence_of :person
  validates_presence_of :assetable

  #--- class methods
  class << self

    # type casts to the class specified in :type parameter
    #
    # E.g.
    #
    #   d = Asset.new(:type => :file)
    #   d.kind == :file # -> true, because it is a FileAsset
    #
    def new_with_cast(*a, &b)  
      if (h = a.first).is_a? Hash and (type = h[:type] || h['type']) and 
        (k = type.class == Class ? type : (type.class == Symbol ? klass(type): type.constantize)) != self
        raise "type not descendent of Asset" unless k < self  # klass should be a descendant of us  
        return k.new(*a, &b)  
      end  
      new_without_cast(*a, &b)  
    end  
    alias_method_chain :new, :cast

    # returns class by kind, e.g. :company returns Company
    def klass(a_kind=nil)
      [FileAsset].each do |subclass|
        return subclass if subclass.kind == a_kind
      end
      Asset
    end

    def kind
      :asset
    end

  end

  #--- callbacks
  before_validation :assign_person_from_assetable
  
  def assign_person_from_assetable
    self.person = self.assetable.person if !self.person && self.assetable && self.assetable.respond_to?(:person)
  end

  #--- instance methods

  # returns asset kind, e.g. :asset, :file, :url etc.
  def kind
    self.class.kind
  end
  
  # override in sublcass
  def empty?
    true
  end
  alias_method :blank?, :empty?
  
  # Checks if this user is accepted
  # If no user is provided or user is nil, we still
  # check if asset is public (everyone)
  def accepts_user?(user=nil)
    if user.nil?
      return accepts_everyone?
    else
      return true if accepts_everyone?
      if self.assetable.is_a?( Issue )
        issue = self.assetable
        if accepts_respondents?
          # TODO: add responding to Issue
          # return true if issue.responding.user.id==user.id
          if response=issue.reponse
            return true if response.person.user.id==user.id
          end
        end
        if accepts_followers?
          return true if issue.is_followed_by?( user.person )
        end
      end
      if accepts_friends?
        return true if self.person.is_friends_with?( user.person )
      end
      if accepts_none?
        return true if (user.person==self.person)
      end
    end
    false
  end

  # A respondent is a usesr (expert) that is going to answer
  # the case. During the course of researching and formulating
  # the answer, he will recieve a privilege to view the asset.
  def accepts_respondents?
    if accepted_roles.find_by_name 'respondent'
      return true
    end
    false
  end

  # Set this asset to accept respondent with the default person's
  # user or if supplied by another user. A respondent is a user
  # who is in the process of answering or answered an issue (case)
  def accepts_respondents(user=nil)
    if user.nil?
      raise "No asset author assigned.".t if self.person.nil?
      raise "No user for asset author.".t if self.person.user.nil?
      user = person.user
    end
    accepts_role 'respondent', user
  end
  alias_method :accepts_respondents!, :accepts_respondents

  # Same as accepts_respondents just removes respondent right
  def accepts_no_respondents(user=nil)
    if user.nil?
      raise "No asset author assigned.".t if self.person.nil?
      raise "No user for asset author.".t if self.person.user.nil?
      user = person.user
    end
    accepts_no_role 'respondent', user
  end
  alias_method :accepts_no_respondents!, :accepts_no_respondents

  # Do all the person's friends get access to this asset?
  def accepts_friends?
    if accepted_roles.find_by_name 'friend'
      return true
    end
    false
  end

  # Accept all friends (contacts) of Asset author
  def accepts_friends
    user=nil
    if user.nil?
      raise "No asset author assigned.".t if person.nil?
      raise "No user for asset author.".t if person.user.nil?
      user = person.user
    end
    accepts_role 'friend', user
  end
  alias_method :accepts_friends!, :accepts_friends

  # Accept all friends (contacts) of Asset author
  def accepts_no_friends
    user=nil
    if user.nil?
      raise "No asset author assigned.".t if person.nil?
      raise "No user for asset author.".t if person.user.nil?
      user = person.user
    end
    accepts_no_role 'friend', user
  end
  alias_method :accepts_no_friends!, :accepts_no_friends

  # Followers are people who are participating on an issue (case)
  def accepts_followers?
    if accepted_roles.find_by_name 'follower'
      return true
    end
    false
  end
  
  # Followers is an implementation of the idea of participants
  def accepts_followers(user=nil)
    if user.nil?
      raise "No asset author assigned.".t if person.nil?
      raise "No user for asset author.".t if person.user.nil?
      user = person.user
    end
    accepts_role 'follower', user
  end
  alias_method :accepts_followers!, :accepts_followers

  # Followers is an implementation of the idea of participants
  def accepts_no_followers(user=nil)
    if user.nil?
      raise "No asset author assigned.".t if person.nil?
      raise "No user for asset author.".t if person.user.nil?
      user = person.user
    end
    accepts_no_role 'follower', user
  end
  alias_method :accepts_no_followers!, :accepts_no_followers

  # Is assets accessible to everyone?
  def accepts_everyone?
    if accepted_roles.find_by_name 'everyone'
      return true
    end
    false
  end

  # Makes asset public to everyone
  def accepts_everyone(user=nil)
    if user.nil?
      raise "No asset author assigned.".t if person.nil?
      raise "No user for asset author.".t if person.user.nil?
      user = person.user
    end
    accepts_role 'everyone', user
  end
  alias_method :accepts_everyone!, :accepts_everyone

  # Makes asset public to everyone
  def accepts_not_everyone(user=nil)
    if user.nil?
      raise "No asset author assigned.".t if person.nil?
      raise "No user for asset author.".t if person.user.nil?
      user = person.user
    end
    accepts_no_role 'everyone', user
  end
  alias_method :accepts_not_everyone!, :accepts_not_everyone

  # Entirely private
  def accepts_none?
    if accepted_roles.empty?
      return true
    end
    false
  end
  alias_method :accepts_nobody?, :accepts_none?
  alias_method :accepts_nobody?, :accepts_none?

  
  def accepts_none
    accepted_roles.delete_all
  end
  alias_method :accepts_none!, :accepts_none
  alias_method :accepts_nobody, :accepts_none
  alias_method :accepts_nobody!, :accepts_none
  
  def privacy
    return 'public' if self.accepts_everyone?
    result = "private"
    result << ' ' + "respondents" if accepts_respondents?
    result << ' ' + "friends" if accepts_friends?
    result << ' ' + "followers" if accepts_followers?
    return result
  end
  
  def privacy=(setting)
    case setting
    when /public/
      self.accepts_everyone!
    when /private/
      self.accepts_not_everyone!
    end
  end
  
  # returns "1" or "0"
  def private_to_respondents
    accepts_respondents? ? "1" : "0"
  end
  
  # set "1" for true everything else for false
  def private_to_respondents=(setting)
    if setting.index(/1/)
      accepts_respondents! 
    else
      accepts_no_respondents! 
    end
  end
  
  def private_to_friends
    accepts_friends? ? "1" : "0"
  end

  def private_to_friends=(setting)
    if setting.index(/1/)
      accepts_friends!
    else
      accepts_no_friends!
    end
  end

  def private_to_followers
    accepts_followers? ? "1" : "0"
  end

  def private_to_followers=(setting)
    if setting.index(/1/)
      accepts_followers!
    else
      accepts_no_followers!
    end
  end

end