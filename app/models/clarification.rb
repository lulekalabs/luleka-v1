# Like comments for kases and responses that restrict access on who can 
# request a clarification and who is allowed to reply to one.
class Clarification < Comment
  #--- accessors
  attr_accessor :kind
  
  #--- associations
  belongs_to :clarifiable, :foreign_key => :commentable_id, :foreign_type => :commentable_type, :polymorphic => true
    
  has_many :clarifications, :foreign_key => :parent_id, :dependent => :destroy
  belongs_to :clarification, :foreign_key => :parent_id

  #--- class methods
  
  class << self
    
    # type casts to the class specified in :type parameter
    #
    # E.g.
    #
    #   d = Clarification.new(:type => :clarification_request)
    #   d.kind == :idea  # -> true
    #
    def new_with_cast(*a, &b)  
      if (h = a.first).is_a? Hash and (type = h[:type] || h['type']) and 
        (k = type.class == Class ? type : (type.class == Symbol ? klass(type): type.constantize)) != self
        raise "type not descendent of #{name}" unless k < self  # klass should be a descendant of us  
        return k.new(*a, &b)  
      end  
      new_without_cast(*a, &b)  
    end  
    alias_method_chain :new, :cast

    def klass(a_kind=nil)
      [ClarificationRequest, ClarificationResponse].each do |subclass|
        return subclass if subclass.kind == a_kind
      end
      Clarification
    end

    def kind
      # returns nothing, overridden in subclass
    end
    
  end

  #--- instance methods
  
  def kind
    @kind || self.class.kind
  end
  
  # overrides super
  def build_reply(options={})
    self.clarifications.build(reply_options(options)) if repliable?
  end

  # overrides super
  def create_reply(options={})
    if repliable?
      reply = self.clarifications.create(reply_options(options))
      reply.activate! if reply.valid?
      reply
    end
  end
  
  # returns the kase instance, no matter if this clarification
  # is attached to a response or kase
  def kase
    if self.clarifiable.is_a?(Kase)
      self.clarifiable
    elsif self.clarifiable.is_a?(Response)
      self.clarifiable.kase
    end
  end

  # is this clarification a request?
  def request?
    false
  end

  # is this clarification a response?
  def response?
    false
  end

  # override from comment
  def repliable?(a_person=nil)
    false
  end
  
  # returns true if 
  def replied?
    self.repliable? && self.clarifications.size > 0
  end

  protected

  # override from comment
  def reply_options(options={})
    response_kind = if self.kind == :clarification_request
      :clarification_response
    else
      :clarification_request
    end
    options.merge({:type => response_kind, :clarifiable => self.clarifiable,
      :sender => self.receiver, :receiver => self.sender, :parent => self})
  end
  
  # Sends request email depending on the role, e.g. :sender, :receiver
  def send_request_to(role)
    ClarificationMailer.deliver_request_clarification(self, role)
  end

  # Sends response email depending on role, e.g. :sender, :receiver
  def send_response_to(role)
    ClarificationMailer.deliver_response_clarification(self, role)
  end

  # overrides super
  # handles mailer notifications and is called in callback (defined in super)
  def send_notifications
    if self.request?
      send_request_to(:sender) if self.sender && self.sender.notify_on_clarification_request
      send_request_to(:receiver) if self.receiver && self.receiver.notify_on_clarification_request
    elsif self.response?
      send_response_to(:sender) if self.sender && self.sender.notify_on_clarification_response
      send_response_to(:receiver) if self.receiver && self.receiver.notify_on_clarification_response
    end
  end

end
