# Be sure to restart your server when you modify this file.

# Add new mime types for use in respond_to blocks:
# Mime::Type.register "text/richtext", :rtf
# Mime::Type.register_alias "text/html", :iphone

#--- pdf render
require 'action_view_base_ext'
Mime::Type.register 'application/pdf', :pdf
ActionView::Template.register_template_handler 'rpdf', ActionView::PDFRender  # Rails >2.1
