# Date class extensions
#
class Date

  # Return the date format, string or array, based on the current locale
  # Options:
  #   :return => :string  -> e.g. "%m/%d/%y"
  #   :return => :array -> e.g. [:year, :month, :day]
  #   :full -> "%A %B %d, %Y" for formats like "Tuesday, August 12, 1972" or "Dienstag, den 12. August, 1972"
  #   :long -> "%B %d, %Y" for formats like "August 12, 1972" or "12. August, 1972"
  #   :short -> "%b %d, %Y" for formats like "Aug 12, 1972" or "12. Aug, 1972"
  #   :numeric -> "%m/%d/%y" for formats like "08/26/72" or "26.08.1972"
  def self.format_string(format)
    if :full == format.to_sym
      # Monday, February 21, 2005
      I18n.t("date.formats.full").dup
    elsif :long == format.to_sym
      # February 21, 2005
      I18n.t("date.formats.long").dup
    elsif :short == format.to_sym
      # Aug 12, 1972
      I18n.t("date.formats.short").dup
    elsif :numeric == format.to_sym
      # 02/21/05
      I18n.t("date.formats.numeric").dup
    else
      "%Y-%m-%d"
    end
  end

  # returns an array of symbols indicating the order of month, day and year
  # localized to the current locale
  #
  # e.g.
  #
  #  Date.date_format_array -> [:day, :month, :year]  'de-DE'
  #  Date.date_format_array -> [:month, :day, :year]  'en-US'
  #  Date.date_format_array -> [:year, :month, :day]  'ja-JP'
  #
  def self.format_array
    # construct e.g. [:year, :month, :day] or [:day, :month, :year]
    # first get a short string format
    format = format_string(:numeric).gsub("%m", 'month').gsub("%d", 'day').gsub("%y", 'year')
    [',', ';', ':', '.', '-', '/'].each {|m| format.gsub!(m, ' ')}
#    array = eval "%w( #{format} )" # %w( day month year ) -> array
    array = format.split(' ').compact.map(&:to_sym)
    array
  end

  # intercepts with ruby <Date>.to_s
  def to_s_with_loc(format=nil)
    format ? self.loc(self.class.format_string(format)) : self.to_s_without_loc
  end
  alias_method_chain :to_s, :loc

end

