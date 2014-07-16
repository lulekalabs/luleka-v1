# This controller inherits from prodcuts_controller, just as
# Service inherits from Product model. 
class ServicesController < ProductsController
  
  protected

  def topic_class
    Service
  end
  
end
