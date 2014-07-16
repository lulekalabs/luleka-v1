module Account::Bank::DepositsHelper

  def times_text_field_tag(item, index)
    text_field_tag("times[#{item.item_number}]", times[item.item_number] || (0 == index ? 1 : 0),
      :size => 1, :maxlength => 1)
  end

  def times_select_tag(item, index, number=5)
    select_tag("times[#{item.item_number}]", options_for_times_select(number), {:multiple => false})
  end

  def options_for_times_select(number=5, selected=nil)
    container = []
    number.times {|i| container << ["#{i + 1}", i + 1]}
    options_for_select(container, selected)
  end
  
end