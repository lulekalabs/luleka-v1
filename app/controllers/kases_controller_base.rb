# provides controller helpers for SearchesController and LocationsController
module KasesControllerBase
  def self.included(base)
    base.extend(ClassMethods)
  end
  
  module ClassMethods
  end

  protected

  #--- helpers
  
  def kase_class
    raise 'override kase_class in controller'
  end
  
  # used for instantiating a kase, e.g. Kase.new :type => kase_type
  def kase_type
    kase_class.kind if kase_class
  end
  
  # used for querying params, e.g. params[kase_param]
  def kase_param
    kase_type
  end
  
  # checks the params hash for any occurances of a kase "like" id or
  # returns nil if there is none
  # e.g. :kase_id, :problem_id, :idea_id, etc.
  def kase_param_id(klass=kase_class)
    klass.self_and_subclass_param_ids.each {|id| return params[id] if params[id]}
    nil
  end

end