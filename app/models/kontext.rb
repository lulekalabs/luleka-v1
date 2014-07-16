# Kontext represents the link between the Kase (Problem, Question, Praise, Idea, etc.)
# and Tier (Organization, Company, Agency, Group) or Topic (Product, Service, etc.) or
# Location. It refers to a case context.
class Kontext < ActiveRecord::Base
  #--- assocations
  belongs_to :kase
  belongs_to :tier
  belongs_to :topic
  belongs_to :location
end
