module ScottBarron                   #:nodoc:
  module Acts                        #:nodoc:
    module StateMachine              #:nodoc:
      module SupportingClasses
        class StateTransition

          # the perform method was overridden, because update_attribute does
          # not work correctly when the record is new and a default DB
          # value for the state column is provided. The drawback of this patch
          # is (expensive) additional database access.
          #
          # e.g.
          #
          #   t.column :state, :default => 'passive'
          #   ...
          #   so = StateTest.new
          #   so.pending!
          #   so.current_state == :pending  # -> returned :passive without this patch
          # 
          def perform(record)
            return false unless guard(record)
            loopback = record.current_state == to
            states = record.class.read_inheritable_attribute(:states)
            next_state = states[to]
            old_state = states[record.current_state]
          
            next_state.entering(record) unless loopback

            # start change
            record.save(false) if record.new_record?
            # end change
            
            record.update_attribute(record.class.state_column, to.to_s)
          
            next_state.entered(record) unless loopback
            old_state.exited(record) unless loopback
            true
          end

        end
      end
      
      module InstanceMethods
      
        # Returns the current state the object is in, as a Ruby symbol.
        # The override takes care so that nil is returned rather than
        # throwing an exception when doing nil.to_sym
        def current_state
          self.send(self.class.state_column) ? self.send(self.class.state_column).to_sym : nil
        end
      
      end
    end
  end
end
