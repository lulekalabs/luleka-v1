# This controller handles the 'flag as inappropriate' functionality
class FlagsController < FrontApplicationController
  include TiersControllerBase
  include CommentablesControllerBase
  include FlagsControllerBase
  
  #--- layout
  layout :choose_layout
  
  #--- filters
  before_filter :load_kase
  before_filter :load_response
  before_filter :load_comment
  before_filter :load_profile
  before_filter :check_reputation_threshold
  
  #--- actions

  def new
    @flag = build_with({})
    render :template => 'flags/new', :locals => {:modal => request.xhr?}
  end

  def create
    @flag = build_with(params[:flag])
    respond_to do |format|
      format.js {
        if @flag.save
          render :update do |page|
            page << close_modal_javascript
          end
          return
        else
          render :update do |page|
            page.replace dom_id(@flag), render(:file => 'flags/new.html.erb')
          end
          return
        end
      }
      format.html {
        if @flag.save
          flash[:notice] = "Content has been flagged!".t
          redirect_to @flag.flaggable
          return
        end
        render :template => 'flags/new'
        return
      }
    end
  end
  
  protected

  # used when routes /organizations/xxx/kases... in before_filter is loaded
  def load_tier
    if id = tier_param_id
      @tier = Tier.find_by_permalink_and_region_and_active(id)
      @tier_class = @tier.class if @tier
    end
  end

  # used when routes /organizations/luleka/products/xxx/kases... in before_filter is loaded
  def load_topic
    if @tier && id = topic_param_id
      @topic = @tier.topics.find_by_permalink_and_region_and_active(id)
      @topic_class = @topic.class if @topic
    end
  end
  
  def load_kase
    if id = class_param_id(Kase)
      @flaggable = @kase = Kase.find_by_permalink(id)
      @tier = @kase.tier if @kase
      @topics = @kase.topics if @kase
    end
  end

  def load_response
    if id = class_param_id(Response)
      @flaggable = @response = @kase.responses.find(id)
    end
  end
  
  # /kases/:kase_id/comments/<:id>
  # /kases/:kase_id/responses/:response_id/comments/<:id>
  def load_comment
    if id = class_param_id(Comment)
      if @kase && @response
        @flaggable = @comment = @response.comments.find(id)
      elsif @kase
        @flaggable = @comment = @kase.comments.find(id)
      end
    end
  end

  # check if a profile is being flagged?
  def load_profile
    if id = params[:person_id]
      @flaggable = @person = Person.finder(id)
    end
  end
  
  # build flaggable
  def build_with(options={})
    if options.empty?
      current_user.flags.new(:flaggable => @flaggable)
    else
      @flaggable.add_flag(options.merge({:user => current_user}))
    end
  end

  def check_reputation_threshold
    if (result = Reputation::Threshold.lookup(:flag_offensive, current_user.person, :tier => @tier)) && !result.success?
      flash[:warning] = result.message
      render :update do |page|
        page << "Luleka.Modal.instance().reveal('#{escape_javascript(form_flash_messages)}')"
        page.delay(MODAL_FLASH_DELAY) do 
          page << "Luleka.Modal.close()"
        end
      end
      flash.discard
      return false
    end
    true
  end
  
  private
  
  # Helper to choose a layout based on criteria
  def choose_layout
    request.xhr? ? false : super
  end
  
end
