module InlineAuthenticationBase
  def self.included(model)
    model.extend ClassMethods
    model.send :attr_accessor, :authentication_type
  end
  
  module ClassMethods
  end

  #--- instance methods
  
  def authenticate_with_signin?
    @authentication_type ? !!(@authentication_type.to_s =~ /signin/) : false
  end

  def authenticate_with_signup?
    @authentication_type ? !!(@authentication_type.to_s =~ /signup/) : false
  end
  
end
