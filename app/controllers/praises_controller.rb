# Subclass of kases controller
class PraisesController < KasesController

  protected
  
  def kase_class
    Praise
  end

  # overidden from kases_controller
  def action_synonym(name=self.action_name)
    case "#{name}"
    when /index/, /show/ then "overview".t
    when /new/, /create/ then "give new".t
    else super(name)
    end
  end

end
