# Provides property in-place editor functionality for profiles and kases.
#
# To define a property editor in the controller
#
#   property_action :kase, :description, :partial => 'kases/description', :locals => {:label => false}
#
#     or
#
#   property_action :address, :personal_address_attributes, :partial => 'shared/address',
#     :name => [:profile, :personal_address_attributes]
#
#
# In the view
#
#   <%= property_editor(:kase, :description, :editable => true, :partial => 'kases/description') %>
#
module PropertyEditor
  def self.included(base)
    base.extend(ClassMethods)
  end
  
  module ClassMethods

    def property_action(class_name, method_name, options={})
      partial = options.delete(:partial)
      name = options.delete(:name) || class_name.to_sym

      # edit
      define_method "edit_#{method_name}_in_place" do 
        if request.get? && request.xhr?
          object_name = params[:object_name]
          method_name = params[:method_name]
          message_id = params[:message_id]
          
          klass = class_name.to_s.pluralize.classify.constantize
          object = if klass.respond_to?(:find_by_permalink)
            klass.find_by_permalink(params[:id])
          else
            klass.find(params[:id])
          end

          render :partial => 'shared/property_in_place', :object => object, :locals => {
            :edit => true, :object_name => object_name, :method_name => method_name, :message_id => message_id,
            :update => true, :partial => partial, :locals => {
              :object_name => object_name,
              :method_name => method_name,
              :message_id => message_id,
#              :theme => @theme_name,
              :edit => true
            }.merge(options[:locals] || {})
          }
        else
          render :nothing => true
        end
      end

      # update
      define_method "update_#{method_name}_in_place" do
        if request.put? && request.xhr?
          object_name = params[:object_name]
          method_name = params[:method_name]
          message_id = params[:message_id]
          
          klass = class_name.to_s.pluralize.classify.constantize
          object = if klass.respond_to?(:find_by_permalink)
            klass.find_by_permalink(params[:id])
          else
            klass.find(params[:id])
          end
          
          object.attributes = property_attributes_for_params(name)
          if object.valid?
            object.save
            render :partial => 'shared/property_in_place', :object => object, :locals => {
              :edit => false, :object_name => object_name, :method_name => method_name, :message_id => message_id,
              :update => true, :editable => true, :partial => partial, :locals => {
                :object_name => object_name,
                :method_name => method_name,
                :message_id => message_id,
#                :theme => @theme_name,
                :edit => false
              }.merge(options[:locals] || {})
            }
          else
            render :text => form_error_messages_for(object, :uniq => true), :status => 444
          end
        end
      end
    end
    
  end
  
  protected

  # reads the parameters based on the :name option passed in to property_action
  # for in place properties
  def property_attributes_for_params(name=nil)
    name = [name].flatten
    case name.size
      when 1 then params[name[0]]
      when 2 then params[name[0]][name[1]]
      when 3 then params[name[0]][name[1]][name[2]]
    else
      raise "Can't read attributes"
    end
  end

end