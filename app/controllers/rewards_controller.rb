# Manages to add or remove rewards from a kase
class RewardsController < FrontApplicationController
  include TiersControllerBase
  include CommentablesControllerBase
  include VoteablesControllerBase
  helper :kases, :flags, :voteables, :tiers, :topics, :property_editor
  
  #--- filters
  before_filter :load_kase
  before_filter :reputation_threshold_required
  
  #--- layout
  layout :choose_layout
  
  #--- actions

  def new
    @reward = build_reward
    render :template => 'rewards/new', :locals => {:modal => request.xhr?}
  end

  def create
    @reward = build_reward(params[:reward])
    if @reward.valid?
      @reward.activate!
      flash[:notice] = "Reward amount of %{price} was successfully added.".t % {:price => @reward.price.format}
      
      respond_to do |format|
        format.js {
          render :update do |page|
            page.replace dom_id(@kase), :partial => "kases/show_kase"
            page << rebind_facebox_javascript(dom_id(@kase))
            page << close_modal_javascript
          end
          flash.discard
        }
        format.html {
          redirect_to @kase
        }
      end
      return
    end
    # not valid
    respond_to do |format|
      format.js {
        @uses_modal = true
        render :update do |page|
          page.replace 'contentColumnModal', render(:file => 'rewards/new.html.erb')
        end
      }
      format.html {
        render :template => 'rewards/new'
        return
      }
    end
  end
  
  protected

  def load_kase
    if id = class_param_id(Kase)
      @kase = Kase.find_by_permalink(id, :include => [:tiers, :topics])
      @tier = @kase.tier if @kase
      @topics = @kase.topics if @kase
    end
  end

  def load_reward
    if id = params[:id]
      @reward = @kase.rewards.find(id)
    end
  end
  
  # build reward
  def build_reward(options={})
    @reward = Reward.new({:kase => @kase, :sender => @person}.merge(options))
    @reward
  end

  # overrides from front app and provides threshold action
  def reputation_threshold_action
    :offer_reward
  end
  
  def reputation_threshold_options
    {:validate_sender => @kase.person != @person}
  end
  
  # dom id for the kase main content and sidebar
  def page_dom_id
    dom_class(Kase, :page)
  end
  helper_method :page_dom_id

  private
  
  # Helper to choose a layout based on criteria
  def choose_layout
    request.xhr? ? 'modal' : 'front'
  end
  
end
