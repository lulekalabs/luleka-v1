class Account::Bank::TransfersController < Account::Bank::BanksController
  include WizardBase

  #--- constants
  MESSAGE_SELECT_METHOD = "Please select a deposit method".t

  #--- filters
  before_filter :clear_current_transfer_time, :except => :complete
  before_filter :load_current_transfer_time_or_redirect, :only => :complete
  after_filter :clear_current_transfer_time, :only => :complete

  #--- wizard
  wizard do |step|
    step.add :new, "Transfer", :required => true, :link => true
    step.add :complete, "Complete", :required => true, :link => false
  end

  #--- actions

  def new
    build_deposit_methods(:paypal,
      @person.find_or_build_deposit_account(:paypal).content_attributes.merge({:person => @person}))
  end
  
  def create
    @deposit_object = build_deposit_method(
      params[:deposit_method], {
        :person => @person,
        :transfer_amount => params[:deposit_object] ? params[:deposit_object][:transfer_amount] : nil
      }.merge(params[params[:deposit_method]] || {})
    ) if params[:deposit_method]

    flash[:error] = MESSAGE_SELECT_METHOD unless params[:deposit_method]

    if @deposit_object && @deposit_object.valid?
      result = @deposit_object.transfer
      if result.success?
        @deposit_object = @person.find_or_build_deposit_account(@deposit_object.kind, @deposit_object.content_attributes)
        @deposit_object.save
        @deposit_object.register!
        @deposit_object.activate!
        self.current_transfer_time = Time.now.utc - 1.minute
        flash[:warning] = result.description
        redirect_to complete_account_bank_transfer_path
        return
      end
      flash[:error] = (result.message || '').humanize
    end
    render :action => 'new'
  end

  def complete
  end
  
  protected
  
  # hash key for transfer time
  def transfer_time_session_param
    :transfer_time
  end
  
  # Accesses the current transfer time from the session. 
  # Future calls avoid the database because nil is not equal to false.
  def current_transfer_time
    @current_transfer_time ||= load_transfer_time_from_session unless @current_transfer_time == false
  end
  helper_method :current_transfer_time

  # Store the given transfer time in the session.
  def current_transfer_time=(new_transfer_time)
    session[transfer_time_session_param] = new_transfer_time ? new_transfer_time.to_s : nil
    @current_transfer_time = new_transfer_time || false
  end
  
  # loads the time object from session
  def load_transfer_time_from_session
    self.current_transfer_time = Time.parse(session[transfer_time_session_param]) if session[transfer_time_session_param]
  end
  
  # clears transfer time in before_filter
  def clear_current_transfer_time
    self.current_transfer_time = @transfer_time = nil
    true
  end

  # loads the current time of transfer or 
  # redirects to new. used in before_filter
  def load_current_transfer_time_or_redirect
    @transfer_time = self.current_transfer_time
    unless @transfer_time
      redirect_to new_account_bank_transfer_path
      return
    end
    true
  end
  
end
