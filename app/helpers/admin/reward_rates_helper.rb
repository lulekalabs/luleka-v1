module Admin::RewardRatesHelper
  
  def source_class_form_column(record, name)
    object = BonusObserver.send(:new)
    select = object.observed_classes.map(&:name).map {|k| [k, k]}.insert(0, ["Select...", nil])
    select_tag(name, options_for_select(select, record.source_class))
  end

  def beneficiary_type_form_column(record, name)
    select_tag(name, options_for_select(record.class.beneficiary_types.map(&:to_s).map {|k| [k, k]}.insert(0, ["Select...", nil]), 
      record.beneficiary_type ? record.beneficiary_type.to_s : nil))
  end

  def action_form_column(record, name)
    select_tag(name, options_for_select(record.class.action_types.map(&:to_s).map {|k| [k, k]}.insert(0, ["Select...", nil]), 
      record.action ? record.action.to_s : nil))
  end

  def cents_form_column(record, name)
    text_field_tag(name, record.cents, :size => 5, :class => "text-input")
  end

  def percent_form_column(record, name)
    text_field_tag(name, record.percent, :size => 5, :class => "text-input")
  end

  def points_form_column(record, name)
    text_field_tag(name, record.points, :size => 5, :class => "text-input")
  end

  def max_events_per_month_form_column(record, name)
    text_field_tag(name, record.max_events_per_month, :size => 5, :class => "text-input")
  end
  
end
