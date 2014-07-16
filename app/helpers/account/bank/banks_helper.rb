module Account::Bank::BanksHelper

  # returns a description string for a piggy bank account transaction
  #
  # e.g. 
  #
  #   "Deposit. A deposit of $3.50 from John Smith on May-3, 2009"
  #   "Transfer. A Transfer of $3.50... <a href='/account/invoices/...'>Order"
  #
  def transaction_description(transaction)
    descriptions = []
    descriptions << transaction.description unless transaction.description.blank?
    descriptions << case transaction.context.class.name
    when /Invoice/ then "%{context} %{status}" % {
      :context => link_to("#{transaction.context.class.human_name.titleize} (#{transaction.context.short_number})", account_invoice_path(transaction.context)),
      :status => transaction.context.current_state_t
    }
    when /Order/ then "%{context} %{status}" % {
      :context => link_to("#{transaction.context.class.human_name.titleize} (#{transaction.context.short_number})", account_order_path(transaction.context)),
      :status => transaction.context.current_state_t
    }
    end if transaction.context
    descriptions.compact.to_sentences + "&nbsp;"
  end
  
end
