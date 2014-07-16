# ActsAsPollable
require 'active_record'

module Probono #:nodoc
  module Acts #:nodoc:
    module Pollable #:nodoc:

      def self.included(base)
        base.extend ClassMethods
      end

      module ClassMethods
        def acts_as_pollable(opts={})
          options = options_for_pollable(opts)
          extend Probono::Acts::Pollable::SingletonMethods
          include Probono::Acts::Pollable::InstanceMethods

          has_many :polls, :as => :pollable, :dependent => :destroy
        end

      private
        def options_for_pollable(opts={})
          {
            :poller_class_name => 'Person'
          }.merge(opts)
        end
      
      end
      
      # This module contains class methods
      module SingletonMethods
      end
      
      # This module contains instance methods
      module InstanceMethods

        # Add a poll
        def create_poll(a_title, expiry=Time.now.utc+7.days)
          unless poll=polls.find_by_title(a_title)
            poll=polls.create( :title => a_title, :expires_at => expiry)
          end
          poll
        end

        # Remove a poll
        def delete_poll(a_title)
          polls.delete(poll=polls.find(:first, :conditions => ["title = ?", a_title]))
          poll
        end
        
        # Find a poll by title
        def poll(a_title=nil)
          if a_title.nil?
            polls.first
          else
            polls.find_by_title(a_title)
          end
        end

        # Vote for poll and outcome
        def vote_poll(a_title, a_label, a_participant=nil, options={})
          if poll=polls.find_by_title(a_title)
            poll.vote(a_label, a_participant, options)
          end
        end

        # You can count a poll by title and lable
        # Use options as in Poll class
        def count_poll(a_title, a_label, options={})
          if poll=polls.find_by_title(a_title)
            poll.count(a_label, options)
          end
        end
        
        # Get normalized data across all outcomes of a poll
        def data_poll(a_title, a_label=nil, options={})
          if poll=polls.find_by_title(a_title)
            poll.data(a_label, options)
          end
        end
        
        # Created data labels for a given data row
        def labels_poll(a_title, a_label=nil, options={})
          if poll=polls.find_by_title(a_title)
            poll.labels(a_label, options)
          end
        end
        
      end
    end
  end
end
