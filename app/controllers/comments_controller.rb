# Handles comments and clarifications in kase or response
class CommentsController < FrontApplicationController
  include FlagsControllerBase
  include PropertyEditor
  include VoteablesControllerBase
  include CommentablesControllerBase
  helper :kases, :flags, :property_editor, :voteables, :tiers, :organizations, :topics, :products, :locations
  
  #--- filters
  before_filter :load_commentable
  before_filter :load_comment, :except => [:new, :create]
#  before_filter :reputation_threshold_required
  
  #--- theme
  choose_theme :which_theme?
  
  #--- actions
  property_action :comment, :message, :partial => 'comments/message', :locals => {:label => false}
  
  def new
    @comment = @commentable.build_comment(@person)
    
    respond_to do |format|
      format.js {
        render :update, :status => 202 do |page|
          page.replace_html new_commentable_comment_dom_id(@commentable), :partial => "comments/new",
            :object => @comment, :locals => {:update => true, :id => new_commentable_comment_dom_id(@commentable)}
        end
      }
      format.html {
        render :nothing => true
      }
    end
  end
  
  def create
    respond_to do |format|
      format.js {
        @comment = @commentable.send(build_method(params), @person, params[:comment] || {})

        if @comment.save
          @comment.activate!

          @partial_name = commentable_partial_name
          render :update do |page|
            page.replace dom_id(@commentable), :partial => @partial_name,
              :object => @commentable, :locals => {:update => true}
          end
        else
          render :update do |page|
            page.replace comment_dom_id(@comment), :partial => "comments/new",
              :object => @comment, :locals => {:display => true}

            page.replace_html dom_class(@commentable.class.base_class, :message),
              form_error_messages_for(:comment, :unique => true, :attr_names => {
            	  :base => '', :message => "Comment".t, :sender_email => "Email".t
            	})

            page << "new Effect.ScrollTo('#{dom_class(@commentable.class.base_class, :message)}', {offset:-12})"
          end
          return
        end
      }
      format.html {
        render :nothing => true
      }
    end
  end
  
  def activate
    if @comment = Comment.find_by_activation_code(params[:id])
      @comment.sender = @person

      if @comment.activate! && @comment.active?
        flash[:notice] = (PUBLISH_SUCCESS.t % {:object => @comment.class.human_name}).to_sentence
        redirect_to member_path([@comment.kase.tier, @comment.kase])
        return
      end
    end
    flash[:error] = (PUBLISH_FAIL.t % {:object => (@comment.class || Comment).human_name}).to_sentence
    redirect_to '/'
  end
  
  protected
  
  def ssl_required?
    false
  end
  
  def ssl_allowed?
    true
  end
  
  def build_method(params={})
    :build_comment
  end
  
  def load_commentable
    if params[:response_id]
      @commentable = @response = Response.find(params[:response_id], :include => {:kase => :tiers})
      @tier = @response.kase.tier if @response && @response.kase
    elsif id = class_param_id(Kase)
      @commentable = @kase = Kase.find_by_permalink(id, :include => :tiers)
      @tier = @kase.tier if @kase
    end
  end
  
  def load_comment
    if params[:id]
      @comment = Comment.find(params[:id])
      @commentable = @comment.commentable
    end
  end

  # determine which theme we should set?
  def which_theme?
    if @commentable && @commentable.is_a?(Response)
      @commentable.accepted? ? :response : :form
    else
      :kase
    end
  end

  def commentable_partial_name
    if @commentable.is_a?(Response)
      'responses/response'
    elsif @commentable.is_a?(Kase)
      'kases/show_kase'
    end
  end

  # overrides from front app and provides threshold action
  def reputation_threshold_action
    :leave_comment
  end
  
  # override from superclass, current user can edit her own kase/response
  def current_user_requires_reputation_threshold?
    !(current_user && current_user.person && @commentable && @commentable.person == current_user.person)
  end

  # dom id for the kase main content and sidebar
  def page_dom_id
    dom_class(Kase, :page)
  end
  helper_method :page_dom_id
  
end
