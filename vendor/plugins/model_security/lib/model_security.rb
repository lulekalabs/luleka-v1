module Probono #:nodoc
  module ModelSecurity #:nodoc:

    def self.included(base)
      base.extend ClassMethods
      base.extend ClassAndInstanceMethods
    end


    module ClassMethods
      def self.extended(base)
        ActiveRecord::Base.send( :include, Probono::ModelSecurity::InstanceMethods )
        class_eval do
#          base.alias_method_chain :content_columns, :security
        end
      end

      # Declare whether reads and writes are permitted on the named attributes.
      def allows_access_of(*arguments, &block)
        let(:read, arguments, block)
        let(:write, arguments, block)
      end

      # Declare whether display of the named attribute is permitted.
      def allows_display_of(*arguments, &block)
        let(:display, arguments, block)
      end

      # Declare whether read is permitted upon the named attributes.
      def allows_read_of(*arguments, &block)
        let(:read, arguments, block)
      end

      # Declare whether write is permitted upon the named attributes.
      def allows_write_of(*arguments, &block)
        let(:write, arguments, block)
      end

      # Install default permissions for all of the attributes that Rails defines.
      #
      # Readable:
      #	created_at, created_on, type, id, updated_at, updated_on,
      #	lock_version, position, parent_id, lft, rgt,
      #	table_name + '_count'
      #
      # Writable:
      #	updated_at, updated_on, lock_version, position, parent_id, lft, rgt
      #
      # Writable only before the first save of an Active Record:
      #	created_at, created_on, type, id
      #
      def default_permissions
        allows_read_of :created_at, :created_on, :type, :id, :updated_at, \
        :updated_on, :lock_version, :position, :parent_id, :lft, :rgt, \
        (table_name + '_count').to_sym

        # These shouldn't change after the first save.
        allows_write_of :created_at, :created_on, :type, :id, :if => :new_record?

        # These can change.
        allows_write_of :updated_at, :updated_on, :lock_version, :position, :parent_id, \
        :lft, :rgt
      end

      # Checks if a let_read was defined for attribute
      def defines_read?(attribute)
        return false if read_inheritable_attribute(:read).nil?
        read_inheritable_attribute(:read)[attribute.to_sym].nil? ? false : true
      end

      # Checks if a let_write was defined for attribute
      def defines_write?(attribute)
        return false if read_inheritable_attribute(:write).nil?
        read_inheritable_attribute(:write)[attribute.to_sym].nil? ? false : true
      end

      # Checks if a let_display was defined for attribute
      def defines_display?(attribute)
        return false if read_inheritable_attribute(:display).nil?
        read_inheritable_attribute(:display).has_key?( attribute.to_s.to_sym ).nil? ? false : true
      end
      
      # Overload the base method to understand the let_display directive
      # of ModelSecurity. If display? is not true for a model attribute
      # in this context, that attribute won't be reported as a content
      # column.
      def content_columns_with_security
        content_columns_without_security.reject { |c|
          not displayable?(c.name)
        }
      end
      
    private

      # Internal function where the work of let_read, let_write, let_access,
      # and let_display is done. Store the tests to be run for each attribute
      # in the class, to be evaluated later. *permission* is :read,
      # :write, or :display. *arguments* is a list of attributes
      # upon which security permissions are being declared and a hash
      # containing all options, currently just :if . *block*, if given,
      # contains a security test.
      #
      def let(permission, arguments, block)
        attributes = []	# List of attributes that this permission applies to.
        parameters = {}	# Optional parameters, currently only :if
        procedure = nil	# Permission-test procedure.

        arguments.each { |argument|
          case argument.class.name
          when 'Hash'
            parameters.merge! argument
          else
            attributes << argument
          end
        }
        if not block.nil?
          procedure = block
        elsif (p = parameters[:if])
          procedure = p
        else
          procedure = :always?
        end

        d = {}
        attributes.each { |name| d[name] = procedure }
        write_inheritable_hash(permission, d)
      end
    end   # --- ClassMethods


    module ClassAndInstanceMethods
  
      def self.extended(base)
        ActiveRecord::Base.send( :include, Probono::ModelSecurity::ClassAndInstanceMethods )
      end

      # Stub test for let_read and friends. Always returns true.
      def always?
        true
      end

      # Stub test for let_read and friends. Always returns false.
      def never?
        false
      end
      
    private
    
      # Run a single test. 
      def run_test(test, context=nil)
        case test.class.name
        when 'Proc'
