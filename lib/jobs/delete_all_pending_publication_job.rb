# Delete all objects that have not be activated in 30 days
class DeleteAllPendingPublicationJob

  def perform
    Kase.find_all_pending_publication.each {|kase| kase.delete!}
    Response.find_all_pending_publication.each {|response| response.delete!}
    Comment.find_all_pending_publication.each {|comment| comment.delete!}
  end

end  
