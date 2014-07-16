class Poll < ActiveRecord::Base
  # Associations
  has_many :outcomes, :dependent => :destroy
  belongs_to :pollable, :polymorphic => true
  
  # Add an outcome, e.g. 'Apple'
  def add(a_label)
    if !expired? && !active?
     out=outcomes.find_or_create_by_label(a_label)
     self.save
    end
    out
  end
  
  # Remove an outcome
  def remove(a_label)
    if !active?
      outcomes.delete(out=outcomes.find(:first, :conditions => ["label = ?", a_label]))
    end
    out
  end
  
  # Activates this poll
  def activate!
    write_attribute('active', 1)
    true
  end
  
  # Deactivate this poll
  def deactivate!
    write_attribute('active', 0)
    false
  end
  
  # Is this poll active?
  def active?
    return true if read_attribute('active')==1
    false
  end
  
  # Expires this poll right now
  def expire!
    write_attribute('expires_at', Time.now.utc)
    deactivate!
  end
  
  # Has this poll been expired?
  def expired?
    if Time.now.utc>expires_at
      deactivate!
      return true 
    end
    false
  end
  
  # Vote for an outcome
  # A given participant can only vote once for any available outcome
  def vote(a_label, a_participant=nil, options={})
    raise "Poll expired".t if expired?
    raise "Poll not active".t unless active?
    unless a_participant.nil?
      voted=nil
      outcomes.each { |outcome| break if voted=outcome.countings.find(:first, :conditions => ["participant_id", a_participant.id] ) }
      if voted.nil?
        if outcome=outcomes.find_by_label(a_label)
          update_attribute('total', self.total+1)
          return outcome.vote(a_participant, options)
        end
      end
    else
      if outcome=outcomes.find_by_label(a_label)
        update_attribute('total', self.total+1)
        return outcome.vote(options)
      end
    end
    false
  end

  # Returns the votes for a data set defined by label or :all
  # Optionally, you can count each set or total define :until time
  # Options: :until => <time>
  # Usage: count 'Apples' => 1
  #        count :until => Time.now.utc - 1.day, :outcome => 'Apples'
  #        count => { 'Apples' => 1, 'Oranges' => 5 }
  def count(a_label=nil, options={})
    if a_label.nil?
      result = {}
      outcomes.each do |outcome|
        result.merge!(outcome.label => outcome.count(options))
      end
      return result
    else
      if outcome=outcomes.find_by_label(a_label)
        outcome.count(options)
      end
    end
  end

  # Of all outcomes, determine the outcome which has the oldest vote :-)
  def find_outcome_with_oldest_vote
    from_time = Time.now.utc
    result = nil
    outcomes.each do |outcome|
      time = outcome.time_of_oldest_vote
      if time<from_time
        from_time = time 
        result = outcome
      end
    end
    result
  end

  # Retrieves the data ready to feed to Gruff
  # Options:
  #  :resolution => <time> | :minute | :hour | :day | :week | :month | :auto
  #  :from_time =>  <time> | :now | :auto
  # Usage: 
  #  data('Apples', :from_time => Time.now.utc-5.months, :resolution => :month) => [2, 8, 25, 21, 10]
  #  data('Apples') => [1, 2, 3] in auto mode
  def data(a_label=nil, options={})
    defaults = { :resolution => :auto }
    options = defaults.merge(options).symbolize_keys

    if a_label.nil?
      result = {}
      max_size = 0
      # if auto, determine resolution of outcome with oldest vote
      if :auto==options[:resolution]
        if outcome=find_outcome_with_oldest_vote
          options.merge!( :resolution => outcome.calculate_resolution(options) )
        end
      end
      # build result for each outcome
      outcomes.each do |outcome|
        d=outcome.data(options)
        result.merge!(outcome.label => d)
        max_size = d.size if d.size>max_size
      end
      # Normalize
      if result.size>1
        result.each do |k, v|
          while v.size<max_size
            v.insert(0, 0)
          end
        end
      end
      return result
    elsif outcome=outcomes.find_by_label(a_label)
      return outcome.data(options)
    end
    []
  end

  # Retrieve a label for Gruff, see Outcome class
  # If you already have a data row, you can provide it
  # using the :data option.
  def labels(a_label=nil, options={})
    defaults = { :resolution => :auto }
    options = defaults.merge(options).symbolize_keys

    if options[:data]
      outcomes.first.labels(options)
    else
      if a_label.nil?
        outcome=find_outcome_with_oldest_vote
        if outcome
          options.merge!(:resolution => outcome.calculate_resolution(options)) if :auto==options[:resolution]
          options.merge!(:data => outcome.data(options))
          return outcome.labels(options) unless 0==outcome.count
        end
      else
        o=outcomes.find_by_label(a_label)
        unless o.nil?
         return o.labels(options)
       end
      end
    end
    {}
  end

end
