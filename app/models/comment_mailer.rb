# Takes care of all comment related mails
class CommentMailer < Notifier

  #--- notifiers
  
  def new_post(comment, role, sent_at=Time.now.utc)
    if comment && comment.commentable
      subject_line = case role
      when :person, :sender then "Comment posted on %{type} for \"%{title}\"".t % {
        :type => comment.commentable.class.human_name,
        :title => comment.kase.title
      }
      when :receiver then "Comment received on %{type} for \"%{title}\"".t % {
        :type => comment.commentable.class.human_name,
        :title => comment.kase.title
      }
      end
      from       Notifier.service_email
      recipients subject_line && comment.respond_to?(role) ? comment.send(role).email : []
      sent_on    sent_at
      subject    subject_line
      body       :comment => comment, :role => role
    end
  end
  
  def activation(comment, sent_at = Time.now.utc)
    subject        "Publish your comment for case \"%{title}\"".t % {:title => comment.kase.title.titleize}
    recipients     comment.sender_email
    from           Notifier.service_email
    sent_on        sent_at
    body(:comment => comment, :kase => comment.kase)
  end
  
end
