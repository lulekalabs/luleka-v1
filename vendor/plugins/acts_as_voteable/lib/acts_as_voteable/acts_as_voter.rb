module Acts #:nodoc:
  module Voteable #:nodoc:

    def self.included(mod)
      mod.extend(ClassMethods)
    end

    module ClassMethods
      # Used for the voter class, such as User, Person
      # Options: :voteables => { :responses => "Response", :comments => "Comment" }
      def acts_as_voter(options={})
        has_many :votes, :foreign_key => :voter_id
        
        # add this to your Person model if you want all posts voted by this person
        #
        # has_many posts,
        #   :through => :votes,
        #   :source => 'Person',
        #   :foreign_key => :voteable_id,
        #   :conditions => "votes.voteable_type = 'Person'"
      end
    end
    
  end
end
