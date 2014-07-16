# Imports the exchange rates using the ExchangeRate, ideally daily
class ImportExchangeRatesJob

  def perform
    ExchangeRate.import!
  end

end  
