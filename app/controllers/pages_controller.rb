# This controller serves static page content from views or the database
require 'radius'
class PagesController < FrontApplicationController
  
  #--- filters
  skip_before_filter :login_required
  before_filter :load_tier, :only => :show
  before_filter :load_page, :only => :show
  
  #--- layout
  layout :choose_layout, :except => :show

  #--- actions

  def show
    if params[:id] && self.respond_to?("#{params[:id]}")
      self.page_title = params[:id].titleize.t
      render :template => "pages/#{params[:id]}", :layout => page_layout
      return
    elsif @page || page_fragment_exist?
      self.page_title = page_fragment_exist? ? params[:id].titleize.t : @page.title
      render :template => 'pages/show', 
        :layout => page_layout
    else
      raise ActiveResource::ResourceNotFound, "#{params[:id]} not found"
    end
  end

  def no_javascript
    # renders a page to complain that javascript is not enabled on the browser
  end
  
  def faq
    # faqs Note: needs to stay in here 
    @page_title = "Frequently Asked Questions".t
  end
  
  def switch_to_nl
    session[:site_ui] = "nl"
    redirect_to "/"
  end
  
  def switch_to_ol
    session[:site_ui] = nil
    redirect_to "/"
  end
  
  protected

  def ssl_required?
    false
  end
  
  def ssl_allowed?
    false
  end
  
  def load_page
    if params[:id] && !self.respond_to?("#{params[:id]}") && !page_fragment_exist?
      @page = Page.find_by_permalink(params[:id])
    end
  end
  
  def page_fragment_exist?
    fragment_exist?(page_fragment_cache_key(self.page_permalink))
  end

  def page_permalink
    @page ? @page.permalink : params[:id]
  end
  helper_method :page_permalink

  # returns the layout for the page
  def page_layout
    if @page
      if params[:popup]
        "modal"
      elsif !@page.layout.blank?
        @page.layout
      else
       choose_layout
     end
    else
      params[:popup] ? 'modal' : choose_layout
    end
  end

  # used when page has specific tier info, e.g. faq
  def load_tier
    if id = params[:tier_id]
      @tier = Tier.find_by_permalink_and_region_and_active(id)
    end
  end
  
end
