# Reflects actions on the clarifications model.
class ClarificationsController < CommentsController
  
  protected
  
  def build_method(params={})
    if params[:request]
      :build_clarification_request
    elsif params[:reply] || params[:response]
      :build_clarification_response
    else
      :build_clarification
    end
  end
  
end
