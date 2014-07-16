class ActiveRecord::Base

  #--- class methods
  class << self

    # sanitizes SQL and safely merges multiple conditions with AND
    #
    # e.g.
    #
    #   User.sanitize_and_merge_conditions "id = 1", [':state = ?', state]
    #   ->  "id = 1 AND state = 'new'"
    #
    def sanitize_and_merge_conditions(*conditions)
      conditions = conditions.reject(&:blank?).map {|condition| sanitize_sql_for_assignment(condition)}.reject(&:blank?)
      conditions.empty? ? nil : conditions.join(" AND ")
    end
    
  end
  
  
  # Dito, but the instance method
  def sanitize_and_merge_conditions(*conditions)
    self.class.sanitize_and_merge_conditions(*conditions)
  end
  
end