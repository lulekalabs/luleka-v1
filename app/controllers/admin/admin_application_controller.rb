# Base controller for all admin related controllers
class Admin::AdminApplicationController < ApplicationController
  helper :front_tag

  #--- filters
  prepend_before_filter :login_required
  before_filter :set_locale
  
  
  # /layouts/admin.rthml
  layout 'admin'

  #--- active scaffold
  ActiveScaffold.set_defaults do |config| 
    config.ignore_columns.add [:created_at, :updated_at, :lock_version]
  end
  
  #--- actions

  def index
  end
  
  #--- other
  protected
  
  def set_locale
    I18n.locale = :"en-US"
  end
  
  def ssl_required?
    ssl_supported?
  end
  
  def user_class
    AdminUser
  end
  
  def user_session_param
    :admin_user_id
  end
  
  def return_to_param
    :admin_return_to
  end
  
  def account_controller
    '/admin'
  end

  def account_login_path
    new_admin_session_path
  end

  # override from application controller
  def return_to_previous_param
    :admin_redirect_previous
  end

  # override from application controller
  def return_to_current_param
    :admin_redirect_current
  end

  # Triggers the provided event and updates the list item.
  # Usage:     do_list_action(:suspend!)
  def do_list_action(event)
    @record = active_scaffold_config.model.find_by_id params[:id]
    raise UserException.new(:record_not_found) if @record.nil?    
    if @record.send("#{event}")
      render :update do |page|
        page.replace element_row_id(:action => 'list', :id => params[:id]), 
          :partial => 'list_record', :locals => { :record => @record }
        page << "ActiveScaffold.stripe('#{active_scaffold_tbody_id}');"
      end
    else
      message = render_to_string :partial => 'errors'
      render :update do |page|
        page.alert(message)
      end
    end
  end

  # overrides set the page title from application
  def set_page_title(title=nil)
    @page_title = "Luleka Administrator - %{title}".t % {:title => title || SERVICE_TAGLINE}
  end
  
  # adds https to session url
  def ssl_admin_session_url
    admin_session_url(:only_path => false, :protocol => ssl_supported? ? 'https://' : 'http://')
  end
  helper_method :ssl_admin_session_url
  
end