#          return test.call(context.nil? ? binding : context)
          return test.call(context.nil? ? self : context)
        when 'Symbol'
          return (context.nil? ? self : context).send(test)
        when 'String'
          return eval(test)
        else
          return false
        end
      end

      # This does the permission test for readable?, writable?, and display?. 
      # A global variable is used to short-circuit recursion.
      # 
      # FIX: The global variable should be replaced with a thread-local variable
      # once I learn how to make one. 
      #
      def run_tests(d, attribute, context=nil)
        global = d[:all]
        local = d[attribute.to_sym]
        result = true

        if (global or local) and ($in_test_permission != true)
          $in_test_permission = true
          result = (run_test(global) or run_test(local, context))
          $in_test_permission = false
        end
        return result
      end

    end  # --- ClassAndInstanceMethods

    
    # This module contains instance methods
    module InstanceMethods
      
      def self.included(base)
        class_eval do
          base.alias_method_chain :write_attribute, :security
          base.alias_method_chain :read_attribute, :security
        end
      end

      # Return true if a read of *attribute* is permitted.
      # *attribute* should be a symbol, and should be the
      # name of a database field for this model.
      def readable?(attribute, context=nil)
        test_permission(:read, attribute, context)
      end

      # Return true if a display of *attribute* is permitted.
      # *attribute* should be a symbol, and should be the
      # name of a database field for this model.
      def displayable?(attribute, context=nil)
        test_permission(:display, attribute, context)
      end

      # Return true if a write of *attribute* is permitted.
      # *attribute* should be a symbol, and should be the
      # name of a database field for this model.
      def writeable?(attribute, context=nil)
        test_permission(:write, attribute, context)
      end

      # Overloads ActiveRecord::Base#read_attribute. Read the attribute if that is
      # permitted. Otherwise, throw an exception.
      def read_attribute_with_security(name)
        if not readable?(name)
          security_error(:read, name)
        end
        read_attribute_without_security(name)
      end

      # Overloads ActiveRecord::Base#write_attribute. Write the attribute if that is
      # permitted. Otherwise, throw an exception.
      def write_attribute_with_security(name, value)
        if not writeable?(name)
          security_error(:write, name)
        end
        write_attribute_without_security(name, value)
      end

      # Has a read attribute been defined for Class of this instance?
      def defines_read?(attribute)
        self.class.defines_read?( attribute )
      end

      # Has a write attribute been defined for Class of this instance?
      def defines_write?(attribute)
        self.class.defines_write?( attribute )
      end

      # Has a display attribute been defined for Class of this instance?
      def defines_display?(attribute)
        self.class.defines_display?( attribute )
      end
      
      # This does the permission test for readable? or writable?.
      def test_permission(permission, attribute, context)
        if (d = self.class.read_inheritable_attribute( permission.to_sym ))
          return run_tests(d, attribute, context)
        end
        true
      end

    private

    
      # Responsible for raising an exception when an unpermitted security
      # access is attempted. *permission* is :read or :write.
      # *attribute* is the name of the attribute upon which an access is
      # being attempted.
      #
      def security_error(permission, attribute)
        global = nil
        local = nil

        if (d = self.class.read_inheritable_attribute( permission.to_sym ))
          global = d[:all]
          local = d[attribute.to_sym]
        end

        message = "Security Violation: #{permission} on attribute #{attribute.to_sym}" \
         "\n\tof object: #{self.inspect}."

        if global
          message << "\n\tTest for :all is #{global.inspect}."
        end

        if local
          message << "\n\tTest for :#{attribute} is #{local.inspect}."
        end

        raise SecurityError.new(message)
      end
      

    end # --- InstanceMethods
  end
end
