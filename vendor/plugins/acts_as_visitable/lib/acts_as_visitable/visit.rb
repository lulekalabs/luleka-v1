# Stores all visits between visitor and visitable
#
# Requires the following table columns
#
#    create_table :visits do |t|
#      t.column 'visitor_id', :integer 
#      t.column 'visited_id', :integer
#      t.column 'visited_type', :string
#      t.column 'ip_address', :string
#      t.column 'session_id', :string
#      t.column 'created_at', :datetime
#    end
#
class Visit < ActiveRecord::Base

  #--- associations
  belongs_to :visited, :polymorphic => true
  belongs_to :visitor, :foreign_key => :visitor_id, :class_name => 'Person'
    
  #--- class methods
  class << self
  end
  
  #--- instance methods

  # returns true if this is a unique visit
  def unique?
    self[:unique] ? true : false
  end
  
  protected
  
  # review this again later, it doesn't work
  # called in after_create
  def update_visits_count
    if self.visited && self.visited.visits_count_column? || self.visited.views_count_column?
      
      self.visited.sweep_count_cache
      
      self.visited.class.transaction do 
        self.visited.lock!
        
        attributes = {}
    
        # visits count
        if self.visited.visits_count_column? && self.unique?
          attributes[:visits_count] = self.visited[:visits_count] = self.visited.visits_count_cache = self.visited.calculate_visits_count
        end

        # views count
        if self.visited.views_count_column?
          attributes[:views_count] = self.visited[:views_count] = self.visited.views_count_cache = self.visited.calculate_views_count
        end
        
        self.visited.update_attributes(attributes) unless attributes.empty?
      end
    end
  end
  
end
