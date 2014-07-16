# Expires session in DB store older than 1 month
class DeleteExpiredSessionsJob

  def perform
    # is there a DB session store then delete all session that are older than 1 month?
    if ActiveRecord::Base.connection.tables.include?("sessions")
      ActiveRecord::Base.connection.execute("DELETE FROM sessions WHERE updated_at < '#{(Time.now.utc - 1.month).to_s(:db)}'")
    end
  end

end  
