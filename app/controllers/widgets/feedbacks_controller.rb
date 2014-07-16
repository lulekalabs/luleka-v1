# Feedback widget
class Widgets::FeedbacksController < Widgets::WidgetApplicationController
  helper :kases, :tiers
  
  #--- constants
  LOOKUP_LIMIT = 5
  
  #--- layout
  layout 'widgets/feedback'
  
  #--- filters
  skip_before_filter :verify_authenticity_token, :only => [:lookup, :create]
  before_filter :load_tier
  before_filter :load_topic
  before_filter :load_topics
  before_filter :load_kases
  
  #--- actions
  
  def show
    @kase = build_with(params[:kase] || {})
  end
  
  def create
    @kase = build_with(params[:kase] || {})
    
    if @kase.save
      @kase.activate!
      render :update do |page|
        page << "Luleka.Feedback.complete();"
        page << "Luleka.Feedback.reload();"
      end
    else
      render :update do |page|
        page.replace feedback_content_dom_id, :partial => '/widgets/feedbacks/content',
          :locals => {:update => true}
        page << "Luleka.Feedback.enter();"
        page << "Luleka.Feedback.reload();"
      end
    end
  end
  
  def lookup
    title = params[:kase][:title]
    klass = kase_class
    
    @kases = if @tier
      @tier.kases.find(:all, klass.find_options_for_query(title, :limit => LOOKUP_LIMIT))
    else
      klass.find_by_query(:all, title, :limit => LOOKUP_LIMIT)
    end
    
    if @kases.blank?
      render :update do |page|
        page << "Luleka.Feedback.enter()"
      end
      return
    else
      # return lookup results
      render :update do |page|
        page << "if ($('#{existing_kases_list_dom_class(self.kase_class)}')) {"
          page.replace existing_kases_list_dom_class(self.kase_class), :partial => 'widgets/feedbacks/kase_list', :object => @kases, 
            :locals => {:update => true, :kind => self.kase_class.kind}
        page << "} else {"
          page.insert_html :bottom, kase_list_dom_class(self.kase_class), :partial => 'widgets/feedbacks/kase_list', :object => @kases, 
            :locals => {:update => true, :kind => self.kase_class.kind}
        page << "}"
        page << "Luleka.Feedback.existing('#{self.kase_class.kind}')"
          
        page[dom_class(Kase, :continue_row)].show
        page[dom_class(Kase, :continue_spinner)].hide
        page[dom_class(Kase, :start)].show
      end
    end
  end
  
  protected

  # entire feedback container
  def feedback_dom_id
    "feedbackContainer"
  end
  helper_method :feedback_dom_id

  # container id that holds the feedback content
  def feedback_content_dom_id
    "feedbackContentContainer"
  end
  helper_method :feedback_content_dom_id

  # dom id for kase list, e.g. Idea -> "list-idea"
  def kase_list_dom_class(klass_or_name)
    if klass_or_name.is_a?(Class)
      "list-#{klass_or_name.kind}"
    else
      "list-#{klass_or_name.to_s.downcase}"
    end
  end
  helper_method :kase_list_dom_class

  # dom id for existing kases list in kase_list template
  def existing_kases_list_dom_class(klass_or_name)
    if klass_or_name.is_a?(Class)
      "existing-#{klass_or_name.kind}-list"
    else
      "existing-#{klass_or_name.to_s.downcase}-list"
    end
  end
  helper_method :existing_kases_list_dom_class
  
  def popular_kases_list_dom_class(klass_or_name)
    if klass_or_name.is_a?(Class)
      "popular-#{klass_or_name.kind}-list"
    else
      "popular-#{klass_or_name.to_s.downcase}-list"
    end
  end
  helper_method :popular_kases_list_dom_class

  # e.g. /companies/luleka/feedback
  def feedback_path(object_or_class, options={})
    "#{member_path(object_or_class)}/widgets/feedback"
  end
  helper_method :feedback_path

  # e.g. http://luleka.com/companies/luleka/feedback
  def feedback_url(object_or_class, options={})
    "#{member_url(object_or_class)}/widgets/feedback"
  end
  helper_method :feedback_url

  # e.g. /companies/luleka/feedback/lookup
  def lookup_feedback_path(object_or_class, options={})
    "#{member_path(object_or_class)}/widgets/feedback/lookup"
  end
  helper_method :lookup_feedback_path

  # e.g. http://luleka.com/companies/luleka/feedback/lookup
  def lookup_feedback_url(object_or_class, options={})
    "#{member_url(object_or_class)}/widgets/feedback/lookup"
  end
  helper_method :lookup_feedback_url

  # load kases for @tier
  def load_kases
    if @tier || @topic
      @ideas = (@topic || @tier).popular_kases.find(:all, :conditions => {:type => "Idea"}, :limit => LOOKUP_LIMIT)
      @questions = (@topic || @tier).popular_kases.find(:all, :conditions => {:type => "Question"}, :limit => LOOKUP_LIMIT)
      @problems = (@topic || @tier).popular_kases.find(:all, :conditions => {:type => "Problem"}, :limit => LOOKUP_LIMIT)
      @praises = (@topic || @tier).popular_kases.find(:all, :conditions => {:type => "Praise"}, :limit => LOOKUP_LIMIT)
    else
      @ideas = @questions = @problems = @praises = []
    end
  end
  
  # returns the class inferred by parameters, e.g. "idea" -> Idea 
  def kase_class
    @kase_class ||= params[:kase] ? (Kase.klass(params[:kase][:kind]) || Kase) : Kase
  end
  helper_method :kase_class

  # returns the type of the kind, e.g. :problem
  def kase_type
    kase_class.kind if kase_class
  end
  
  # builds a new kase based on the params passed in
  def build_with(options={})
    options = {:language_code => Utility.language_code || 'en', 
      :country_code => Utility.country_code || 'US'}.merge(options.symbolize_keys)
    Kase.new(options_for_kase(options))
  end
  
  # takes the params and returns a hash for kase to instantiate
  def options_for_kase(options={})
    options.delete(:kind)
    options.merge({
      :person => @person,
      :tier => @tier,
      :type => self.kase_class.kind
    }.merge(@topic ? {:topics => [@topic].compact} : {}))
  end

end
