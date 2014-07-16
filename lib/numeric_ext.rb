# Numeric class extension
#
class Numeric

  # Enhances the Numeric.to_money core extension inside money plugin
  # with a feature to also specify the currency, which, by default,
  # is set to USD

  # Allows Writing of 100.to_money for +Numeric+ types
  #   100.to_money => #<Money @cents=10000>
  #   100.37.to_money => #<Money @cents=10037>
  # Now also supports...
  #   12.32.to_money( :currency => 'EUR' )  => #<Money @currency='EUR', @cents=1232 @>
  def to_money(options={})
    options = {:currency => 'USD'}.merge(options).symbolize_keys
    Money.new(self * 100, options[:currency])
  end

end

