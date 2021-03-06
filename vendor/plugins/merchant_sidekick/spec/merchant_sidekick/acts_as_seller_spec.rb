require File.dirname(__FILE__) + '/../spec_helper'

describe "A seller's model" do
  
  it "should be able to sell" do
    SellingUser.new.should respond_to(:sell)
  end

  it "should be able to sell" do
    SellingUser.new.should respond_to(:sell_to)
  end
  
  it "should have many orders" do
    lambda { SellingUser.new.orders(true).first }.should_not raise_error
  end

  it "should have many invoices" do
    lambda { SellingUser.new.invoices(true).first }.should_not raise_error
  end

  it "should have many sales orders" do
    lambda { SellingUser.new.sales_orders(true).first }.should_not raise_error
  end

  it "should have many sales invoices" do
    lambda { SellingUser.new.sales_invoices(true).first }.should_not raise_error
  end

end

describe "A seller sells one product" do
  fixtures :user_dummies, :product_dummies, :addresses
  
  before(:each) do
    @sally = user_dummies(:sally)
    @sally.create_billing_address(addresses(:sally_billing).content_attributes)
    @sally.create_shipping_address(addresses(:sally_shipping).content_attributes)

    @sam = user_dummies(:sam)
    @sam.create_billing_address(addresses(:sam_billing).content_attributes)
    @sam.create_shipping_address(addresses(:sam_shipping).content_attributes)
    
    @product = product_dummies(:widget)
  end
  
  it "should create a new order" do
    lambda do
      order = @sally.sell_to @sam, @product
      order.should be_an_instance_of(SalesOrder)
      order.should be_valid
      order.save!
    end.should change(Order, :count)
  end
  
  it "should add to seller's orders" do
    order = @sally.sell_to(@sam, @product)
    order.save!
    @sally.orders.last.should == order
    @sally.sales_orders.last.should == order
    order.seller.should == @sally
    order.buyer.should == @sam
  end
  
  it "should create line items" do
    order = @sally.sell_to(@sam, @product)
    order.line_items.size.should == 1
    order.line_items.first.sellable.should == @product
  end
  
  it "should set line item amount to sellable price" do
    order = @sally.sell_to @sam, @product
    order.line_items.first.amount.should == @product.price
  end
  
  it "should set line item amount to 0 if sellable does not have a price" do
    @product.price = 0
    order = @sally.sell_to @sam, @product
    order.line_items.first.amount.should == 0.to_money
  end
  
end

describe "A seller selling multiple products" do
  fixtures :user_dummies, :product_dummies, :addresses
  
  before(:each) do
    @sally = user_dummies(:sally)
    @sally.create_billing_address(addresses(:sally_billing).content_attributes)
    @sally.create_shipping_address(addresses(:sally_shipping).content_attributes)

    @sam = user_dummies(:sam)
    @sam.create_billing_address(addresses(:sam_billing).content_attributes)
    @sam.create_shipping_address(addresses(:sam_shipping).content_attributes)
    
    @products = [product_dummies(:widget), product_dummies(:knob)]
    @order = @sally.sell_to(@sam, @products)
  end
  
  it "should create line items for each sellable" do
    lambda { @order.save! }.should change(LineItem, :count).by(2)
    @order.should have(2).line_items
    @order.line_items.collect(&:sellable).should == @products
  end
end

describe "A seller selling no product" do
  fixtures :user_dummies, :product_dummies, :addresses
  
  before(:each) do
    @sally = user_dummies(:sally)
    @sally.create_billing_address(addresses(:sally_billing).content_attributes)
    @sally.create_shipping_address(addresses(:sally_shipping).content_attributes)

    @sam = user_dummies(:sam)
    @sam.create_billing_address(addresses(:sam_billing).content_attributes)
    @sam.create_shipping_address(addresses(:sam_shipping).content_attributes)

    @product = product_dummies(:widget)
  end

  it "should raise an error as sell is a protected method" do
    lambda { @sally.sell(@product) }.should raise_error(NoMethodError)
  end
  
  it "should raise an error for there is no sellable" do
    lambda { @sally.sell_to(@sam) }.should raise_error(ArgumentError)
  end
  
  it "should raise an error for no sellable" do
    lambda { @sally.sell_to(@sam, []) }.should raise_error(ArgumentError)
  end
  
end