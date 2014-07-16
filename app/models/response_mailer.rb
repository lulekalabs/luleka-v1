# Handles all mails for responses made by response author and
# the kase author
class ResponseMailer < Notifier

  #--- notifiers
  
  def new_post(response, role, sent_at=Time.now.utc)
    if response
      subject_line = case role
      when :person, :sender then "Answer posted on %{type} for \"%{title}\"".t % {
        :type => response.kase.class.human_name,
        :title => response.kase.title
      }
      when :receiver then "Answer received on %{type} for \"%{title}\"".t % {
        :type => response.kase.class.human_name,
        :title => response.kase.title
      }
      end
      email_address = subject_line && response.respond_to?(role) ? response.send(role).email : []

      from       Notifier.service_email
      recipients email_address
      sent_on    sent_at
      subject    subject_line
      body       :response => response
    end
  end
  
  def activation(response, sent_at = Time.now.utc)
    subject        "Publish your response for case \"%{title}\"".t % {:title => response.kase.title.titleize}
    recipients     response.sender_email
    from           Notifier.noreply_email
    sent_on        sent_at
    body(:response => response, :kase => response.kase)
  end
  
end
