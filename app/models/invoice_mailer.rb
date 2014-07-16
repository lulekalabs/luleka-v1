# Handles all mails relating to invoices.
class InvoiceMailer < Notifier
  
  # Send new invoice, attaching pdf
  # TODO: with PDF attachment
  def new_invoice(invoice, sent_at = Time.now.utc)
    if invoice.sales_invoice?
      subject      "You have just received your reward".t
    else
      subject      "You have just received a new invoice".t
    end
    recipients     invoice.sales_invoice? ? invoice.seller.email : invoice.buyer.email
    from           Notifier.noreply_email
    sent_on        sent_at
    body           :invoice => invoice
    attachment     :content_type => 'application/pdf', :body => invoice.to_pdf, :filename => invoice.pdf_default_filename
  end
  
end