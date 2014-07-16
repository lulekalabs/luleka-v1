# Employment is the link between a person and an organization. The employment status can be default or
# the employment can be upgraded to e.g. "official rep." or "admin"
class Employment < Membership
  #--- associations
  belongs_to :employee, :class_name => 'Person', :foreign_key => :person_id
  belongs_to :employer, :class_name => 'Organization', :foreign_key => :tier_id

  #--- class methods
  class << self

    # override from membership
    def kind
      :employment
    end

    # string rep of a employments member
    def member_s
      "employee"
    end
    
  end
  

end
