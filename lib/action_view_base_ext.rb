# makes sure we can render a pdf template with extension .rpdf
# you would have to add a 
#
#   # e.g. InvoiceController
#   def show
#     @invoice = Invoice.find(...)
#     respond_to do |format|
#       format.html
#     format.pdf do
#       send_data render(:template => 'invoice'),
#         :filename => 'products.pdf', :type => 'application/pdf', :disposition => 'inline'
#     end
#   end
#
#   # invoice view
#   <p><%= link_to 'PDF Format', formatted_invoice_path(@invoice, :pdf) %></p>
#
# in environment.rb
# 
#   Mime::Type.register 'application/pdf', :pdf
#   ActionView::Base.register_template_handler 'rpdf', ActionView::PDFRender
#
#  or rails > Rails 2.1
#
#   ActionView::Template.register_template_handler 'rpdf', ActionView::PDFRender
#
module ActionView
  require 'rubygems'
  require 'pdf/writer'
  require 'pdf/simpletable'

  class PDFRender
    PAPER = 'letter'

    include ApplicationHelper
    include ActionView::Helpers::AssetTagHelper
    include ActionView::Helpers::TextHelper      
    include ActionView::Helpers::TagHelper
    include ActionView::Helpers::UrlHelper


    def self.call(template)
      "ActionView::PDFRender.new(self).render(template, local_assigns)"
    end
    
    def initialize(action_view)
      @action_view = action_view
    end

    # Render the PDF
    def render(template, local_assigns = {})
      @action_view.controller.headers["Content-Type"] ||= 'application/pdf'

      # Retrieve controller variables
      @action_view.controller.instance_variables.each do |v|
        instance_variable_set(v, @action_view.controller.instance_variable_get(v))
      end

      pdf = ::PDF::Writer.new(:paper => Utility.paper_size || PAPER,
        :orientation => :portrait)
      pdf.compressed = true if RAILS_ENV != 'development'

      eval template.source, nil, "#{@action_view.base_path}/#{@action_view.first_render}.#{@action_view.finder.pick_template_extension(@action_view.first_render)}" 

      pdf.render
    end

    def self.compilable?
      false
    end

    def compilable?
      self.class.compilable?
    end
  end
end
