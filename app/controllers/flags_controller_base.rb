# provides controller helpers for TiersController and TopicsController
module FlagsControllerBase

  def self.included(base)
    base.extend(ClassMethods)
    base.send :helper_method, :flag_path, :new_flag_path
  end
  
  module ClassMethods
  end

  protected

  # overloads flag_path
  # assembles a path with nested associations
  #
  # e.g.
  #
  #   /kases/:kase_id/flag
  #   /kases/:kase_id/responses/:response_id/flag
  #   /tiers/:tier_id/topics/:topic_id/kases/:id
  #
  def flag_path(flag)
    selector = []
    selector << @tier if @tier
    selector << @kase if @kase
    selector << @response if @response
    selector << @comment if @comment
    selector << flag
    flag.new_record? ? collection_url(selector) : member_url(selector)
  end

  # overridses default new_flag_path
  # adds nesting for kase, response and comment if necessary
  # if the object is passed, the path is derived from the object
  # otherwise we check for instance methods and derive it from there
  def new_flag_path(object=nil)
    selector = [@tier]
    if object
      if object.is_a?(Comment)
        if object.commentable.is_a?(Response)
          selector << object.commentable.kase
          selector << object.commentable
          selector << object
        elsif object.commentable.is_a?(Kase)
          selector << object.commentable
          selector << object
        end
      elsif object.is_a?(Response)
        # /kase/:kase_id/responses/:response_id/flags/new
        selector << object.kase
        selector << object
      elsif object.is_a?(Kase)
        # /kase/:kase_id/flags/new
        selector << object
      elsif object.is_a?(Person)
        # /people/:person_id/flags/new
        selector << object
      end
    end
    selector << :flag
    collection_url(selector.compact, :new)
  end

end