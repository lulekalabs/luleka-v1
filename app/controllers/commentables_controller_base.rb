# provides controller helpers for KasesController and ResponsesController
# for resources, etc.
module CommentablesControllerBase
  def self.included(base)
    base.extend(ClassMethods)
    base.send :helper_method, :commentable_comments_path, 
      :hash_for_commentable_comments_path, :commentable_comment_path, :hash_for_commentable_comment_path,
      :comment_dom_id, :commentable_dom_class, :commentable_dom_id, :new_commentable_comment_dom_id
  end
  
  module ClassMethods
  end

  protected

  # e.g. kase_comments_path(@kase)
  def commentable_comments_path(commentable)
    if commentable.is_a?(Kase)
      if @tier || params[:tier_id]
        collection_url([:tier, commentable, :comments], nil, {:tier_id => @tier || params[:tier_id]})
      else
        kase_comments_path(:kase_id => commentable)
      end
    elsif commentable.is_a?(Response)
      if @tier || params[:tier_id]
        collection_url([:tier, commentable.kase, commentable, :comments], nil, {:tier_id => @tier || params[:tier_id]})
      else
        kase_response_comments_path(:kase_id => commentable.kase, :response_id => commentable)
      end
    end
  end

  def hash_for_commentable_comments_path(commentable)
    if commentable.is_a?(Kase)
      if @tier || params[:tier_id]
        hash_for_collection_path([:tier, commentable, :comments], nil, {:tier_id => @tier || params[:tier_id]})
      else
        hash_for_kase_comments_path(:kase_id => commentable)
      end
    elsif commentable.is_a?(Response)
      if @tier || params[:tier_id]
        hash_for_collection_path([:tier, commentable.kase, commentable, :comments], nil, {:tier_id => @tier || params[:tier_id]})
      else
        hash_for_kase_response_comments_path(:kase_id => commentable.kase, :response_id => commentable)
      end
    end
  end

  # e.g. kase_comment_path(@kase, @comment)
  def commentable_comment_path(commentable, comment)
    if commentable.is_a?(Kase)
      if @tier || params[:tier_id]
        member_url([:tier, commentable, comment], nil, {:tier_id => @tier || params[:tier_id]})
      else
        kase_comment_path(:kase_id => commentable, :id => comment)
      end
    elsif commentable.is_a?(Response)
      if @tier || params[:tier_id]
        member_url([:tier, commentable.kase, commentable, comment], nil, {:tier_id => @tier || params[:tier_id]})
      else
        kase_response_comment_path(:kase_id => commentable.kase, :response_id => commentable, :id => comment)
      end
    end
  end

  # e.g. kase_comment_path(@kase, @comment)
  def hash_for_commentable_comment_path(commentable, comment)
    if commentable.is_a?(Kase)
      if @tier || params[:tier_id]
        hash_for_member_path([:tier, commentable, comment], nil, {:tier_id => @tier || params[:tier_id]})
      else
        hash_for_kase_comment_path(:kase_id => commentable, :id => comment)
      end
    elsif commentable.is_a?(Response)
      if @tier || params[:tier_id]
        hash_for_member_path([:tier, commentable.kase, commentable, comment], nil, {:tier_id => @tier || params[:tier_id]})
      else
        hash_for_kase_response_comment_path(:kase_id => commentable.kase, :response_id => commentable, :id => comment)
      end
    end
  end
  
  # e.g. comment_dom_id(@comment)  ->  "<commentable id>_<comment id>"
  def comment_dom_id(comment_object, prefix=nil)
    "#{dom_id(comment_object.commentable, prefix)}_#{dom_id(comment_object, prefix)}"
  end

  # e.g. commentable_comment_dom_id(@kase, @comment)  ->  "<commentable id>_<comment id>"
  def new_commentable_comment_dom_id(commentable_object, prefix=nil)
    "#{dom_id(commentable_object, prefix)}_new_comment"
  end

  # e.g. commentable_dom_class(Kase, Comment)
  def commentable_dom_class(commentable_object_or_class, prefix=nil)
    "commentable_#{dom_class(commentable_object_or_class, prefix)}"
  end

  # e.g. commentable_dom_id(@kase, :comment)
  def commentable_dom_id(commentable_object, prefix=nil)
    "commentable_#{dom_id(commentable_object, prefix)}"
  end

end
