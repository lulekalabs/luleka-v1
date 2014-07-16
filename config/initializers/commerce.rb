#--- Money + ExchangeRate
Utility.setup_default_currency_and_bank_rates

#--- active merchant
ActiveMerchant::Billing::CreditCard.require_verification_value = true

#--- merchant sidekick
LineItem.tax_rate_class_name = 'TaxRate'
