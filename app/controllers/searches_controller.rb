# Controller is derived from TagsController
# Manages search for kases, people, and all other searchable items in front application.
#
# e.g.
#
# search kases
#   /kases/search/keyboard                                  | search all cases for "keyboard"
#   /communities/apple/kases/search/keyboard                | search Apple for cases "keyboard"
#   /communities/apple/topics/imac/kases/search/keyboard    | search Apple's iMac for cases "keyboard"
#
# search communities
#   /communities/search/apple                               | search for communities with "apple"
#
# topics
#   /communities/apple/topics/search/imac                   | search in Apple for topics with "imac"
#
# search people
#   /people/search/juergen+fesslmeier
#
class SearchesController < TagsController

  #--- actions

  def index
    do_redirect_query(Tag.parse_param(params[:q] || params[:search]))
  end
  
  protected

  def do_redirect_query(tags)
    unless tags.blank? && context_type.blank?
      if :kase == context_type
        #--- kase tags
        if topic_param_id
          redirect_to "/communities/#{tier_param_id}/topics/#{topic_param_id}/cases/search/#{tag_param_id(tags)}"
        elsif tier_param_id
          redirect_to "/communities/#{tier_param_id}/cases/search/#{tag_param_id(tags)}"
        else
          redirect_to "/cases/search/#{tag_param_id(tags)}"
        end
        return
      elsif :tier == context_type
        #--- tier tags
        redirect_to "/communities/search/#{tag_param_id(tags)}"
        return
      elsif :topic == context_type
        #--- topic tags
        redirect_to "/communities/#{tier_param_id}/topics/#{topic_param_id}/search/#{tag_param_id(tags)}"
        return
      elsif :person == context_type
        #--- person tags
        redirect_to "/people/search/#{tag_param_id(tags)}"
        return
      end
    end
    render :template => 'searches/no_result'
  end

  # override from tiers_controller
  # returns context type from params[:class] or otherwise calls tags_controller
  def context_type
    params[:type] ? ("#{params[:type]}".constantize == Kase ? :kase : "#{params[:type]}".constantize.kind) : super
  end

  # joins tags for parameter
  def tag_param_id(tags)
    tags.join("+") unless tags.blank?
  end
  
end
