# Defines named roles for users that may be applied to
# objects in a polymorphic fashion. For example, you could create a role
# "moderator" for an instance of a model (i.e., an object), a model class,
# or without any specification at all.
class Role < ActiveRecord::Base
  # Associations
  belongs_to :authorizable, :polymorphic => true
  has_and_belongs_to_many :users
  has_and_belongs_to_many :rights



  # --- Instance methods

  def has_right?(right_name)
    right=get_right(right_name)
    return true if right
    false
  end

  # Assigns a right to a role instance
  def has_right(right_name)
    right = Right.find_by_name( right_name.to_s ) 
    if right.nil?
      return self.rights.create( :name => right_name.to_s )
    end
    self.rights << right if right and not self.rights.exists?( right.id )
  end
  
  # Removes a right from a role
  def has_no_right(right_name)
    right = get_right(right_name)
    if right
      self.rights.delete(right)
      right.destroy if right.roles.empty?
    end
  end

  # Assigned multiple rights to a role 
  def has_rights(*some_right_names)
    some_right_names.each do |right|
      has_right(right)
    end
  end

  # Clone the rights from another role
  def clone_rights_from(role_name)
    role=Role.find_by_name(role_name)
    if role
      self.rights << role.rights
    end
  end
    
  private
    
  # Within the role instance, find its rights,
  # which should be the same as the class method equvivalent
  def get_right(right_name)
    self.rights.find_by_name( right_name.to_s )
  end
  
  
end
