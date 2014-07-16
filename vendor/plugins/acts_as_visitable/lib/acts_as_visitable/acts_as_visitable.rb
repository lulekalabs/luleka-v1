module Acts #:nodoc:
  module Visitable #:nodoc:
    
    def self.included(base)
      base.extend(ClassMethods)
    end
  
    module ClassMethods

      # acts_as_visitable adds visiting capability to the models
      # acts_as_visitor is on the user or person side
      #
      # e.g.
      # 
      #    class < Visitable  # e.g. Post, Person, etc.
      #      ...
      #      acts_as_visitable 
      #        :time_range => 3.months,  # default: 5.days
      #        :class_name => 'Person'   # default: 'Person'
      #      ...
      #    end
      #
      def acts_as_visitable(options={})
        write_inheritable_attribute(:acts_as_visitable_options, options_for_visitable(options))
        class_inheritable_reader :acts_as_visitable_options

        has_many :visits, :as => :visited, :dependent => :destroy
        has_many :visitors,
          :through => :visits,
          :source => :visitor,
          :foreign_key => :visitor_id,
          :class_name => options_for_visitable(options)[:class_name],
          :conditions => ["visits.unique = ?", true],
          :order => "visits.created_at DESC"
        has_many :viewers,
          :through => :visits,
          :source => :visitor,
          :foreign_key => :visitor_id,
          :class_name => options_for_visitable(options)[:class_name],
          :order => "visits.created_at DESC"

        after_create :update_visits_cache
          
        include Acts::Visitable::InstanceMethods
        extend Acts::Visitable::SingletonMethods
      end
              
      private

      def options_for_visitable(options={})
        {:class_name => 'Person'}.merge(options)
      end
      
    end
    
    module SingletonMethods

      def visits_count_column?
        columns.to_a.map {|a| a.name.to_sym}.include?(:visits_count)
      end

      def views_count_column?
        columns.to_a.map {|a| a.name.to_sym}.include?(:views_count)
      end
    end
    
    module InstanceMethods #:nodoc:

      def visits_count_column?
        self.class.visits_count_column?
      end
      
      def views_count_column?
        self.class.views_count_column?
      end

      # add a unique visit to visitable by visitor
      # visitor can be a @person or unique string
      #
      # e.g.
      #
      #   @post.visit @person
      #   @post.visit session.session_id    # "fe7f785b6941a20aaf5fd11816d3f28b"
      #
      def visit(visitor, options={})
        visited_by?(visitor) ? false : build_or_create_visit(visitor, {:unique => true}.merge(options))
      end

      # add a visit to this visitable
      def view(visitor, options={})
        build_or_create_visit(visitor, {:unique => !visited_by?(visitor)}.merge(options))
      end

      # returns the visit if this visitor has visited the visitable, otherwise false
      # visitor can either be a Person instance or a session id
      def visited_by?(visitor)
        if visitor.is_a?(String)
          return self.visits.find(:first, :conditions => {:uuid => visitor, :unique => true},
            :order => "visits.created_at ASC") unless visitor.blank?
        else
          return self.visits.find(:first, :conditions => {:visitor_id => visitor.id, :unique => true},
            :order => "visits.created_at ASC") unless visitor.new_record?
        end
        false
      end

      # similar to visited_by, returns the latest view or false
      def viewed_by?(visitor)
        if visitor.is_a?(String)
          return self.visits.find(:first, :conditions => {:uuid => visitor},
            :order => "visits.created_at DESC") unless visitor.blank?
        else
          return self.visits.find(:first, :conditions => {:visitor_id => visitor.id},
            :order => "visits.created_at DESC") unless visitor.new_record?
        end
        false
      end

      # returns the unique visitors count
      def visits_count
        self.visits_count_cache || self.visits_count_cache = self.calculate_visits_count
      end

      # returns the views count
      def views_count
        self.views_count_cache || self.views_count_cache = self.calculate_views_count
      end
      
      # get visits count and visits count cache
      def visits_count_cache
        @visits_count_cache || @visits_count_cache = self.visits_count_column? ? self[:visits_count] : false
      end

      # set visits count and visits count cache
      def visits_count_cache=(count)
        if self.visits_count_column?
          self[:visits_count] = @visits_count_cache = count
        else
          @visits_count_cache = count
        end
      end

      # goes out to the database and calculates
      def calculate_visits_count
        self.visits.count(:conditions => {:unique => true}).to_i
      end

      # get views count and views count cache
      def views_count_cache
        @views_count_cache || @views_count_cache = self.views_count_column? ? self[:views_count] : false
      end

      # set views count and views count cache
      def views_count_cache=(count)
        if self.views_count_column?
          self[:views_count] = @views_count_cache = count
        else
          @views_count_cache = count
        end
      end

      # goes out to the database and calculates
      def calculate_views_count
        self.visits.count.to_i
      end

      # sweeps the count cache
      def sweep_count_cache
        @visits_count_cache = false
        @views_count_cache = false
      end

      protected

      # called after create to update cached columns
      def update_visits_cache(force=@update_visits_cache)
        if force
          @update_visits_cache = false

          self.sweep_count_cache
          
          # cached columns?
          if self.visits_count_column? || self.views_count_column?
            self.class.transaction do
              Vote.transaction do  
                self.lock_self_and_visits!
            
                attributes = {}
            
                # visits count
                if self.visits_count_column?
                  attributes[:visits_count] = self.visits_count_cache = self.calculate_visits_count
                end

                # views count
                if self.views_count_column?
                  attributes[:views_count] = self.views_count_cache = self.calculate_views_count
                end
                
                self.update_attributes(attributes) unless attributes.empty?
              end
            end
          end
        end
      end
      
      # pessimistically locks all visits
      def lock_self_and_visits!
        self.lock!
        self.visits(:lock => true)
      end

      def build_or_create_visit(visitor, options={})
        visit = false
        if visitor.is_a?(String)
          if self.new_record?
            visit = self.vitis.build({:uuid => visitor}.merge(options))
            @update_visits_cache = true
          else
            visit = self.visits.create({:uuid => visitor}.merge(options))
            update_visits_cache(true)
          end
        else
          if self.new_record?
            visit = self.vitis.build({:visitor => visitor}.merge(options))
            @update_visits_cache = true
          else
            visit = self.visits.create({:visitor => visitor}.merge(options))
            update_visits_cache(true)
          end
        end
        visit
      end
      
    end
    
  end
end
