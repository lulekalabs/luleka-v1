# Products controller is handling all products and service related
# resources. It is derived from TopicsController
class ProductsController < TopicsController
  #--- actions

  protected

  def tier_class
    @tier_class || Organization
  end
  
  def topic_class
    Product
  end

  # override from topics_controller
  def action_synonym(name=self.action_name)
    case "#{name}"
    when /new/, /create/ then "start new product".t
    else super(name)
    end
  end
  
end
