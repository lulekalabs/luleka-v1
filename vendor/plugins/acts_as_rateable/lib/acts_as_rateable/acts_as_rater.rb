# ActsAsRateable
module Acts #:nodoc:
  module Rateable #:nodoc:

    def self.included(mod)
      mod.extend(ClassMethods)
    end

    module ClassMethods
      
      # Used for the rater class, such as User, Person
      # In order to retrieve the the 
      # Options: :rated_responses => "Response", :rated_comments => "Comment"
      def acts_as_rater(options={})
        has_many :ratings, :foreign_key => :rater_id

        # add this to your model if you want e.g. all responses this person has rated
        # has_many posts,
        #  :through => :ratings,
        #  :source => 'Person',
        #  :foreign_key => :rateable_id,
        #  :conditions => "ratings.rateable_type = 'Person'"
      end

    end
  end
end
