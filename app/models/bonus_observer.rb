# Class makes sure that a bonus event is created for each observed instance
class BonusObserver < ActiveRecord::Observer 
  observe Person, Kase, Response
  
  def after_create(record)
    receiver = case record.class.name
    when /Person/ then record
    else record.person
    end
    tier = find_tier(record)
    BonusEvent.create(:source => record, :action => :created, :receiver => receiver, :tier => tier) if tier && receiver
  end
  
  def after_update(record)
  end
  
  protected
  
  # retrieves e.g. @tier of the source instance or an object that has a 
  # piggy bank associated with it
  def find_tier(source)
    if source.is_a?(Kase)
      source.tier
    elsif source.is_a?(Response)
      source.kase.tier
    elsif source.is_a?(Comment)
      if source.commentable && source.commentable.is_a?(Kase)
        source.commentable.tier
      elsif source.commentable && source.commentable.is_a?(Response)
        source.commentable.kase.tier
      end
    end
  end
  
end 
