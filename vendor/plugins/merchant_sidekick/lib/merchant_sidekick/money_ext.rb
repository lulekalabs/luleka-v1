# Fixes the initializer for Money.new nil to work
class Money
  # Creates a new money object. 
  #  Money.new(100) 
  # 
  # Alternativly you can use the convinience methods like 
  # Money.ca_dollar and Money.us_dollar 
  def initialize(cents, currency = default_currency)
    @cents, @currency = cents.nil? ? 0 : cents.round, currency
  end

end