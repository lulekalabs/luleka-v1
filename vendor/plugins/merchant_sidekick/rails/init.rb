require 'merchant_sidekick'

ActiveRecord::Base.send(:include, Merchant::Sidekick::Buyer)
ActiveRecord::Base.send(:include, Merchant::Sidekick::Sellable)
ActiveRecord::Base.send(:include, Merchant::Sidekick::Seller)

require 'shopping_cart'

RAILS_DEFAULT_LOGGER.info "** merchant_sidekick: plugin initialized properly."

