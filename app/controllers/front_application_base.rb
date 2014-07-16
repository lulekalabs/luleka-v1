# Base module for shared front application controller helpers
# Used in Admin session
module FrontApplicationBase

  def self.included(base)
    base.send :helper_method, :form_flash_messages
    base.extend(ClassMethods)
  end
  
  module ClassMethods
  end
  
  protected

  # Prints flash messages
  # HTML => ...Error | ...Warning | ...Notice
  # FLASH_NAMES = [:error, :warning, :notice]
  # Options:
  #  :type => :error || :warning || :notice
  #  :header => "a title message"
  #
  def form_flash_messages(options = {})
    defaults = {
      :concise => false,
      :bracket => false,
      :theme => respond_to?(:current_theme_name) ? current_theme_name : :profile
    }
    options = defaults.merge(options).symbolize_keys

    if respond_to?(:render_to_string)   # render in Controllers
      render_to_string( :partial => 'shared/form_flash_messages', :locals => options )
    else
      # render in Views
      render(:partial => 'shared/form_flash_messages', :locals => options)
    end
  end

end