# String class extensions
#
class String

  # turns this: "Hello People!!!" into this: "hello_people"
  def shortcase
    downcase.gsub(/[^a-z0-9]/, '_').gsub(/__*/,'_').gsub(/_$/,'').gsub(/^_/,'')
  end

  # returns the string only with first letter uppercased, the rest remains unchanged
  #
  # e.g.
  #
  #   "the big Fox jumps over the Computer"   ->   "The big Fox jumps over the Computer"
  #
  def firstcase
    self.length > 0 ? self.first.upcase + self[1..self.length - 1] : self
  end

  # makes sure that the string does not end with a period
  #
  # e.g.
  # 
  #   "a fox."  ->  "a fox"
  #   "a fox"   ->  "a fox"
  #   "."       ->  ""
  #
  def strip_period
    self.length > 1 ? self.strip[0..self.length - (self.strip.last == '.' ? 2 : 1)] : self.length == 1 && self.first == '.' ? '' : self
  end
  alias_method :chop_period, :strip_period

  # e.g. 
  #
  #  "question?".punctuation?  ->  true
  #  "this is a sentence".punctuation?  ->  false
  #
  def punctuation?
    !!self.last.match(/\.|\?|!/)
  end

  # creates a full sentence from a string by capitalizing the first letter
  # and adding a period (full stop)
  #
  # e.g.
  #
  #   'this tastes great'.to_sentence ->  'This tastes great.'
  #   'this tastes great!'  ->  'This tastes great!'
  # 
  def to_sentence
    self.length > 1 ? (self.punctuation? ? self.firstcase : "#{self.firstcase}.") : self
  end

  # Patches Money::core_extensions String.to_money support
  # a locale independent way for price (amount) entry in forms.
  # Examples:
  #   "$12,345.67".to_money              -> #<Money:0x30c21fc @currency="USD", @cents=1234567>
  #   "4;234".to_money                   -> #<Money:0x30c21fe @currency="USD", @cents=423>
  #   "5 €".to_money                      -> #<Money:0x30c21ff @currency="EUR", @cents=500>
  #   "5".to_money :currency => "EUR"    -> #<Money:0x30c21ff @currency="EUR", @cents=500>
  #   "1,2".to_money :currency => "EUR"  -> #<Money:0x30c21ff @currency="EUR", @cents=120>
  #
  
  # Parses a string and converts it to a Money object
  # It will not distinguish between any locale specific thousand 
  # and decimal separators, just assumes, any kind of seperation.
  # If not separation is provided, it assumes no decimals.

  SERVICE_CURRENCY_SYMBOL_MAPPING = [
    {'EUR' => ['EUR', '€']},
    {'USD' => ['USD', 'US$', '$']},
    {'GBP' => ['GBP', '£']}
  ]  

  def to_money(currency="USD")
    compounds = []
    strip_currency_symbol(self.to_s).split(/[\s\.,;]/).each { |i| compounds << i }

    case compounds.size
    when 0
      Money.new(0, currency)
    when 1
      Money.new(compounds[0].to_i * 100, currency)
    else
      value = ['', '']  # [full amount, cent amount]
      compounds[0..compounds.size - 2].each {|c| value.first << c.to_s}
      value[0] = value.first.to_i
      value[1] = (compounds.last.to_s + "00").scan(/../).first.to_i
      Money.new(value.first * 100 + value.last, currency)
    end
  end

  private

  def currency_symbols
    symbols = []
    SERVICE_CURRENCY_SYMBOL_MAPPING.each {|a| a.each_pair {|k, v| v.each {|e| symbols << e } } }
    symbols.uniq
  end

  def strip_currency_symbol(str)
    currency_symbols.each {|s| str.gsub!(s, '') }
    str
  end

end