# Subclass of kases controller
class IdeasController < KasesController

  protected
  
  def kase_class
    Idea
  end

  # overidden from kases_controller
  def action_synonym(name=self.action_name)
    case "#{name}"
    when /considered/ then "under consideration".t
    when /closed/ then "not planned".t
    when /assigned/ then "assigned".t
    when /open/ then "open".t
    when /active/, /recent/ then "recently active".t
    when /popular/ then "popular".t
    when /solved/ then "completed".t
    when /new/, /create/ then "share new".t
    else super
    end
  end

end
