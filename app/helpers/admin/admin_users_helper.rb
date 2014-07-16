module Admin::AdminUsersHelper
  
  def role_ids_column(record)
    record.roles.map(&:name).join(", ")
  end
  
end
