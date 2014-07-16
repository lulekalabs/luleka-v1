# Bank combines all bank related actions
class Account::Bank::BanksController < Account::AccountApplicationController
  
  #--- actions
  
  def show
    redirect_to account_bank_transactions_path
    return
  end
  
  protected
  
  def do_search_transactions(class_or_record, method=nil, options={})
    @transactions = do_search(class_or_record, method, {
      :partial => 'account/bank/transactions/list_item_content',
      :url => hash_for_account_bank_transactions_path,
      :sort => {'piggy_bank_account_transactions.created_at' => "Date".t},
      :sort_display => true,
    }.merge(options))
  end
  
end
