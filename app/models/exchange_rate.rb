# Imports exchanges from the EuroFX and stores the rates in the table
# Will populate the Money exchange bank with the rates previously fetched.
#
#   ExchangeRate.import                # fetches the rates from EuroFX
#   Exchange.setup_money_bank   # populated the Money.bank periodically
#
class ExchangeRate < ActiveRecord::Base

  #--- constants
  BASE_CURRENCY              = "EUR"
  UPDATE_RATES_INTERVAL      = 6.hours
  UPDATE_BANK_RATES_INTERVAL = 3.hours

  #--- accessors
  cattr_accessor :rates_base_euro
  cattr_accessor :updated_rates_at

  #--- class methods
  class << self

    # setup thread to update Money.bank rates with ExchangeRate periodically
    def setup_money_bank
      @@worker_thread ||= Thread.new do 
        Thread.current[:name] = "Load Money Bank"
        loop do
          ExchangeRate::load_money_bank
          RAILS_DEFAULT_LOGGER.info "** exchange_rate: thread '#{Thread.current[:name]}' to update exchange rates in money bank."
          sleep(ExchangeRate::UPDATE_BANK_RATES_INTERVAL.to_i)
        end
      end
    end

    # loads supported currency rates into Money.bank
    def load_money_bank
      Money.bank = VariableExchangeBank.new unless Money.bank.is_a?(VariableExchangeBank)
      Utility.active_currency_codes.each do |from|
        Utility.active_currency_codes.each do |to|
          if rate = get(from, to)
            Money.bank.add_rate(from, to, rate) unless from == to
          end
        end
      end
    end
    
    # Get the exchange rate based on FROM and TO currency
    #
    # e.g.
    #
    #   get("EUR", "USD")  ->  1.34554
    #
    def get(from, to, options={})
      populate_if_expired
      if from == to
        1
      elsif from.match(/^EUR/i)
        self.rates_base_euro["#{to}".upcase]
      elsif to.match(/^EUR/i)
        if symetric = get("EUR", from)
          1 / symetric unless symetric == 0.0
        end
      else
        from_per_euro, to_per_euro = get("EUR", from), get("EUR", to)
        1 / from_per_euro * to_per_euro if from_per_euro && to_per_euro
      end
    end

    # calls the EuroFX for exchange rates
    def import!
      data = REXML::Document.new(Net::HTTP.get('www.ecb.int', '/stats/eurofxref/eurofxref-daily.xml'))
      xp = REXML::XPath.first(data, '//Cube/Cube').to_a
      transaction do 
        lock!
        xp.each do |currency| 
          begin
            set_base_euro(
              currency.attribute('currency').value,
              currency.attribute('rate').value.to_f
            )
          rescue NoMethodError
          end
        end
      end
    end
    
    private
    
    def lock!
      ExchangeRate.find(:all, :lock => true)
    end
    
    # writes rate to database and cache based on EUR
    def set_base_euro(to, rate)
      if exchange = ExchangeRate.find_or_create_by_from_currency_and_to_currency("EUR", to)
        exchange.update_attribute(:rate, rate)
        self.rates_base_euro ||= {}
        self.rates_base_euro[to.upcase] = rate if to
      end
    end

    # populates the rates cache
    def populate
      transaction do 
        er = ExchangeRate.find(:all, :conditions => ["from_currency LIKE ?", BASE_CURRENCY], :lock => true)
        unless er.blank?
          self.updated_rates_at ||= Time.now.utc
          self.rates_base_euro ||= {}
          er.each do |e|
            self.rates_base_euro[e.to_currency.upcase] = e.rate unless e.to_currency.blank?
          end
        end
      end
      RAILS_DEFAULT_LOGGER.info "** exchange_rate: populated rates_base_euro cache with new exchange rates."
    end
    
    # populate rates cache if expired
    def populate_if_expired
      if self.updated_rates_at
        populate if Time.now.utc - self.updated_rates_at > 6.hours
      else
        populate
      end
    end

  end
  
end
