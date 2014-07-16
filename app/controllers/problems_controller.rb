# Subclass of kases controller
class ProblemsController < KasesController

  protected
  
  def kase_class
    Problem
  end

  # overidden from kases_controller
  def action_synonym(name=self.action_name)
    case "#{name}"
    when /open_rewarded/ then "offers reward".t
    when /open/ then "being worked on".t
    when /active/, /recent/ then "recently active".t
    when /popular/ then "common".t
    when /solved/ then "completed".t
    when /new/, /create/ then "report new".t
    else super(name)
    end
  end
  
end
