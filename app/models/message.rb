# Message is the superclass of invitation and request
class Message < ActiveRecord::Base
  
  #--- associations
  belongs_to :sender, :class_name => 'Person', :foreign_key => :sender_id
  belongs_to :receiver, :class_name => 'Person', :foreign_key => :receiver_id
  belongs_to :voucher
  
  #--- class methods
  class << self
    
    def kind
      self.name.underscore.to_sym
    end
    
  end
  
  #--- instance methods
  
  def kind
    self.class.kind
  end
  
  def validate
  end
  
end
