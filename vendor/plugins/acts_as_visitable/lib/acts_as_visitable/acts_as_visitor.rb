module Acts #:nodoc:
  module Visitable #:nodoc:

    def self.included(base)
      base.extend(ClassMethods)
    end

    module ClassMethods
      
      # Used for the acts_as_visitor class, such as User, Person
      # Options: :visitables => { :issue => "Issue", :person => "Person" }
      #
      # e.g.
      #
      #   class Person < ActiveRecord::Base
      #     ...
      #     acts_as_visitor :kase, :person 
      #     ...
      #   end
      #
      #   @person.visited_kases  ->  returns a list of kases that were visited
      #   @person.visited_people  ->  returns a list of people that were visited
      #  
      def acts_as_visitor(*args)
        has_many :visits, :foreign_key => :visitor_id
          
      end
    end
    
    module InstanceMethods
    end

  end
end
