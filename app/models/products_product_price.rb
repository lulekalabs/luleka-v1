# Acts as the join table between product and product_price
class ProductsProductPrice < ActiveRecord::Base
  #--- associations
  belongs_to :product, :foreign_key => :product_id
  belongs_to :product_price, :foreign_key => :product_price_id
end
