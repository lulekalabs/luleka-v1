# provides vote and rating actions and helpers for e.g. controllers KasesController and ResponsesController
# that offer to be rated by users
module VoteablesControllerBase
  def self.included(base)
    base.extend(ClassMethods)
    base.send :helper_method, :vote_up_member_path, :vote_down_member_path
    base.before_filter(:load_voteable, :only => [:vote_up, :vote_down])
  end
  
  module ClassMethods
  end

  #--- mixed in actions
  
  def vote_up
    do_vote(1)
  end
  
  def vote_down
    do_vote(-1)
  end
  
  protected

  def do_vote(value)
    result = nil
    if request.xhr? && @voteable
      # undo and do vote
      if previous_cast = @voteable.voted_by?(@person)
        # undo repute and vote
        if previous_cast.vote > 0
          result = @voteable.cancel_repute_vote_up(@person)
        elsif previous_cast.vote < 0
          result = @voteable.cancel_repute_vote_down(@person)
        end
        @voteable.undo_vote(@person)
      else
        # do vote and repute
        if value > 0
          result = @voteable.repute_vote_up(@person)
        elsif value < 0
          result = @voteable.repute_vote_down(@person)
        end
        @voteable.vote(value, @person) if !result || (result && result.success?)
      end
      
      # render
      if !result || (result && result.success?)
        render :update do |page|
          page.replace dom_id(@voteable, :vote), vote_control(@voteable)
          if result && result.success?
            page.replace status_dom_id, :partial => 'layouts/front/status_navigation'
            page.replace sidebar_stats_dom_id, :partial => "kases/sidebar_stats", :object => @voteable if @voteable.is_a?(Kase)
          end
        end
        return
      elsif result && !result.success?
        flash[:warning] = result.message
        render :update do |page|
          page << "Luleka.Modal.instance().reveal('#{escape_javascript(form_flash_messages)}')"
          page.delay(MODAL_FLASH_DELAY) do 
            page << "Luleka.Modal.close()"
          end
        end
        flash.discard
        return
      end
    end    
    render :nothing => true if !performed?
    return
  end

  def current_voteable
    @voteable
  end

  def load_voteable
    if Kase.self_and_subclasses.map(&:name).map(&:pluralize).map(&:underscore).include?(controller_name)
      @voteable = Kase.finder(params[:id]) if params[:id]
    elsif Response.name.pluralize.underscore == controller_name
      @voteable = Response.finder(params[:id]) if params[:id]
    end
  end

  #--- helpers

  # returns an url for vote_up for object
  def vote_up_member_path(object)
    selector, options = voteable_member_selector(object)
    member_url(selector, :vote_up, options)
  end

  # returns an url for vote_down for object
  def vote_down_member_path(object)
    selector, options = voteable_member_selector(object)
    member_url(selector, :vote_down, options)
  end
  
  private
  
  def voteable_member_selector(object)
    selector, options = [@tier], {}
    if object.is_a?(Kase)
      selector << object
    elsif object.is_a?(Response)
      selector << object.kase
      selector << object
    end
    return selector, options
  end

end
