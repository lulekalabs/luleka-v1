# ActsAsRateable derived work from Fortius
#
# In the rateable schema the following columns can be used to cache ratings
#
#   :ratings_average :integer
#   :ratings_count, :integer
#
module Acts #:nodoc:
  module Rateable #:nodoc:
    
    def self.included(mod)
      mod.extend(ClassMethods)
    end
  
    module ClassMethods
      
      # Adds ratings functionality to an ActiveRecord model
      #
      # The following methods are added and available to the model
      #
      # rate(rating) : Rate the object with a rating (integer)
      #
      # rating= : Alias for rate
      #
      # rating : Return the object's rating
      #
      # find_all_by_rating : Find all objects matching the rating criteria
      #
      # find_by_rating : Find the first object matching the rating criteria
      #
      def acts_as_rateable(opts={})
        options = default_options_for_rateable(opts)
        
        if options[:average] == true
          has_many :ratings,
            :dependent => :destroy,
            :as => :rateable,
            :foreign_key => :rateable_id
          
          # add has_many raters, by default rater_class_name => :person  
          if options[:rater_class_name]
            has_many :raters,
              :class_name => options[:rater_class_name].tableize.to_sym,
              :through => :ratings,
              :foreign_key => :rater_id
          end
          
          class_eval do
            def self.has_many_ratings?; true; end
          end
          
        else
          has_one :rating_association,
            :dependent => :destroy,
            :as => :rateable,
            :foreign_key => :rateable_id,
            :class_name => "Rating"

          class_eval do
            def self.has_many_ratings?; false; end
          end

          if options[:rater_class_name]
            define_method(:rater) do
              self.rating_association.rater if self.rating_association
            end
          end
        end
        
        after_create :update_ratings_cache

        include Acts::Rateable::InstanceMethods
        extend Acts::Rateable::SingletonMethods
      end
              
      private

      def default_options_for_rateable(opts={})
        {
          :limit => -1,
          :average => true,
          :rater_class_name => 'Person'
        }.merge(opts)
      end
      
    end
    
    module SingletonMethods
    
      def ratings_count_column?
        columns.to_a.map {|a| a.name.to_sym}.include?(:ratings_count)
      end

      def ratings_average_column?
        columns.to_a.map {|a| a.name.to_sym}.include?(:ratings_average)
      end
    
      # Finds objects with the ratings specified.  You can either specify a single
      # rating, or an array.  Each single rating or element in the array can be a
      # number or a range.  To find items with a minimum rating, use -1 as the end of the range.
      # Optionally, you can specify the rater
      # Example:
      # find_all_by_rating(3..-1)  # Finds all with a rating of at least 3
      # find_all_by_rating(3..-1, :rater => person) # Dito, but for person
      def find_all_by_rating(ratings, options={})
        rating_conditions = []
        
        rating_list = ratings
        unless ratings.kind_of?(Array)
          rating_list = [ratings]
        end
        
        rating_list.each do |rating|
          if rating.kind_of?(Range)
            if rating.end > 0
              if options[:rater]
                rating_conditions.push ["((rating >= ?) AND (rating <= ?) AND (rater_id = ?))", rating.begin, rating.end, options[:rater].id]
              else
                rating_conditions.push ["((rating >= ?) AND (rating <= ?))", rating.begin, rating.end]
              end
            else
              if options[:rater]
                rating_conditions.push ["((rating >= ?) AND (rater_id = ?))", rating.begin, options[:rater].id]
              else
                rating_conditions.push ["(rating >= ?)", rating.begin]
              end
            end
          else
            if options[:rater]
              rating_conditions.push ["((rating = ?) AND (rater_id = ?))", rating.to_i, options[:rater].id]
            else
              rating_conditions.push ["(rating = ?)", rating.to_i]
            end
          end
        end
        
        condition_str = rating_conditions.collect {|cond| cond.first}.join(' OR ')
        condition_args = rating_conditions.collect {|cond| cond.slice(1..-1) }.flatten
        with_scope(:find => {:conditions => [condition_str, *condition_args], 
            :include => has_many_ratings? ? :rating : :rating_association}) do
          find(:all, options)
        end      
      end
      
      # Find the first object matching the conditions specified
      # Optionally, define the rater as :rater => person
      def find_by_rating(ratings, options={})
        find_all_by_rating(ratings, options.update(:limit => 1)).first || nil
      end
      
    end
    
    module InstanceMethods #:nodoc:

      def ratings_count_column?
        self.class.ratings_count_column?
      end

      def ratings_average_column?
        self.class.ratings_average_column?
      end

      # creates and returns a rating instance
      # choose your own integer value as value 
      #
      # e.g.
      #
      #   @post.rate(-2)
      #   @post.rate(1, @person)
      #
      def rate(value, rater=nil, options={})
        rating = nil
        if has_many_ratings?
          if self.new_record?
            rating = self.ratings.build({:rating => value, :rater => rater}.merge(options))
            @update_ratings_cache = true
          else
            rating = self.ratings.create({:rating => value, :rater => rater}.merge(options))
            update_ratings_cache(true)
          end
        else
          if self.rating_association
            if self.new_record?
              rating = self.build_rating_association({:rating => value, :rater => rater}.merge(options))
              @update_ratings_cache = true
            else
              self.rating_association.update_attributes({:rating => value, :rater => rater}.merge(options))
              self.rating_association.reload
              rating = self.rating_association
              update_ratings_cache(true)
            end
          else
            if self.new_record?
              rating = self.build_rating_association({:rating => value, :rater => rater}.merge(options))
            else
              rating = self.create_rating_association({:rating => value, :rater => rater}.merge(options))
              update_ratings_cache(true)
            end
          end
        end
        rating
      end
      alias_method :rating=, :rate

      # undo rater's rating
      # for single rateables, remove rating
      # for average ratings, remove the latest rating by user
      def undo_rate(rater=nil)
        if has_many_ratings? && rater
          if rating = rated_by?(rater)
            rating.destroy
            self.ratings.reload
            update_ratings_cache(true)
          end
        else
          if self.rating_association
            self.rating_association.destroy
            self.ratings_average_cache = nil
            self.rating_association.reload
            update_ratings_cache(true)
          end
        end
      end

      # Has rateable been rated?
      #, or if rater is provided
      # also checks if the rater has rated this rateable already
      def rated?(rater=nil)
        if has_many_ratings?
          if rater
            return self.ratings.find(:first, :conditions => {:rater_id => rater.id},
              :order => "ratings.created_at DESC") unless rater.new_record?
          else
            !self.ratings.empty?
          end
        else
          return self.rating_association
        end
        false
      end
      
      # alias for rated?
      def rated_by?(rater)
        rated?(rater)
      end

      # Return the average rating for this object. If this object hasnt been rated,
      # we will return nil, otherwise, it will return the rating
      def ratings_average
        self.ratings_average_cache || self.ratings_average_cache = self.calculate_ratings_average
      end
      alias_method :rating, :ratings_average

      # returns true if we are in average mode
      def has_many_ratings?
        self.respond_to?(:ratings)
      end

      def ratings_count
        self.ratings_count_cache || self.ratings_count_cache = self.calculate_ratings_count
      end
      
      protected
      
      # get ratings average or cache
      def ratings_average_cache
        @ratings_average_cache || @ratings_average_cache = self.ratings_average_column? ? self[:ratings_average] : false
      end

      # sets ratings average column and cache
      def ratings_average_cache=(average)
        if self.ratings_average_column?
          self[:ratings_average] = @ratings_average_cache = average
        else
          @ratings_average_cache = average
        end
      end

      # goes out to the database and calculates the average
      def calculate_ratings_average
        if has_many_ratings?
          self.ratings.average(:rating).to_i
        else
          self.rating_association ? self.rating_association.rating : 0
        end
      end

      # get ratings count or cache
      def ratings_count_cache
        @ratings_count_cache || @ratings_count_cache = self.ratings_count_column? ? self[:ratings_count] : false
      end

      # sets ratings average column and cache
      def ratings_count_cache=(count)
        if self.ratings_count_column?
          self[:ratings_count] = @ratings_count_cache = count
        else
          @ratings_count_cache = count
        end
      end

      # goes out to the database and calculates the count
      def calculate_ratings_count
        if has_many_ratings?
          self.ratings.count.to_i
        else
          self.rating_association ? 1 : 0
        end
      end

      # called after create to update cached columns
      def update_ratings_cache(force=@update_ratings_cache)
        if force
          @update_ratings_cache = false
          
          # sweep cache
          @ratings_count_cache = false
          @ratings_average_cache = false
          
          if self.ratings_average_column? || self.ratings_count_column?
            self.class.transaction do
              Rating.transaction do  
                self.lock_self_and_ratings!

                attributes = {}
            
                # average cache
                if self.ratings_average_column?
                  attributes[:ratings_average] = self.ratings_average_cache = self.calculate_ratings_average
                end

                # count cache
                if self.ratings_count_column?
                  attributes[:ratings_count] = self.ratings_count_cache = self.calculate_ratings_count
                end

                self.update_attributes(attributes) unless attributes.empty?
              end
            end
          end
          
        end
      end
      
      # pessimistically locks all ratings and self
      def lock_self_and_ratings!
        self.lock!
        has_many_ratings? ? self.ratings(:lock => true) : self.rating_association(:lock => true)
      end
      
    end
    
  end
end
