# Invoice extension for generating PDF files and streams
#
#   @invoice.to_pdf
#   @invoice.to_pdf_file('test.pdf')
#   
class Invoice < ActiveRecord::Base
  include ActionView::Helpers::TextHelper
  
  #--- attributes
  attr_accessor :service_url

  #--- instance methods
  
  # returns a pdf stream
  def to_pdf(options={})
    self.to_pdf_writer(options).render
  end

  # write a PDF file name specified as file_name
  def to_pdf_file(file_name=self.default_pdf_file_name, options={})
    self.to_pdf_writer(options).save_as(file_name)
  end
  
  protected 
  
  # Creates and returns a PDF::Writer instance
  def to_pdf_writer(options = {})
    I18n.switch_locale(options[:locale] || Utility.locale_code) do
      # setup
      pdf = PDF::Writer.new(
        :paper => Utility.paper_size,
        :orientation => :portrait
      )
      encoding = {
        :encoding     => nil,  # "MacRomanEncoding",  #  "WinAnsiEncoding", 
        :differences  => { 
          215 => 'multiply', 
          148 => 'copyright',
          142 => 'euro'
        } 
      } 
      pdf.select_font("Helvetica", encoding)
      pdf.font_size = 12 
      pdf.margins_cm(1, 2.5, 1, 1.5) # (top, left = top, bottom = top, right = left)

      # header
      pdf.open_object do |header| 
        pdf.save_state 
        # columns
        pdf.start_columns(2, 20)   
        # add logo
        if self.seller.is_a?(Organization)
          begin
            image = pdf.image("#{RAILS_ROOT}/#{seller.logo('invoice')}",
              :resize => 1.00, :justification => :left, :pad => 0)
          rescue
          end
        end
        pdf.start_new_page  # will start new column 

        # senders's address
        fl = 0
        if self.origin_address
          pdf_bracket(pdf, pdf.left_margin - 10, pdf.y, pdf.column_width + 10, 120)

          if self.origin_address && self.origin_address.company_name
            pdf.text("<b>#{e(self.origin_address.company_name)}</b>",
              :justification => :left ) and fl += 1
          end

          pdf.text(e(self.origin_address.name.to_s),
            :justification => :left) and fl += 1 if self.origin_address && self.origin_address.name

          pdf.text(e(self.origin_address.address_line_1.to_s),
            :justification => :left) and fl += 1 if self.origin_address && self.origin_address.address_line_1
        
          pdf.text(e(self.origin_address.address_line_2).to_s,
            :justification => :left) and fl += 1 unless self.origin_address.address_line_2.blank?
            
          pdf.text(e(self.origin_address.city_postal_and_province), :justification => :left)

          pdf.text(e(self.origin_address.country_or_country_code.to_s), :justification => :left)
          pdf.text( "\n", :justification => :left )
        
          pdf.text(e(self.origin_address.phone.blank? ? "" : "Phone:".t + ' ' + self.origin_address.phone),
            :justification => :left )
          
          pdf.text(e(self.origin_address.fax.blank? ? "" : "Fax:".t + ' ' + self.origin_address.fax),
            :justification => :left )
          pdf.text("\n" * fl)
        end
        pdf.stop_columns

        # space
        pdf.text( "\n\n\n" )

        # columns
        pdf.start_columns(2, 20)   # columns=2, gutter=20
        pdf_bracket(pdf, pdf.left_margin - 10, pdf.y, pdf.column_width + 10, 110)

        # billing address
        if self.billing_address
          fl = 0
          pdf.text(e(self.billing_address.company_name),
            :justification => :left ) and fl += 1 unless self.billing_address.company_name.blank?

          pdf.text(e(self.billing_address.salutation_t.to_s),
            :justification => :left ) and fl += 1 unless String(self.billing_address.salutation_t).empty?

          pdf.text(e(self.billing_address.name.to_s), :justification => :left)

          pdf.text(e(self.billing_address.address_line_1.to_s), :justification => :left)

          pdf.text(e(self.billing_address.address_line_2.to_s),
            :justification => :left ) and fl += 1 unless self.billing_address.address_line_2.blank?
          
          pdf.text(e(self.billing_address.city_postal_and_province.to_s), :justification => :left)
          pdf.text(e(self.billing_address.country_or_country_code.to_s), :justification => :left )

          pdf.text("\n" * fl)
        end
        pdf.start_new_page  # will start new column

        # ID, Date
        pdf.text("<b>#{e(self.kind_t.titleize)}:</b> #{self.short_number.to_s}", :justification => :left)
        pdf.text("<b>#{e("Seller".t ) }:</b> #{e(self.seller.is_a?(Organization) ? self.seller.name.to_s : self.seller.name.to_s)}",
          :justification => :left)
        pdf.text("<b>#{e("Buyer".t) }:</b> #{e(self.buyer.name.to_s)}", :justification => :left)
        pdf.text("\n" )
        pdf.text("#{e((self.created_at || Time.now.utc).to_date.to_s(:long))}", :justification => :left)

        pdf.stop_columns  # stops column mode
        pdf.restore_state 
        pdf.close_object 
        pdf.add_object(header, :all_pages)   # :this_page / :all_pages / etc.
      end

      # Invoice / Credit Note
      pdf.text("\n\n\n<b>#{e(self.kind_t.titleize)}</b>\n\n", :font_size => 18)

      # Table
      PDF::SimpleTable.new do |table|
        table.column_order.push(*%w(description sku net_price))
        header = {:description => e("Item".t), :sku => e("Number".t), :net_price => e("Net Price".t)}
      
        table.columns['description'] = PDF::SimpleTable::Column.new('description') {|col|
          col.heading = PDF::SimpleTable::Column::Heading.new("<b>#{header[:description]}</b>") {|head|
            head.justification = :left
          }
        }
        table.columns['sku'] = PDF::SimpleTable::Column.new('sku') {|col|
          col.heading = PDF::SimpleTable::Column::Heading.new("<b>#{ header[:sku] }</b>") {|head|
            head.justification = :center
          }
          col.justification = :left
        }
        table.columns['net_price'] = PDF::SimpleTable::Column.new('net_price') {|col|
          col.heading = PDF::SimpleTable::Column::Heading.new(
            "<b>#{ header[:net_price] } (#{self.net_total.currency})</b>"
          ) { |head|
            head.justification = :center
          }
          col.justification = :right
          col.width = pdf.text_width("<b>#{header[:net_price] }</b>")
        }

        table.maximum_width   = pdf.margin_width
        table.font_size       = 12
        table.show_lines      = :none
        table.show_headings   = true
        table.shade_headings  = false
        table.shade_rows      = :none
        table.orientation     = :center
        table.position        = :center

        data = []
        self.line_items.each do |item|
          data.push( {
            'description'  => "<b>#{e(item.sellable.name)}</b>, #{e(truncate(item.sellable.description, :length => 100))}",
            'sku'          => item.sellable.item_number,
            'net_price'    => item.amount.format(:strip_symbol => true)
          } )
        end
        table.data.replace data
        table.render_on(pdf)
      end
    
      # Space
      pdf.text( "\n" )
    
      # disclaimer
      disclaimer = []
      if self.sales_invoice?
        disclaimer << "Your %{payment_type} was credited with a total amount of %{amount}".t % {
          :payment_type => payment_type_t,
          :amount => self.total.format(:currency_symbol => self.total.currency)
        }
      elsif self.purchase_invoice?
        disclaimer << "Your %{payment_type} was charged with a total amount of %{amount}".t % {
          :payment_type => payment_type_t,
          :amount => self.total.format(:currency_symbol => self.total.currency)
        }
      end
      disclaimer << "For any remaining questions regarding this statement, please don't hesitate to consult %{url}".t % {
        :url => service_url
      } if self.seller.is_a?(Organization) && service_url
      pdf.text(disclaimer.to_sentences, :font_size => 8) unless disclaimer.empty?

      # Put a footing on all pages.
      pdf.move_pointer( pdf.y - pdf.absolute_bottom_margin - 125 )
      pdf.open_object do |footer|
      pdf.save_state

  #      pdf.move_pointer = pdf.bottom_margin - 100

        # columns
        pdf.start_columns(2, 20)   
        # total column
        pdf.start_new_page  # will start new column 
        pdf_bracket( pdf, pdf.left_margin - 5, pdf.y, pdf.column_width + 5, 60 )
        # total table
        PDF::SimpleTable.new do |table|
          table.column_order.push(*%w(description total))
          table.columns['description'] = PDF::SimpleTable::Column.new('description') { |col|
            col.justification = :right
          }
          table.columns['total'] = PDF::SimpleTable::Column.new('totals') { |col|
            col.justification = :right
          }

          table.maximum_width   = pdf.column_width
          table.font_size       = 12
          table.show_lines      = :none
          table.show_headings   = false
          table.shade_headings  = false
          table.shade_rows      = :none
          table.orientation     = :left
          table.position        = :right
          table.heading_color   = Color::RGB::Black

          data = [{
            'description' => "#{e("Net Total".t)} (#{self.net_total.currency})",
            'total' => self.net_total.format(:strip_symbol => true)
          }, {
            'description' => "#{e(self.tax_rate.loc + '% ' + "Tax".t)} (#{self.tax_total.currency})",
            'total' => self.tax_total.format(:strip_symbol => true)
          }, {
            'description' => "<b>#{e( "Gross Total".t)} (#{self.gross_total.currency})</b>",
            'total' => "<b>#{self.gross_total.format(:strip_symbol => true)}</b>"
          }]
          table.data.replace data
          table.render_on(pdf)
        end
        pdf.stop_columns  # stops column mode
      
        pdf.text("\n\n", :font_size => 10)
      
        # footer info
        pdf.fill_color(Color::RGB::Grey)
        pdf.start_columns(3, 10)

        # seller's info
        pdf.text("<b>#{e(self.seller.name)}</b>", :font_size => 8)

        pdf.text("#{e(self.seller.is_a?(Organization) && self.seller.respond_to?(:tagline) ? self.seller.tagline.to_s : '')}",
          :font_size => 8)

        pdf.text("#{e(self.seller.is_a?(Organization) && self.seller.respond_to?(:site_url) ? self.seller.site_url.to_s: '')}",
          :font_size => 8 )
          
        pdf.text( "\n", :font_size => 8 )

        pdf.text(e(%(#{"Tax Code".t}: #{self.seller.tax_code})), :font_size => 8)
          
        pdf.start_new_page  # will start new column 
        
        # directions
        pdf.text(e(self.origin_address.address_line_1), :font_size => 8)
        pdf.text(e(self.origin_address.address_line_2), :font_size => 8 ) unless self.origin_address.address_line_2.blank?
        pdf.text(e(self.origin_address.city_postal_and_province), :font_size => 8)
        pdf.text(e(self.origin_address.country_or_country_code), :font_size => 8 )
        pdf.start_new_page  # will start new column 

        # Phone and Email
        pdf.text(e("Support".t), :font_size => 8)
        pdf.text(e(self.seller.is_a?(Organization) ? service_url : ''), :font_size => 8) if service_url
        pdf.text(e(self.origin_address.phone.blank? ? "" : "Phone".t + ' ' + self.origin_address.phone.to_s), :font_size => 8)
        pdf.text(e(self.origin_address.fax.blank? ? "" : "Fax".t + ' ' + self.origin_address.fax.to_s), :font_size => 8)
        pdf.stop_columns
      
        pdf.restore_state
        pdf.close_object
        pdf.add_object(footer, :all_pages)
      end

      pdf
    end
  end
  
  # returns a default pdf filename 
  # e.g. pi-ae4dad.pdf
  def default_pdf_file_name
    "#{self.number}.pdf" if self.number
  end

  private

  # convert string to unicode
  def unicode_text(pdf, str, options={})
    pdf.text(e("\xfe\xff#{str}", :encoding => 'UTF-16BE'), options)   # start Unicode UTF-16BE encoding
  end

  # Encode a string to a character encoding that matches that
  # of the spoken language (language_code). 
  #
  # The encoding can
  # be set manually with the :to_encoding option.
  #
  # e.g.
  #
  #   e('Grüße', :from_encoding => 'UTF-8', :to_encoding => 'latin1')
  #
  def e(str, options={})
    defaults = {:language_code => Utility.language_code, :from_encoding => 'UTF-8'}
    options = defaults.merge(options).symbolize_keys

    to_encoding = options[:to_encoding] || Utility::LANGUAGE_TO_CHARSET_ENCODING[options[:language_code]] || 'latin1'
    Iconv.iconv(to_encoding, options[:from_encoding], str.gsub('€', 'EUR')) if str
  end
  
  # Prints a style bracket to the PDF at the given location
  def pdf_bracket(pdf, x, y, w, h)
    r = 5

    pdf.stroke_style( PDF::Writer::StrokeStyle.new(1) )
    pdf.stroke_color( Color::RGB::Grey )
    pdf.rounded_rectangle(x, y, w, h, r).stroke   # x, y, w, h, r
    
    pdf.stroke_style( PDF::Writer::StrokeStyle.new(8) )
    pdf.stroke_color( Color::RGB::White )
    pdf.rectangle(x + r + 6, y + 2, w - (2 * (r + 6)), -(h + 2) ).stroke
  end
  
end
