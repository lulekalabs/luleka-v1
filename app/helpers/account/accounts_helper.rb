module Account::AccountsHelper
  
  def order_description(order)
    link_to(order.line_items.map(&:sellable).map(&:name).to_sentence, account_order_path(order))
  end
  
  def invoice_description(invoice)
    link_to(invoice.line_items.map(&:sellable).map(&:name).to_sentence, account_invoice_path(invoice))
  end

  # returns a string that displays a total earnigns in statistics 
  def total_spending_earnings_and_profit(person)
    result = []
    result << "total spending %{total}".t % {:total => person.total_spending.format}
=begin    
		result << "total earning %{total}".t % {:total => person.total_earning.format} if person.partner?
		result << "%{total} %{profit_or_loss}".t % {
		  :total => person.total_profit.format
		  :profit_or_loss => (person.total_earning >= person.total_spending ? "profit".t : "loss".t),
		} if person.partner?
=end
		result.to_sentence.strip_period
  end
  
  # provides some basic feedback of response
  def total_response_rating(person)
    stars = ""
  	person.average_response_rating.to_int.times {stars << "*"}
  	
    "%{count} of %{total} responses received a feedback of %{percentage} (%{stars})".t % {
  	  :count => person.response_ratings.count.loc,
  	  :total => person.responses.count.loc,
  	  :percentage => "#{((person.average_response_rating / 5) * 100).loc} %",
  	  :stars => "<strong>#{stars}</strong>"
    } if person.responses.count > 0
  end
end
