module RewardsHelper

  def collect_probono_offer_audience_type_for_select(with_select=false)
    AudienceType.find_for_probono_offer.map {|a| [a.name, a.kind]}.insert(0,
      with_select ? [with_select.is_a?(String) ? with_select : "Select...".t, nil] : nil).reject {|a| a.nil?}
  end

  def collect_fixed_offer_audience_type_for_select(with_select=false)
    AudienceType.find_for_fixed_offer.map {|a| [a.name, a.kind]}.insert(0,
      with_select ? [with_select.is_a?(String) ? with_select : "Select...".t, nil] : nil).reject {|a| a.nil?}
  end

  # returns "$" for "USD"
  def currency_code_to_unit(code)
    I18n.t("currencies.#{code.to_s.upcase}.format.unit", :raise => true)
  end
  
  # text field with currency symbol formatted correctly
  def text_field_with_currency_unit(object_name, method, options={})
    format = I18n.t("currencies.#{@reward.default_currency}.format.format") || "%n %u"
    format = format.split("%").reject {|a| a.blank?}.map(&:strip).compact
    
    elements = []
    format.each do |symbol|
      elements << text_field(object_name, method, options) if symbol == "n"
      elements << "&nbsp;#{content_tag(:span, currency_code_to_unit(@reward.default_currency), :class => "unit")}&nbsp;" if symbol == "u"
    end
    
    
    table_cells_tag(*elements)
  end
  
  # Returns an array of arrays with day and fix num
  def collect_days_to_expire_for_select(days=5)
    array = []
  	days.times do |d|
  	  case d
  	    when 0..5 then array << [I18n.t("{{count}} day", :count => (d + 1)), d + 1]
  	    when 6 then array << [I18n.t("{{count}} week", :count => 1), d + 1]
  	    when 13 then array << [I18n.t("{{count}} week", :count => 2), d + 1]
  	    when 20 then array << [I18n.t("{{count}} week", :count => 3), d + 1]
  	    when 27 then array << [I18n.t("{{count}} week", :count => 4), d + 1]
  	  end
	  end
  	array
  end

  # e.g. 
  #
  #   returns "(5-200 characters)"
  #
  def currency_inclusion(code, leading_space=true)
    content_tag(:span, (leading_space ? "&nbsp;" : '') + "(" + "in %{currency}".t % {:currency => code.to_s.upcase} + ")", 
      :class => "normal inclusion")
  end

  # price help text on reward form
  def reward_price_help_text 
    result = []
    result << "You offer must be between %{min} and %{max}.".t % {
      :min => content_tag(:span, @reward.min_price.format, :class => "highlight"),
      :max => content_tag(:span, @reward.max_price.format, :class => "highlight")
    }

    result << "Your available #{SERVICE_PIGGYBANK_NAME} account balance is %{balance}.".t % {
      :balance => content_tag(:span, current_user.person.piggy_bank.available_balance.format, :class => "highlight")
    } if logged_in?

    result << "Do you want to %{add} now?".t % {
      :add => link_to("add more credit".t, new_account_bank_deposit_path),
    }
    result.to_sentences
  end
  
  # expires at for reward on reward form
  def reward_expiry_help_text
    result = []
    if @reward.kase.offers_reward?
      result << "Another offer has already set an expiry time.".t
  	  result << "The offer is set to expire on %{time}.".t % {
        :time => content_tag(:span, @reward.expires_at.loc(:long), :class => "highlight")}
  	else
  	  result << "Please set a date until your offer is good.".t
  	end
  	result << "For more information, please visit our %{faq}.".t % {:faq => link_to("FAQ page".t, 
  	  @tier ? tier_faq_url(:tier_id => @tier.to_param) : faq_path, :popup => true)}
    result.to_sentences
  end
  
end
