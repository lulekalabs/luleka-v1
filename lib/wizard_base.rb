# Provides wizard functionality to mix into with controller.
# In order to define a wizard declare it inside the controller like this:
# 
# wizard do |step|
#   step.add :new, "Describe", :required => true, :link => true
#   step.add :finish, "Review", :required => true, :link => true
# end
#
#
# Wizard data is stored in a wizard hash class instance as follows and 
# can be accessed via wizard_data() helper:
#
#  @@wizard_hash = { :kase => [
#      { :step => 1, :action => 'create',            :caption => "Describe",         :required => true,  :link => true  }, 
#      { :step => 2, :action => 'finish',            :caption => "Finish",           :required => true,  :link => true  }, 
#    ]
#  }
#
module WizardBase
  def self.included(base)
    base.extend(ClassMethods)
    base.send :helper_method, :wizard_data, :next_wizard_action, :current_wizard_index, :current_wizard_step
  end
  
  module ClassMethods
    
    def wizard(name=nil, &block)
      wizard_name = name ? name.to_sym : controller_name.to_sym
      write_inheritable_attribute(:wizard_data, {wizard_name => []})
      yield(Step.new(self, wizard_name))
    end
  
    class Step 
      cattr_accessor :controller
      cattr_accessor :wizard_name
      def initialize(controller, wizard_name)
        @@controller = controller
        @@wizard_name = wizard_name
      end
    
      def add(action_name, caption, options={})
        options = {
          :controller => controller.controller_name.to_sym,
          :action => action_name.to_sym,
          :caption => caption,
          :link => true,
          :required => true,
          :display => true
        }.merge(options)

        %w(link required display).each do |option_name|
          if options[option_name.to_sym].is_a?(Symbol)
            method_name = options[option_name.to_sym]
            controller.append_before_filter("wizard_#{wizard_name}_#{action_name}_#{option_name}".to_sym)
            controller.class_eval <<-"end_eval"
              protected 
              def wizard_#{wizard_name}_#{action_name}_#{option_name}
                wizard_name = "#{wizard_name}".to_sym
                action_name = "#{action_name}".to_sym
                option_name = "#{option_name}".to_sym
                method_name = "#{method_name}".to_sym
                if step_hash = find_wizard_data_hash(:action, action_name)
                  step_hash[option_name] = send(method_name)
                end
              end
            end_eval
          end
        end
        
        controller.read_inheritable_attribute(:wizard_data)[wizard_name] << {
          :controller => controller.controller_name.to_sym,
          :action => action_name.to_sym,
          :caption => caption,
          :link => options[:link],
          :required => true,
          :display => true
        }.merge(options)
      end
    end
    
  end
  
  protected

  # returns the wizard data hash by the given name
  # or otherwise, returns the first element of the defined wizards
  def wizard_data(wizard_name=nil)
    if data = self.class.read_inheritable_attribute(:wizard_data)
      return data[wizard_name.to_sym] if wizard_name
      data.each {|k, v| return v}
    end
    []
  end

  # returns the current wizard index (say 0 for new, 1 for finish) or nil if not found
  # e.g. index is 0, 1, 2
  def current_wizard_index(action_name=nil, wizard_name=nil)
    action_name ||= respond_to?(:controller) ? self.controller.action_name : self.action_name
    action_name.to_sym
    wizard_data(wizard_name).each_with_index {|v, i| return i if action_name == v[:action]}
    nil
  end
  
  # similar to current_wizard_index but the steps are defined starting with 1
  # e.g. steps are 1, 2, 3, etc.
  def current_wizard_step(action_name=nil, wizard_name=nil)
    index = current_wizard_index(action_name, wizard_name)
    return index + 1 if index
    nil
  end

  # returns the current wizard action name
  def current_wizard_action(wizard_name=nil)
    if index = current_wizard_index(nil, wizard_name)
      return wizard_data(wizard_name)[index][:action]
    end
    nil
  end

  # returns the next action relative to the current action
  def next_wizard_action(action_name=nil, wizard_name=nil)
    wizard_data(wizard_name)[current_wizard_step(action_name, wizard_name) || 666]
  end
  
  private

  def find_in_wizard_data(key, value, wizard_name=nil)
    wizard_data(wizard_name).each {|v| return v[key.to_sym] if value == v[key.to_sym]}
    nil
  end

  def find_wizard_data_hash(key, value, wizard_name=nil)
    wizard_data(wizard_name).each {|v| return v if value == v[key.to_sym]}
    nil
  end

end