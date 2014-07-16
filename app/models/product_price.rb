# Represents the product price in one currency. Each product can have multiple 
# price definitions, depending on the locale or currency.
class ProductPrice < ActiveRecord::Base
  #--- associations
  has_and_belongs_to_many :products, :join_table => 'products_product_prices'
  
  #--- mixins
  money :price, :cents => :cents, :currency => :currency
  
end
