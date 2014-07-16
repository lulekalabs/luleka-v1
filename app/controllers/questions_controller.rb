# Subclass of kases controller
class QuestionsController < KasesController

  protected
  
  def kase_class
    Question
  end

  # overidden from kases_controller
  def action_synonym(name=self.action_name)
    case "#{name}"
    when /new/, /create/ then "ask new".t
    when /open_rewarded/ then "offers reward".t
    when /open/ then "needs answer".t
    when /active/, /recent/ then "recently active".t
    when /popular/ then "frequently asked".t
    when /solved/ then "answered".t
    else super
    end
  end
  
end
