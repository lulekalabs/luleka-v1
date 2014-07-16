# Defines roles available for admin users
class AdminRole < ActiveRecord::Base

  #--- associations 
  has_and_belongs_to_many :admin_users
  
  #--- instance methods
  
  def name
    self[:name] || self.kind.to_s.humanize
  end
  
end
