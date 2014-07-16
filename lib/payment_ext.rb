# Enhances the order from merchant_sidekick with callback from the state 
# machine. This will enable us to add notifiers and other stuff to intefere
# with orders.
class Payment < ActiveRecord::Base
  
  #--- class methods 
  
  # overrides the class_for to include Piggy Bank payments
  def self.class_for(payment_object)
    if PaymentMethod.piggy_bank?(payment_object)
      PiggyBankPayment
    else
      CreditCardPayment
    end
  end
  
end