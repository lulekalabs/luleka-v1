class Outcome < ActiveRecord::Base
  # Associations
  has_many :countings, :dependent => :destroy
  belongs_to :poll
  
  # Cast a vote for this outcome with a participant optional
  def vote(a_participant=nil, options={})
    defaults = { :created_at => Time.now.utc }
    options = defaults.merge(options).symbolize_keys
    
    if !poll.expired? && poll.active?
      if a_participant.nil?
        countings.create(:created_at => options[:created_at].utc)
      else
        countings.create(:participant_id => a_participant.id, :poll => poll, :created_at => options[:created_at].utc)
      end
      update_attribute('count', self.count+1)
      return true
    end
    false
  end
  
  # Returns the votes for a data set defined by label or :all
  # Optionally, you can count each set or total define :until time
  # Options: :until => <time>
  # Usage: count :outcome => 'Apples'
  #        count :until => Time.now.utc - 1.day, :outcome => 'Apples'
  def count(options={})
    defaults = { }
    options = defaults.merge(options).symbolize_keys
    total = 0
    
    if options[:until]
      total = self.countings.count(:created_at, :conditions => ["created_at <= ?", options[:until]], :order => "created_at DESC")
    else
      total = read_attribute('count')
    end
    total
  end
  
  # Retrieves the data ready to feed to Gruff
  # Options:
  #  :resolution => <time> | :minute | :hour | :day | :week | :month | :auto
  #  :from_time =>  <time> | :now | :auto
  # Usage: 
  #  data(:from_time => Time.now.utc-5.months, :resolution => :month) => [2, 8, 25, 21, 10]
  #  data => [1, 2, 3] in auto mode
  def data(options={})
    defaults = { :resolution => :auto, :from_time => :auto }
    options = defaults.merge(options).symbolize_keys
    result = []

    # Starting time
    if :now==options[:from_time]
      return result.insert(0, self.count)
    elsif :auto==options[:from_time]
      from_time = time_of_oldest_vote
    else
      from_time = options[:from_time]
    end

    # Resolution
    time_interval=calculate_resolution(options)

    # Assemble result
    to_time = Time.now.utc
    until to_time<from_time
      c = self.count(:until => to_time)
      break if 0==c
      result.insert(0, c)
      to_time -= time_interval
    end
    result
  end
  
  # Generates Gruff formatted data labels
  # Options
  #  :data : one data series e.g. from self.data
  #  :resolution => :hour | :day | :week | :month
  #  :skip => <number> | :auto
  # Usage:
  #   poll_labels(data) => { 0 => 'Jan', 2 => 'Mar', 4 => 'Mai' }
  def labels(options={})
    defaults = { :resolution => :auto, :skip => :auto }
    options = defaults.merge(options).symbolize_keys
    labels = []
    result = {}
    to_time = Time.now.utc
    data = options[:data] || self.data(options)
    time_interval = 0
    
    case options[:resolution]
      when :minute then time_interval = 1.minute
      when :hour   then time_interval = 1.hour
      when :day    then time_interval = 1.day
      when :week   then time_interval = 7.days
      when :month  then time_interval = 1.month
      when :year   then time_interval = 1.year
      when :auto   then time_interval = calculate_resolution
      else              time_interval = options[:resolution]
    end
    
    # Create labels
    data.reverse.each do |item|
      case time_interval
        when 0..1.day-1        then labels.insert(0, to_time.strftime("%H:%M"))
        when 1.day..1.year-1   then labels.insert(0, to_time.strftime("%m/%d"))
        else                        labels.insert(0, to_time.strftime("%Y"))
      end
      to_time -= time_interval
    end
    
    # Build labels hash
    index = 0
    labels.each do |label|
      result.merge!(index => label)
      index += 1
    end
    # Delete hash elements
    if :auto==options[:skip]
      # if too many
      while result.size>7
        index = 0
        result.sort.reverse.each do |item|
          result.delete(item.first) if 1==index.modulo(2)
          index += 1
        end
      end
    elsif options[:skip]>0
      # defined by :skip
      index = 0
      result.sort.reverse.each do |item|
        result.delete(item.first) unless 0==index.modulo(options[:skip]+1)
        index += 1
      end
    end
    result.sort
  end
  
  # Returns time when the first vote for this outcome has happened
  # If no vote has occured, current time will be returned
  def time_of_oldest_vote
    from_time = Time.now.utc
    if first=countings.find(:first, :order => 'created_at ASC')
      from_time=first.created_at if first.created_at<from_time
    end
    from_time
  end
  
  # Determines the optimal resolution for the graph
  def calculate_resolution(options={})
    defaults = { :resolution => :auto }
    options = defaults.merge(options).symbolize_keys
    time_interval = 0

    # Resolution
    if :auto == options[:resolution]
      from_time = time_of_oldest_vote
      distance_in_minutes = (((Time.now.utc - from_time).abs)/60).round
      case distance_in_minutes
        when 0..2:             time_interval = 100.years        # nothing
        when 3..14:            time_interval = 1.minute         # 3+ minutes
        when 15..44:           time_interval = 5.minutes        # 3+ 5 minutes
        when 45..179:          time_interval = 15.minutes       # 3+ 15 minutes
        when 180..4319:        time_interval = 1.hour           # 3+ hours
        when 4320..30239:      time_interval = 1.day            # 3+ days
        when 30240..129599:    time_interval = 7.days           # 3+ weeks
        when 129600..1577879:  time_interval = 1.month          # 3+ months
        else                   time_interval = 1.year           # 3+ years
      end
    else
      case options[:resolution]
        when :minute:          time_interval = 1.minute
        when :hour:            time_interval = 1.hour
        when :day:             time_interval = 1.day
        when :week:            time_interval = 7.days
        when :month:           time_interval = 1.month
        else                   time_interval = options[:resolution]
      end
      time_interval = options[:resolution]
    end
    time_interval
  end
  
end
