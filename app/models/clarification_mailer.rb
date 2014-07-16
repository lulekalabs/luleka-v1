# Handling mails of clarifications, comment like, request and 
# response pairs for kases and responses
class ClarificationMailer < Notifier

  # Message sent when a "Request for Case-Clarification" (RFC)
  # or "Request for Response-Clarification" (RFR) has been issued!!
  #
  # Note: We cannot call this just "request" as it is already used in ActionMailer
  #
  def request_clarification(clarification, role, sent_at = Time.now.utc)
    if clarification && clarification.clarifiable
      request_type = if clarification.clarifiable.is_a?(Response) 
        "answer for %{type}".t % {:type => clarification.kase.class.human_name}
      else  
        clarification.kase.class.human_name
      end

      subject_line = case role
      when :sender then "Sent request to clarify %{type} \"%{title}\"".t % {
        :type => request_type,
        :title => clarification.kase.title
      }
      when :receiver then "Received request to clarify %{type} \"%{title}\"".t % {
        :type => request_type,
        :title => clarification.kase.title
      }
      end
      
      from       Notifier.service_email
      recipients subject_line && clarification.respond_to?(role) ? clarification.send(role).email : []
      sent_on    sent_at
      subject    subject_line
      body       :clarification => clarification
    end
  end

  # Message sent when a "Request for Case-Clarification" (RFC)
  # or "Request for Response-Clarification" (RFR) has been answered!!
  #
  # Note: we don't want to call this just response, at is may overlay
  #       controller methods
  #
  def response_clarification(clarification, role, sent_at = Time.now.utc)
    if clarification && clarification.clarifiable
      response_type = if clarification.clarifiable.is_a?(Response) 
        "answer for %{type}".t % {:type => clarification.kase.class.human_name}
      else  
        clarification.kase.class.human_name
      end
      
      subject_line = case role
      when :receiver then "Received response to clarify %{type} \"%{title}\"".t % {
        :type => response_type,
        :title => clarification.kase.title
      }
      when :sender then "Sent response to clarify %{type} \"%{title}\"".t % {
        :type => response_type,
        :title => clarification.kase.title
      }
      end
    end

    from       Notifier.service_email
    recipients subject_line && clarification.respond_to?(role) ? clarification.send(role).email : []
    sent_on    sent_at
    subject    subject_line
    body       :clarification => clarification
  end
  
end