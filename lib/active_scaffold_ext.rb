ActiveScaffold::DataStructures::ActionLink.class_eval do
  mattr_accessor :record
end

# Override from active scaffold to distinguish between "save" and "save and close"
ActiveScaffold::Actions::Core.class_eval do

  def return_to_main
    if '1' == params[:save_only] && @record && !@record.new_record?
      redirect_to :action => "edit", :id => @record
      return
    elsif params[:next_action] && @record && !@record.new_record?
      next_step = YAML::load(params[:next_action])
      if next_step.is_a? Hash
        next_step = {:id => @record}.merge(next_step)
      end
      redirect_to next_step
      return
    else
      redirect_to :action => "index"
      return
    end
  end

end
