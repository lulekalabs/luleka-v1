module Admin::TierCategoriesHelper
  
  def super_type_form_column(record, name)
    select(:record, :super_type, [["Organization", Organization.name], ["Group", Group.name]])
  end
  
end
