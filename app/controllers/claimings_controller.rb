# This controller handels "claims" for tiers and topics. Claims are 
# essentially request to be registered to work for company XYZ and
# support products/services XYZ
class ClaimingsController < FrontApplicationController
  include TiersControllerBase
  helper :tiers, :topics, :organizations, :products
  
  #--- constants
  MESSAGE_SUCCESS = "Thanks, we have received your claim to be an employee of \"%{name}\". It may take 1-3 business days to process your request."
  MESSAGE_CLAIM_SUCCESS = "Congratulations! You have successfully claimed your employment with \"%{name}\"."
  MESSAGE_CLAIM_WRONG_CODE = "Sorry, your claim to be employed with \"%{name}\" could not automatically be processed."
  MESSAGE_CLAIM_FAIL = "Something went wrong while processing your claim."

  #--- filters
  before_filter :load_tier
  before_filter :load_claiming, :only => :confirm
  
  #--- actions
  
  def new
    @topics = @tier.products.active
    @claiming = build_with {}
  end

  def create
    @topics = @tier.products.active
    @claiming = build_with({:organization => @tier}.merge(params[:claiming]))
    if @claiming.save
      @claiming.register!
      flash[:warning] = MESSAGE_SUCCESS.t % {:name => @claiming.organization.name}
      redirect_to member_path(@tier)
      return
    end
    render :action => 'new'
  end
  
  def confirm
    if @claiming && @claiming.pending?
      @claiming.accept!
      flash[:notice] = MESSAGE_CLAIM_SUCCESS.t % {
        :name => @claiming.organization.name
      }
      redirect_to person_path(@claiming.person)
      return
    elsif @tier
      flash[:error] = MESSAGE_CLAIM_WRONG_CODE.t % {
        :name => @tier.name
      }
      redirect_to organization_path(@tier)
      return
    else
      flash[:error] = MESSAGE_CLAIM_FAIL.t
      redirect_to organizations_path
      return
    end
  end
  
  protected

  def tier_class
    @tier_class || Organization
  end
  
  def topic_class
    Product
  end

  def build_with(options={})
    options = {:organization => @tier, :person => @person}.merge(options.symbolize_keys)
    Claiming.new(options)
  end
  
  # loads a tier, e.g. organization, specified by :organization_id, etc. as permalink, like 'luleka', 'apple', etc.
  def load_tier
    if id = tier_param_id || params[:tier_id]
      @tier = Tier.find_by_permalink_and_region_and_active(id)
      @tier_class = @tier.class if @tier
    end
  end

  def load_claiming
    if params[:id] && @tier && @tier.is_a?(Organization) && @person
      @claiming = @tier.claimings.find_by_activation_code_and_person(params[:id], @person)
    end
  end
  
end
