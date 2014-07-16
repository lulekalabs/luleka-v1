# Adds a way to kase as to distinguish between open and closed discussions, later on
# possibly other discussion types. Open discussions allow comments by all registered 
# users. Closed ones are open to clarifications (a closed form of commenting) for 
# members that were picked through audience type.
class DiscussionType < ActiveRecord::Base
  #--- associations
  has_many :kases
  
  #--- mixins
  self.keep_translations_in_model = true
  translates :name, :base_as_default => true
  
  #--- class variables
  @@open = nil
  @@closed = nil

  #--- validations
  validates_presence_of :kind, :name # :message => translation not important!

  #--- class methods
  class << self
    
    def open_id
      open ? open.id : nil
    end

    def open
      @@open || @@open = find_by_kind('open')
    end

    def closed_id
      closed ? closed.id : nil
    end

    def closed
      @@closed || @@closed = find_by_kind('closed')
    end
    
  end
  
  #--- instant methods
  
  def kind
    self[:kind].to_sym if self[:kind]
  end

  def kind=(a_kind)
    self[:kind] = a_kind.to_s if a_kind
  end
  
end
