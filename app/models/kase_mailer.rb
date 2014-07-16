class KaseMailer < Notifier
  
  # Notify an expert of a case which matches this expert's profile 
  def new_post(kase, role=nil, receiver=nil, sent_at = Time.now.utc)
    case role
    when nil, :person, :owner
      subject_line = reason_text = "You posted a new %{type} about \"%{title}\"".t % {
        :type => kase.class.human_name,
        :title => kase.title
      }
      email_addresses = receiver || kase.person.name_and_email
    when :partner, :employee, :member, :match
      subject_line = reason_text = "You match %{type} about \"%{title}\"".t % {
        :type => kase.class.human_name,
        :title => kase.title
      }
      email_addresses = if receiver.is_a?(Array)
        receiver.map(&:name_and_email) || []
      elsif receiver.is_a?(Person)
        receiver.name_and_email || []
      else 
        []
      end
    when :contact, :friend, :following
      subject_line = reason_text = "%{name} has posted a new %{type} about \"%{title}\"".t % {
        :name => kase.person.casualize_name,
        :type => kase.class.human_name,
        :title => kase.title
      }
      email_addresses = if receiver.is_a?(Array)
        receiver.map(&:name_and_email) || []
      elsif receiver.is_a?(Person)
        receiver.name_and_email || []
      else 
        []
      end
    else
      subject_line = ''
      reason_text = ''
      email_addresses = []
    end
    
    subject        subject_line
    recipients     email_addresses
    from           Notifier.service_email
    sent_on        sent_at
    body(:kase => kase, :reason => reason_text)
  end

  def new_state(kase, new_state, role, sent_at = Time.now.utc)
    subject_line = description = "%{type} changed from %{current_state} to %{new_state} about \"%{title}\"".t % {
      :type => kase.class.human_name,
      :current_state => kase.current_state_t,
      :new_state => kase.current_state_t(new_state),
      :title => kase.title
    }
    
    subject        subject_line
    recipients     kase.respond_to?(role) ? kase.send(role).name_and_email : []
    from           Notifier.noreply_email
    sent_on        sent_at
    body(:kase => kase, :description => description, :role => role)
  end

  def solved(kase, role, sent_at = Time.now.utc)
    subject_line = description = case role
      when :owner, :person then "Your %{type} is solved, \"%{title}\"".t % {
        :type => kase.class.human_name,
        :title => kase.title
      }
      when :assigned_person then "You resolved %{type} about \"%{title}\"".t % {
        :type => kase.class.human_name,
        :title => kase.title
      }
    end
    
    subject        subject_line
    recipients     kase.respond_to?(role) ? kase.send(role).name_and_email : []
    from           Notifier.noreply_email
    sent_on        sent_at
    body(:kase => kase, :description => description, :role => role)
  end

  # Notify issue owner / expert that this case has expired
  def expired(an_issue, a_person, sent_at = Time.now.utc)
    if an_issue.owner==a_person
      subject        "Your case has expired, '{subject}'".t.gsub(/\{subject\}/, an_issue.subject)
    else
      subject        "Case expired, '{subject}'".t.gsub(/\{subject\}/, an_issue.subject)
    end
    recipients     a_person.email
    from           Notifier.noreply_email
    sent_on        sent_at
    body( :issue => an_issue, :person => a_person )
  end

  # Notify an expert of a case which matches this expert's profile 
  def qualification_match(an_issue, expert_list, sent_at = Time.now.utc)
    subject        "You qualify for '{subject}'".t.gsub(/\{subject\}/, an_issue.subject)
#    recipients     expert_list.collect {|e| e.email } # an_expert.email
    bcc            expert_list.collect {|e| e.email } # an_expert.email
    from           Notifier.noreply_email
    sent_on        sent_at
    body(:issue => an_issue)
  end
  
  def activation(kase, sent_at = Time.now.utc)
    subject        "Publish your case \"%{title}\"".t % {:title => kase.title.titleize}
    recipients     kase.sender_email
    from           Notifier.noreply_email
    sent_on        sent_at
    body(:kase => kase)
  end
  
  protected
  
  def setup_email(user)
    @recipients  = "#{user.first_name} #{user.last_name} <#{user.email}>"
    @from        = self.service_email
    @subject     = "#{self.site_url} "
    @sent_on     = Time.now
    @body[:user] = user
  end
    
end
