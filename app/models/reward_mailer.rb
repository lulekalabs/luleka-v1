class RewardMailer < Notifier

  #--- notifiers

  def activated(reward, recipient, sent_at=Time.now.utc)
    setup_email(reward, recipient, sent_at)
    subject "%{price} reward was added to %{type} \"%{title}\"".t % {:price => reward.price.format,
      :type => reward.kase.class.human_name, :title => reward.kase.title}
  end

  def paid(reward, recipient, sent_at=Time.now.utc)
    setup_email(reward, recipient, sent_at)
    subject "%{price} reward paid for %{type} \"%{title}\"".t % {:price => reward.price.format,
      :type => reward.kase.class.human_name, :title => reward.kase.title}
  end

  def canceled(reward, recipient, sent_at=Time.now.utc)
    setup_email(reward, recipient, sent_at)
    subject "%{price} reward canceled for %{type} \"%{title}\"".t % {:price => reward.price.format,
      :type => reward.kase.class.human_name, :title => reward.kase.title}
  end

  protected
  
  def setup_email(reward, recipient, sent_at = nil)
    super(recipient, sent_at)
    from         Notifier.noreply_email
    recipients   recipient.email
    body         :reward => reward, :recipient => recipient
  end
  
end
