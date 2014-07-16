# Time class extensions
#
class Time 
=begin
  # If not running rails 1.2.3 the Time.to_date function is broken beginning with ruby 1.8.6
  # This patch with make the to_date and to_datetime public functions again
  %w(to_date to_datetime).each do |method| 
    public method if private_instance_methods.include?(method) 
  end 

  def end_of_year
    last_day = ::Time.days_in_month(12, self.year)
    change(:mday => last_day, :month => 12, :hour => 0, :min => 0, :sec => 0, :usec => 0)
  end
=end
end

