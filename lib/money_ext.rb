# extends class with additional methods
class Money
  
  class << self
    
    def max(a, b)
      a > b ? a : b
    end

    def min(a, b)
      a < b ? a : b
    end
    
  end
  
  def abs
    Money.new(self.cents < 0 ? -self.cents : self.cents, self.currency)
  end
  
  # displays any money object in the correct formatting
  #
  # options:
  #   :force_cents => true (default, always with cents, $10.00) / false ($10 but $10.01)
  #   :unlocalized => true (no locale specific,e.g 1000.02) / false (default, localized format according to locale, e.g. 1,000.02)
  #   :strip_symbol => true / false
  #   :currency_symbol => "US$" to replace the default with the one given here, or :code default currency code, e.g. "USD"
  #   :currency_code => true (USD 100)/ false ($100)
  #
  def format(options={})
    options.reverse_merge!(I18n.t("#{self.currency}.format", :scope => 'currencies')) if I18n.t("#{self.currency}.format", :scope => "currencies").is_a?(Hash)
    options.merge!(:unit => "") if options.delete(:strip_symbol)
    options.merge!(:unit => self.currency) if options.delete(:currency_code)
    options.delete(:unlocalized)  # deprecated
    number_to_currency(Float(self.cents) / 100, options).strip
  end
  
  # converts to another currency
  #
  # e.g.
  #
  #   Money.new(100, "USD").convert_to("EUR") ->  Money.new(77, "EUR")
  #
  def convert_to(currency)
    Money.new(1, currency) + self - Money.new(1, currency)
  end
  
  
  protected
  
  include ActionView::Helpers::NumberHelper
  
end
