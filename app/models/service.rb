# Service is derived from product. It has all properties of a product.
class Service < Product

  #--- class methods
  class << self
    
    def kind
      :service
    end
    
  end
  
  #--- instance methods
  
  # returns a string representation for class/instance type
  def kind
    self.class.kind
  end
  
end