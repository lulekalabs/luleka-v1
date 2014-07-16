# A partner membership voucher is a type of promotion that entitles the consignee for
# a partner membership if the voucher is redeemed.
#
# By default, the partner membership is 3 months.
#
class PartnerMembershipVoucher < Voucher
  #--- constants
  PROMOTABLE_SKU = 'SU00101'
  
  #--- class methods
  class << self
    
    def kind
      :partner_membership
    end
    
    def promotable_s
      'three-month partner membership'
    end

    def promotable_t
      promotable_s.t
    end
    
    def generate(quantity, options={})
      super(quantity, options.merge({:type => kind}))
    end
    
  end
  
  #--- instance methods
  
  def after_initialize
    self[:promotable_sku] = PROMOTABLE_SKU
  end
  
  # in addition to standard voucher validations, we want to make sure that
  # the consignee has not signed up as partner before. 
  #
  # the issue is that, the person.purchase_and_pay method will signup the 
  # consignee as partner before the voucher is redeemed. therefore, the 
  # voucher would become invalid if we were to test only for partner?, etc.
  # 
  # the "preliminary" solution is to check if there were any consignee partner
  # subscriptions before the time when we added the partner membership voucher
  # subscription. this currently should take no longer than a second, but we 
  # added a 10 second window just in case.
  #
  def validate
    super
    consignee_to_test = self.consignee || self.consignee_confirmation
    if consignee_to_test && consignee_to_test.partner?
      if consignee_to_test.subscriptions.find(:first,
          :conditions => ["subscriptions.created_at < ?", Time.now.utc - 10.seconds])
        self.errors.add(:code, I18n.t('activerecord.errors.messages.invalid'))
      end
    end

  end
  
end